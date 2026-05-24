# MBRJ Main Redirect Page

Static single-page redirect hub for the MBRJ product suite.

## Files

- `index.html` - main landing page UI with grouped directories and direct destination cards
- `client-experiences.html` - grouped page for pre-wedding, wedding, and maternity
- `internal-tools.html` - grouped page for easy select, attendance app, and admin
- `favicon.svg` - main favicon source
- `favicon-32.png` - browser tab favicon fallback
- `favicon-512.png` - larger favicon asset

## Redirect Targets

1. MBRJ Pre-Wedding - `https://prewedding.momentsbyrj.in`
2. MBRJ Wedding - `https://wedding.momentsbyrj.in`
3. MBRJ Maternity - `https://maternity.momentsbyrj.in`
4. MBRJ Easy Select - `https://easyselect.momentsbyrj.in`
5. MBRJ Attendance App - `https://attendance.momentsbyrj.in`
6. MBRJ Admin - `https://admin.momentsbyrj.in`

## Structure

- Main index with separate grouped entry cards for client experiences and internal tools
- Dedicated client experiences page
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

- Product cards use a 2-column grid on desktop and a single-column stack on mobile
