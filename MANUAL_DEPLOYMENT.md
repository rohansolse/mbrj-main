# MBRJ Main Manual Deployment

This project is a static website. The live files are served directly from `/var/www/mbrj-main`.

For normal HTML updates:
- You only need to sync the project files to the server
- You do **not** need to restart Nginx

## Quick Way: `./deploy.sh`

Steps 1 to 6 below are automated by the deploy script. From your Mac:

```bash
./deploy.sh
```

It validates the HTML, `sitemap.xml` and internal links first, syncs to the
server home folder, then asks before replacing the live webroot and fixing
ownership and permissions.

Useful flags:

- `./deploy.sh --check` - run the validation only, deploy nothing
- `./deploy.sh --dry-run` - show what would be synced, change nothing
- `./deploy.sh --yes` - skip the confirmation prompt

The server, staging path and webroot can be overridden with the `MBRJ_SERVER`,
`MBRJ_STAGE_DIR` and `MBRJ_LIVE_DIR` environment variables.

The manual steps below still work and are kept as the fallback if SSH or the
script misbehaves.

## Step 1: Sync The Project Folder From Your Mac To The Server Home Folder

Run this on your Mac:

```bash
rsync -av --delete --delete-excluded \
  --exclude '.*' \
  --exclude '*.md' \
  --exclude 'deploy.sh' \
  /Users/rohansolse/Documents/mbrj-main/ \
  rohansolse@192.168.1.33:/home/rohansolse/mbrj-main/
```

The `--exclude '.*'` matters: it keeps hidden folders such as `.git` and
`.claude` off the web server. Without it those get copied into the webroot and
served publicly. `deploy.sh` uses a stricter allowlist and only ships web
assets.

Why:
- Direct write access to `/var/www/mbrj-main` is not allowed for the normal SSH user
- So first sync to `/home/rohansolse/mbrj-main`
- This command copies all website assets automatically, including new `.svg` and `.png` favicon files

## Step 2: Connect To The Server

Run this on your Mac:

```bash
ssh rohansolse@192.168.1.33
```

## Step 3: Copy Files Into The Live Website Folder

Run this on the server:

```bash
sudo rsync -av --delete \
  /home/rohansolse/mbrj-main/ \
  /var/www/mbrj-main/
```

## Step 4: Fix File Ownership

Run this on the server:

```bash
sudo chown -R www-data:www-data /var/www/mbrj-main
```

## Step 5: Fix File Permissions

Run this on the server:

```bash
sudo find /var/www/mbrj-main -type d -exec chmod 755 {} \;
sudo find /var/www/mbrj-main -type f -exec chmod 644 {} \;
```

## Step 6: Verify The Deployment

Run this on the server:

```bash
ls -l /var/www/mbrj-main
```

You should see:
- `index.html`
- `client-experiences.html`
- `internal-tools.html`
- `favicon.svg`
- `favicon-32.png`
- `favicon-512.png`

## Step 7: Open The Website And Hard Refresh

Why:
- Browser cache can show old HTML
- Hard refresh ensures you see the latest deployed version

## Nginx Note

You do **not** need to restart Nginx for normal static HTML file updates.

Only reload or restart Nginx if:
- Nginx config files changed
- site/server block config changed

## Optional Cleanup

If you want to remove the uploaded files from the server home folder after deployment, run:

```bash
rm -rf /home/rohansolse/mbrj-main
```
