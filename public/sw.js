const STATIC_CACHE = 'certex-static-v1';
const RUNTIME_CACHE = 'certex-runtime-v1';
const APP_SHELL = ['/', '/manifest.webmanifest', '/icons/certex-icon.svg'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => cache.addAll(APP_SHELL))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key !== STATIC_CACHE && key !== RUNTIME_CACHE)
          .map((key) => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') {
    return;
  }

  const requestUrl = new URL(request.url);
  if (requestUrl.origin !== self.location.origin) {
    return;
  }

  if (request.mode === 'navigate') {
    event.respondWith(
      (async () => {
        try {
          const networkResponse = await fetch(request);
          const runtimeCache = await caches.open(RUNTIME_CACHE);
          runtimeCache.put(request, networkResponse.clone());
          return networkResponse;
        } catch {
          const cachedPage = await caches.match(request);
          if (cachedPage) {
            return cachedPage;
          }
          const cachedShell = await caches.match('/');
          if (cachedShell) {
            return cachedShell;
          }
          return Response.error();
        }
      })()
    );
    return;
  }

  event.respondWith(
    (async () => {
      const cachedResponse = await caches.match(request);
      if (cachedResponse) {
        return cachedResponse;
      }

      try {
        const networkResponse = await fetch(request);
        if (
          networkResponse &&
          networkResponse.status === 200 &&
          (networkResponse.type === 'basic' || networkResponse.type === 'cors')
        ) {
          const runtimeCache = await caches.open(RUNTIME_CACHE);
          runtimeCache.put(request, networkResponse.clone());
        }
        return networkResponse;
      } catch {
        return cachedResponse || Response.error();
      }
    })()
  );
});
