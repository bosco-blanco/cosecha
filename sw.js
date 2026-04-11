const C='cosecha-v5';const A=['./','./index.html','./manifest.json'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(C).then(c=>c.addAll(A)));self.skipWaiting();});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==C).map(k=>caches.delete(k)))));self.clients.claim();});
self.addEventListener('fetch',e=>{
  const u=new URL(e.request.url);
  // No cachear llamadas al backend (Apps Script)
  if(u.hostname.includes('googleusercontent.com')||u.hostname.includes('script.google.com')||u.hostname.includes('nominatim'))return;
  e.respondWith(caches.match(e.request).then(r=>r||fetch(e.request)));
});
