# MBRJ Main Redirect Page

Static single-page redirect hub for the MBRJ product suite.

## Files

- `index.html` - main landing page UI with grouped directories and direct destination cards
- `client-experiences.html` - grouped page for pre-wedding, wedding, and maternity
- `internal-tools.html` - grouped page for easy select, attendance app, and admin

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

- Upload the files to the server home folder first using `scp`
- SSH into the server
- Copy the files into `/var/www/mbrj-main` using `sudo cp`
- Fix ownership with `sudo chown`
- Fix permissions with `sudo chmod`
- Verify with `ls -l /var/www/mbrj-main`

Junior-friendly step-by-step deployment instructions are available in:

- `MANUAL_DEPLOYMENT.md`
- `scripts/deployment.manual.sh`

## Responsive Notes

- Product cards use a 2-column grid on desktop and a single-column stack on mobile
