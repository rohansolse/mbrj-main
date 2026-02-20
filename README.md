# MBRJ Launcher Page

Static single-page launcher for MBRJ modules.

## Files

- `index.html` - main landing page UI (HTML + CSS + JS in one file)

## Module Links (Current Order)

1. Photo Gallery - `/gallery`
2. Attendance App - `/attendance`
3. Photo Selection - `/selection`
4. Admin Panel - `/admin`
5. MBRJ Creator - `/mbrj-co-selection`
6. Coming Soon - `/reports`

## Branding

- Header: `Welcome to MBRJ`
- Footer: `© <year> • MBRJ copyrights • Single-domain launcher page (static)`

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

## iPad Responsive Notes

- Tablet layout uses a 2-column grid up to `1180px`.
- Mobile switches to 1 column at `720px`.
- iPad portrait has a tuned max content width for better balance.
