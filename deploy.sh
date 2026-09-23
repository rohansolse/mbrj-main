#!/usr/bin/env bash
#
# Deploy the MBRJ static site to the Nginx box.
#
#   ./deploy.sh            validate, then sync to the server (asks before the live copy)
#   ./deploy.sh --check    run the local validation only, deploy nothing
#   ./deploy.sh --dry-run  show what rsync would change, without changing it
#   ./deploy.sh --yes      skip the confirmation prompt
#
# See MANUAL_DEPLOYMENT.md for what this automates and why it is a two-hop copy.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER="${MBRJ_SERVER:-rohansolse@192.168.1.33}"
STAGE_DIR="${MBRJ_STAGE_DIR:-/home/rohansolse/mbrj-main}"
LIVE_DIR="${MBRJ_LIVE_DIR:-/var/www/mbrj-main}"

# What reaches the webroot is an allowlist, not a blocklist: anything not
# matched below is left behind. A blocklist silently ships whatever new file
# lands in the folder (tool configs, notes, credentials), so it is not used.
# First matching rule wins, so the dotfile exclude has to come first.
FILTER=(
  --exclude '.*'          # .git, .claude, .env, .DS_Store, .gitignore, ...
  --include '*/'          # descend into subfolders
  --include '*.html'
  --include '*.css'
  --include '*.js'
  --include '*.svg'
  --include '*.png'
  --include '*.jpg'
  --include '*.jpeg'
  --include '*.webp'
  --include '*.gif'
  --include '*.ico'
  --include '*.woff'
  --include '*.woff2'
  --include 'robots.txt'
  --include 'sitemap.xml'
  --exclude '*'           # everything else stays on the Mac
  --prune-empty-dirs
)

CHECK_ONLY=0
DRY_RUN=0
ASSUME_YES=0

for arg in "$@"; do
  case "$arg" in
    --check|--check-only) CHECK_ONLY=1 ;;
    --dry-run|-n)         DRY_RUN=1 ;;
    --yes|-y)             ASSUME_YES=1 ;;
    --help|-h)            sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
  esac
