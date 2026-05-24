#!/usr/bin/env bash

set -euo pipefail

# Manual deployment guide for MBRJ Main static site.
#
# Purpose:
# - This project is a static website.
# - The live server reads files directly from /var/www/mbrj-main.
# - Because of that, uploading the HTML files is enough.
# - Nginx restart is NOT required for normal HTML file updates.
#
# Server details:
# - Server IP: 192.168.1.33
# - SSH user: rohansolse
# - Live path: /var/www/mbrj-main
#
# Files to deploy:
# - index.html
# - client-experiences.html
# - internal-tools.html
#
# Important:
# - Do not run this script expecting auto deployment.
# - This file is intentionally written as a junior-friendly manual checklist.
# - Copy the commands below and run them one by one.

cat <<'EOF'
============================================================
MBRJ MAIN - MANUAL DEPLOYMENT INSTRUCTIONS
============================================================

STEP 1: Open terminal on your Mac.

STEP 2: Upload the latest HTML files from your local machine to your home folder on the server.

Run this command on your Mac:

scp \
  /Users/rohansolse/Documents/mbrj-main/index.html \
  /Users/rohansolse/Documents/mbrj-main/client-experiences.html \
  /Users/rohansolse/Documents/mbrj-main/internal-tools.html \
  rohansolse@192.168.1.33:/home/rohansolse/

What this does:
- Copies the 3 website HTML files
- Sends them to /home/rohansolse on the server
- This is used because direct write access to /var/www/mbrj-main is not allowed

STEP 3: Connect to the server with SSH.

Run this command on your Mac:

ssh rohansolse@192.168.1.33

STEP 4: Copy the uploaded files into the live website folder.

Run this command on the server:

sudo cp \
  /home/rohansolse/index.html \
  /home/rohansolse/client-experiences.html \
  /home/rohansolse/internal-tools.html \
  /var/www/mbrj-main/

What this does:
- Moves the uploaded HTML files into the live Nginx folder
- Replaces the old live files with the new ones

STEP 5: Fix file ownership.

Run this command on the server:

sudo chown \
  www-data:www-data \
  /var/www/mbrj-main/index.html \
  /var/www/mbrj-main/client-experiences.html \
  /var/www/mbrj-main/internal-tools.html

What this does:
- Makes sure Nginx owns the deployed files properly

STEP 6: Fix file permissions.

Run this command on the server:

sudo chmod 644 \
  /var/www/mbrj-main/index.html \
  /var/www/mbrj-main/client-experiences.html \
  /var/www/mbrj-main/internal-tools.html

What this does:
- Gives read permission to the web server
- Keeps the files safe and standard for static hosting

STEP 7: Verify the files exist in the live folder.

Run this command on the server:

ls -l /var/www/mbrj-main

Expected result:
- You should see index.html
- You should see client-experiences.html
- You should see internal-tools.html

STEP 8: Open the website in the browser and hard refresh.

Why:
- Sometimes the browser shows old cached HTML
- Hard refresh ensures you see the newest deployed version

NGINX NOTE:
- No Nginx restart is needed for simple HTML updates
- Restart or reload Nginx only if Nginx config files are changed

OPTIONAL CLEANUP:
- After deployment, you can remove the uploaded files from /home/rohansolse if you want

Optional cleanup command on the server:

rm -f \
  /home/rohansolse/index.html \
  /home/rohansolse/client-experiences.html \
  /home/rohansolse/internal-tools.html

============================================================
END OF MANUAL DEPLOYMENT GUIDE
============================================================
EOF
