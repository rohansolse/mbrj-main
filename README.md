# MBRJ Main Redirect Page

Static single-page redirect hub for the MBRJ product suite.

## Files

- `index.html` - public home page: hero, one photo card per shoot (linking straight to its subdomain), WhatsApp/call contact band; internal tools are linked from the footer only
- `images/` - the four 4:5 WebP card covers, cropped from each shoot site's share image
- `client-experiences.html` - grouped page for pre-wedding, wedding, maternity, and baby shoot
- `internal-tools.html` - grouped page for easy select, attendance app, and admin
- `deploy.sh` - validates the site, then deploys it to the Nginx box (`./deploy.sh`)
- `robots.txt` - crawler rules + sitemap pointer (internal tools stays crawlable so its `noindex` is seen)
- `sitemap.xml` - lists the two public pages
- `favicon.svg` - main favicon source
- `favicon-32.png` - browser tab favicon fallback
- `favicon-512.png` - larger favicon asset

## Redirect Targets

1. MBRJ Pre-Wedding - `https://prewedding.momentsbyrj.in`
2. MBRJ Wedding - `https://wedding.momentsbyrj.in`
3. MBRJ Maternity - `https://maternity.momentsbyrj.in`
4. MBRJ Baby Shoot - `https://babyshoot.momentsbyrj.in`
5. MBRJ Easy Select - `https://easyselect.momentsbyrj.in`
6. MBRJ Attendance App - `https://attendance.momentsbyrj.in`
7. MBRJ Admin - `https://admin.momentsbyrj.in`

## Structure

- Home page links each shoot site directly; internal tools sit behind a footer link
- Client experiences page (still in the sitemap, but no longer linked from the home page)
- Dedicated internal tools page
- Static footer with current year

## Run Locally

Because this is a static page, you can either:

1. Open `index.html` directly in a browser, or
2. Serve it with any static server (recommended for route testing behind Nginx).

Example:

```bash
cd /Users/rohansolse/Documents/mbrj-main
python3 -m http.server 8080
```

Then open `http://localhost:8080`.

## Manual Deployment

This site is deployed as plain static HTML under `/var/www/mbrj-main` on the server.

- Sync the project folder to the server home folder using `rsync`
- SSH into the server
- Sync the folder into `/var/www/mbrj-main` using `sudo rsync`
- Fix ownership with `sudo chown -R`
- Fix permissions for files and folders
- Verify with `ls -l /var/www/mbrj-main`

Generalized copy commands:

```bash
rsync -av --delete \
  --exclude '.git/' \
  --exclude 'README.md' \
  --exclude 'MANUAL_DEPLOYMENT.md' \
  /Users/rohansolse/Documents/mbrj-main/ \
  rohansolse@192.168.1.33:/home/rohansolse/mbrj-main/
```

```bash
ssh rohansolse@192.168.1.33
sudo rsync -av --delete /home/rohansolse/mbrj-main/ /var/www/mbrj-main/
sudo chown -R www-data:www-data /var/www/mbrj-main
sudo find /var/www/mbrj-main -type d -exec chmod 755 {} \;
sudo find /var/www/mbrj-main -type f -exec chmod 644 {} \;
```

Step-by-step deployment instructions are available in `MANUAL_DEPLOYMENT.md`.

## Responsive Notes

- Home shoot cards: 4 columns on desktop, 2 on tablet, and image-beside-text rows on phones (≤600px)
