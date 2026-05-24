# MBRJ Main Manual Deployment

This project is a static website. The live files are served directly from `/var/www/mbrj-main`.

For normal HTML updates:
- You only need to copy the updated files to the server
- You do **not** need to restart Nginx

## Files To Deploy

- `index.html`
- `client-experiences.html`
- `internal-tools.html`

## Step 1: Upload Files From Your Mac To The Server Home Folder

Run this on your Mac:

```bash
scp \
  /Users/rohansolse/Documents/mbrj-main/index.html \
  /Users/rohansolse/Documents/mbrj-main/client-experiences.html \
  /Users/rohansolse/Documents/mbrj-main/internal-tools.html \
  rohansolse@192.168.1.33:/home/rohansolse/
```

Why:
- Direct write access to `/var/www/mbrj-main` is not allowed for the normal SSH user
- So first upload to `/home/rohansolse`

## Step 2: Connect To The Server

Run this on your Mac:

```bash
ssh rohansolse@192.168.1.33
```

## Step 3: Copy Files Into The Live Website Folder

Run this on the server:

```bash
sudo cp \
  /home/rohansolse/index.html \
  /home/rohansolse/client-experiences.html \
  /home/rohansolse/internal-tools.html \
  /var/www/mbrj-main/
```

## Step 4: Fix File Ownership

Run this on the server:

```bash
sudo chown \
  www-data:www-data \
  /var/www/mbrj-main/index.html \
  /var/www/mbrj-main/client-experiences.html \
  /var/www/mbrj-main/internal-tools.html
```

## Step 5: Fix File Permissions

Run this on the server:

```bash
sudo chmod 644 \
  /var/www/mbrj-main/index.html \
  /var/www/mbrj-main/client-experiences.html \
  /var/www/mbrj-main/internal-tools.html
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
rm -f \
  /home/rohansolse/index.html \
  /home/rohansolse/client-experiences.html \
  /home/rohansolse/internal-tools.html
```
