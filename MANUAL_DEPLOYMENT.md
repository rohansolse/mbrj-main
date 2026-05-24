# MBRJ Main Manual Deployment

This project is a static website. The live files are served directly from `/var/www/mbrj-main`.

For normal HTML updates:
- You only need to sync the project files to the server
- You do **not** need to restart Nginx

## Step 1: Sync The Project Folder From Your Mac To The Server Home Folder

Run this on your Mac:

```bash
rsync -av --delete \
  --exclude '.git/' \
  --exclude 'README.md' \
  --exclude 'MANUAL_DEPLOYMENT.md' \
  /Users/rohansolse/Documents/mbrj-main/ \
  rohansolse@192.168.1.33:/home/rohansolse/mbrj-main/
```

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
