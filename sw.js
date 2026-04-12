/**
 * Cosecha Service Worker v8
 * Estrategia: network-first para HTML (nunca queda cacheado),
 *             cache-first para assets estáticos,
 *             bypass total para backend y APIs externas.
 */
const C = 'cosecha-v23';
const STATIC = ['./icon-192.png', './icon-512.png', './manifest.json'];

self.addEventListener('install', e => {
  self.skipWaiting();
  e.waitUntil(caches.open(C).then(c => c.addAll(STATIC).catch(() => {})));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== C).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
      .then(() => {
        // Avisar a todos los clientes de que hay nueva versión
        return self.clients.matchAll({ type: 'window' }).then(cs => {
          cs.forEach(c => c.postMessage({ type: 'SW_UPDATED', version: C }));
        });
      })
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  const url = new URL(req.url);

  // Bypass total para llamadas externas (backend, geocoder, fuentes)
  if (url.hostname.includes('googleusercontent.com') ||
      url.hostname.includes('script.google.com') ||
      url.hostname.includes('nominatim.openstreetmap.org') ||
      url.hostname.includes('fonts.googleapis.com') ||
      url.hostname.includes('fonts.gstatic.com')) {
    return; // navegador maneja normalmente
  }

  // Solo GET se cachea
  if (req.method !== 'GET') return;

  // HTML → network-first (siempre intenta pedir al servidor primero)
  if (req.mode === 'navigate' || req.destination === 'document' || url.pathname.endsWith('.html') || url.pathname.endsWith('/')) {
    e.respondWith(
      fetch(req)
        .then(resp => {
          // Guardar copia en cache para offline
          const copy = resp.clone();
          caches.open(C).then(c => c.put(req, copy));
          return resp;
        })
        .catch(() => caches.match(req).then(r => r || caches.match('./index.html')))
    );
    return;
  }

  // Assets estáticos → cache-first
  e.respondWith(
    caches.match(req).then(cached => {
      if (cached) return cached;
      return fetch(req).then(resp => {
        if (resp.ok) {
          const copy = resp.clone();
          caches.open(C).then(c => c.put(req, copy));
        }
        return resp;
      });
    })
  );
});