done

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
fail() { printf '\033[31mERROR: %s\033[0m\n' "$1" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1. Local validation
# ---------------------------------------------------------------------------
step "Validating site files"

cd "$PROJECT_DIR"
command -v python3 >/dev/null || fail "python3 not found; needed for validation"

python3 - "$PROJECT_DIR" <<'PYCHECK'
import glob, json, os, re, sys
from html.parser import HTMLParser
from urllib.parse import urlparse
import xml.etree.ElementTree as ET

root = sys.argv[1]
os.chdir(root)
errors, warnings = [], []

pages = sorted(glob.glob("*.html"))
if not pages:
    errors.append("no .html files found")


class Collector(HTMLParser):
    """Collect the bits of each page we care about, and check tag nesting."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack = []
        self.unclosed = []
        self.links = []
        self.title = None
        self.description = None
        self.canonical = None
        self.robots = None
        self.h1_count = 0
        self.jsonld = []
        self._in_title = False
        self._in_jsonld = False
        # void elements never nest, so they are not pushed onto the stack
        self.void = {
            "area", "base", "br", "col", "embed", "hr", "img", "input",
            "link", "meta", "param", "source", "track", "wbr",
        }
        # HTML5 lets these omit their end tag, so a missing one is not an error
        self.optional_end = {
            "p", "li", "dt", "dd", "tr", "td", "th", "thead", "tbody", "tfoot",
            "option", "optgroup", "colgroup", "caption", "rt", "rp",
            "html", "head", "body",
        }

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag not in self.void:
            self.stack.append(tag)
        if tag == "title":
            self._in_title = True
        elif tag == "h1":
            self.h1_count += 1
        elif tag == "a" and a.get("href"):
            self.links.append(a["href"])
        elif tag == "img" and a.get("src"):
            # local images ship too, so a missing one is a broken page
            self.links.append(a["src"])
        elif tag == "link":
            if (a.get("rel") or "").lower() == "canonical":
                self.canonical = a.get("href")
            elif a.get("href"):
                self.links.append(a["href"])
        elif tag == "meta":
            name = (a.get("name") or "").lower()
            if name == "description":
                self.description = a.get("content")
            elif name == "robots":
                self.robots = a.get("content")
        elif tag == "script" and (a.get("type") or "").lower() == "application/ld+json":
            self._in_jsonld = True

    def handle_startendtag(self, tag, attrs):
        # <foo /> closes itself (common in the inline SVG icons), so record its
        # attributes but never put it on the open-tag stack
        depth = len(self.stack)
        self.handle_starttag(tag, attrs)
        del self.stack[depth:]

    def handle_endtag(self, tag):
        if tag in self.void:
            return
        if tag in self.stack:
            # unwind to the matching open tag; anything skipped was left unclosed
            while self.stack:
                popped = self.stack.pop()
                if popped == tag:
                    break
                if popped not in self.optional_end:
                    self.unclosed.append(popped)
        if tag == "title":
            self._in_title = False
        elif tag == "script":
            self._in_jsonld = False

    def handle_data(self, data):
        if self._in_title:
            self.title = (self.title or "") + data
        if self._in_jsonld:
            self.jsonld.append(data)


for page in pages:
    with open(page, encoding="utf-8") as fh:
        html = fh.read()

    p = Collector()
    p.feed(html)
    p.close()
    where = f"{page}:"

    dangling = p.unclosed + [t for t in p.stack if t not in p.optional_end]
    if dangling:
        errors.append(f"{where} unclosed tag(s): {', '.join(sorted(set(dangling)))}")

    title = (p.title or "").strip()
    if not title:
        errors.append(f"{where} missing <title>")
    elif len(title) > 62:
        warnings.append(f"{where} title is {len(title)} chars, Google truncates near 60")

    desc = (p.description or "").strip()
    if not desc:
        errors.append(f"{where} missing meta description")
    elif not 50 <= len(desc) <= 165:
        warnings.append(f"{where} meta description is {len(desc)} chars, aim for 50-165")

    noindexed = "noindex" in (p.robots or "").lower()

    if p.h1_count == 0:
        errors.append(f"{where} no <h1> on the page")
    elif p.h1_count > 1:
        warnings.append(f"{where} {p.h1_count} <h1> elements, expected 1")

    if not noindexed and not p.canonical:
        warnings.append(f"{where} indexable page has no rel=canonical")

    for block in p.jsonld:
        if not block.strip():
            continue
        try:
            json.loads(block)
        except json.JSONDecodeError as exc:
            errors.append(f"{where} invalid JSON-LD ({exc})")

    # relative links must point at files that actually ship
    for href in p.links:
        parsed = urlparse(href)
        if parsed.scheme or parsed.netloc or href.startswith(("#", "mailto:", "tel:")):
            continue
        target = parsed.path
        if target and not os.path.exists(target):
            errors.append(f"{where} link to missing file: {href}")

# sitemap.xml: must parse, and must not advertise noindexed or missing pages
if os.path.exists("sitemap.xml"):
    try:
        tree = ET.parse("sitemap.xml")
    except ET.ParseError as exc:
        errors.append(f"sitemap.xml: not valid XML ({exc})")
    else:
        ns = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
        locs = [el.text.strip() for el in tree.getroot().findall(".//sm:loc", ns) if el.text]
        if not locs:
            errors.append("sitemap.xml: no <loc> entries found")
        for loc in locs:
            path = urlparse(loc).path.lstrip("/")
            if not path:
                continue
            if not os.path.exists(path):
                errors.append(f"sitemap.xml: lists {loc} but {path} does not exist")
            else:
                body = open(path, encoding="utf-8").read()
                if re.search(r'<meta[^>]+name=["\']robots["\'][^>]*noindex', body, re.I):
                    errors.append(f"sitemap.xml: lists {loc} but that page is noindex")
else:
    warnings.append("no sitemap.xml in the project")

if not os.path.exists("robots.txt"):
    warnings.append("no robots.txt in the project")

for w in warnings:
    print(f"  warn  {w}")
for e in errors:
    print(f"  FAIL  {e}")

if errors:
    print(f"\n{len(errors)} error(s), {len(warnings)} warning(s)")
    sys.exit(1)

print(f"  ok    {len(pages)} page(s) checked, {len(warnings)} warning(s)")
PYCHECK

step "Files that would be published"
rsync -an --delete --delete-excluded --out-format='  %n' "${FILTER[@]}" \
  "$PROJECT_DIR/" /dev/null 2>/dev/null || true

if [ "$CHECK_ONLY" -eq 1 ]; then
  step "Checks passed (--check: nothing deployed)"
  exit 0
fi

# ---------------------------------------------------------------------------
# 2. Sync the project to the server's home folder
# ---------------------------------------------------------------------------
# Two hops because the SSH user cannot write to the webroot directly.

# --delete-excluded so anything an earlier deploy left in the staging folder,
# and that the allowlist no longer permits, is removed rather than protected.
RSYNC_FLAGS=(-av --delete --delete-excluded)
[ "$DRY_RUN" -eq 1 ] && RSYNC_FLAGS+=(--dry-run)

step "Syncing to ${SERVER}:${STAGE_DIR}"
rsync "${RSYNC_FLAGS[@]}" "${FILTER[@]}" "$PROJECT_DIR/" "${SERVER}:${STAGE_DIR}/"

# ---------------------------------------------------------------------------
# 3. Publish into the webroot
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 1 ]; then
  step "Dry run: stopping before the live copy"
  exit 0
fi

if [ "$ASSUME_YES" -eq 0 ]; then
  printf '\nAbout to replace %s on %s (rsync --delete). Continue? [y/N] ' "$LIVE_DIR" "$SERVER"
  read -r reply
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Aborted. Files are staged in ${STAGE_DIR} but not live."; exit 1 ;;
  esac
fi

step "Publishing to ${LIVE_DIR} (sudo may prompt)"
ssh -t "$SERVER" "STAGE=\"$STAGE_DIR\" LIVE=\"$LIVE_DIR\" bash -s" <<'REMOTE'
set -euo pipefail

sudo rsync -av --delete "$STAGE/" "$LIVE/"
sudo chown -R www-data:www-data "$LIVE"
sudo find "$LIVE" -type d -exec chmod 755 {} +
sudo find "$LIVE" -type f -exec chmod 644 {} +

echo
echo "Live contents of $LIVE:"
ls -l "$LIVE"
REMOTE

step "Deployed"
echo "Nginx does not need a reload for static file changes."
echo "Hard-refresh the site (Cmd+Shift+R) to bypass browser cache."
