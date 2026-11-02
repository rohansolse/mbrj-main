/*
 * Offline cache for the static hub.
 *
 * The production server is not up around the clock, so a repeat visitor
 * arriving while it is down would otherwise get a browser "site not reachable"
 * page. This worker keeps the three pages and their images in the visitor's own
 * browser and serves those instead. It only helps someone who has loaded the
 * site at least once before — a true first visit during downtime still fails,
 * and so does a crawler. A CDN in front of the origin is the fix for that case;
 * this is the client-side half.
 *
 * Hand-written rather than generated, because this repo has no build step:
 * `deploy.sh` rsyncs the folder as-is. That has two consequences worth knowing:
 *
 * 1. PRECACHE is maintained by hand. Adding a page or an image means adding it
 *    here too, or it is only cached once a visitor has actually fetched it.
 * 2. There are no content hashes in the filenames, so nothing may be served
 *    cache-first for long. Pages go network-first and assets
 *    stale-while-revalidate, which keeps a deploy from being pinned behind a
 *    cached copy without needing a CACHE version bumped by hand on every edit.
 */

const CACHE = 'mbrj-main';

/* The whole site, ~450KB. Small enough to guarantee offline in full. */
const PRECACHE = [
  '/',
  '/index.html',
  '/client-experiences.html',
  '/internal-tools.html',
  '/favicon.svg',
  '/favicon-32.png',
  '/favicon-512.png',
  '/images/wedding.webp',
  '/images/prewedding.webp',
  '/images/babyshoot.webp',
  '/images/maternity.webp',
  '/images/press/wedwar.webp',
  '/images/press/wallmag.webp',
  '/images/press/thane-vaibhav.webp',
];

/*
 * Crawler-facing files. Never answered from the cache: a stale sitemap or a
 * `robots.txt` served to Googlebot from a visitor's own cache is worse than a
 * failed request, and neither is any use offline.
 */
const NETWORK_ONLY = new Set(['/robots.txt', '/sitemap.xml']);

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      // Individually, not addAll: addAll rejects as a unit, so one renamed
      // image would leave the whole site uncached.
      await Promise.all(
        PRECACHE.map((url) => cache.add(new Request(url, { cache: 'reload' })).catch(() => {}))
      );
      await self.skipWaiting();
    })()
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      // Drop caches from an earlier CACHE name, should it ever be renamed.
      const names = await caches.keys();
      await Promise.all(names.filter((name) => name !== CACHE).map((name) => caches.delete(name)));
      await self.clients.claim();
    })()
  );
});

/** Puts a response in the cache, ignoring a full or unavailable store. */
const put = async (request, response) => {
  if (!response || !response.ok) return;
  // A 200 is not proof the right thing came back. An nginx `try_files ...
  // /index.html` fallback answers a *missing* image with the home page at
  // status 200, which would otherwise be stored under the image's URL and
  // handed to an <img> as HTML for as long as the cache lived. Only a
  // navigation may legitimately be HTML.
  if (
    request.mode !== 'navigate' &&
    (response.headers.get('content-type') || '').includes('text/html')
  ) {
    return;
  }
  try {
    const cache = await caches.open(CACHE);
    await cache.put(request, response.clone());
  } catch {
    // Quota exceeded, or storage denied in private mode. Nothing to do.
  }
};

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  if (NETWORK_ONLY.has(url.pathname)) return;

  if (request.mode === 'navigate') {
    // Network-first: the pages carry no content hash, so a cached copy must
    // never win while the origin is reachable.
    event.respondWith(
      (async () => {
        try {
          const response = await fetch(request);
          void put(request, response);
          return response;
        } catch {
          // Offline. The page itself, then the home page as the last resort —
          // a visitor who only ever opened `/` still gets something readable.
          return (
            (await caches.match(request, { ignoreSearch: true })) ??
            (await caches.match('/')) ??
            Response.error()
          );
        }
      })()
    );
    return;
  }

  // Stale-while-revalidate for the images and the favicons: served instantly
  // from the cache, refreshed in the background, and still correct with the
  // origin down.
  event.respondWith(
    (async () => {
      const cached = await caches.match(request);
      const network = fetch(request)
        .then((response) => {
          void put(request, response);
          return response;
        })
        .catch(() => undefined);
      return cached ?? (await network) ?? Response.error();
    })()
  );
});
