# COSECHA Technical Specification
## Comprehensive Development Guide

**Project**: Cosecha PWA  
**Repository**: https://github.com/bosco-blanco/cosecha  
**Hosted At**: https://bosco-blanco.github.io/cosecha/  
**Organization**: En Copa de Balón (ECDB) — Wine & Beverage Distributor  
**Document Version**: 1.0  
**Last Updated**: 2026-04-12

---

## TABLE OF CONTENTS

1. [Project Overview](#project-overview)
2. [Critical Bugs to Fix First](#critical-bugs-to-fix-first)
3. [Module Specifications](#module-specifications)
4. [Data Models](#data-models)
5. [Architecture Recommendations](#architecture-recommendations)
6. [UI/UX Guidelines](#uiux-guidelines)
7. [Environment & Deployment](#environment--deployment)
8. [Security Requirements](#security-requirements)
9. [Testing Strategy](#testing-strategy)
10. [Development Roadmap](#development-roadmap)

---

## PROJECT OVERVIEW

### What is Cosecha?

Cosecha is an internal management PWA (Progressive Web App) built for **En Copa de Balón (ECDB)**, a wine and beverage distribution group operating since 1991 across Spain. The app consolidates employee time tracking, team communication, sales pipeline management, and self-service HR functions into a single mobile-first platform.

### Organization Structure

En Copa de Balón operates **15+ locations** across four business segments:
- **Retail Wine Stores**: 5 locations
- **Restaurants**: 3 locations
- **Gastronomic Venues**: 3 locations
- **Nightlife Venues**: 2 locations
- **B2B Distribution**: CODEBA (commercial distribution arm)

**Total User Base**: ~50–100 employees across all locations, plus commercial team.

### Current State

**Status**: MVP/Prototype with critical data flow issues  
**Architecture**: Single-file PWA (index.html, ~3000+ lines) with Google Apps Script backend and localStorage frontend state

**Key Limitations**:
- Backend URL not configured → app runs on demo data only
- No authentication → anyone with URL has full access
- No offline sync capability
- Poor error handling and empty states
- Tracker (CRM) tab has visual bugs
- Service worker only caches 3 files
- No push notifications

### Target Users

1. **Store/Location Managers** (8–10 people) — Manage daily operations, view team time tracking, track KPIs
2. **Commercial/Sales Team** (5–8 people) — Log visits, manage CODEBA pipeline, generate proposals
3. **General Employees** (40–50 people) — Clock in/out, check announcements, submit service requests, view shifts
4. **Admin** (Bosco) — System configuration, data exports, compliance reports

### Success Metrics

- 100% daily adoption for time tracking (legal requirement)
- <2 second page load time on 4G
- Offline functionality for critical flows (clock-in, task creation)
- Zero auth-related security incidents
- Spanish labor law compliance (Real Decreto-ley 8/2019)

---

## CRITICAL BUGS TO FIX FIRST

These issues block the app from working in production. Fix these before any feature work.

### 1. Backend Disconnected

**Issue**: Google Apps Script endpoint URL is not configured in the frontend. App reads hardcoded demo data from `localStorage` only.

**Evidence**:
- Network tab shows no API calls to Google Apps Script
- Refreshing page doesn't persist changes
- All "saved" data disappears on app close

**Fix**: 
- Configure `window.GAS_URL` in `index.html` to point to your Apps Script deployment URL
- Test end-to-end: create a task → should hit `GAS_URL/exec?action=tasks&method=create`
- Implement basic retry logic for failed requests

**Expected Behavior After Fix**:
```javascript
const GAS_URL = 'https://script.google.com/macros/d/{YOUR_DEPLOYMENT_ID}/usercontent/exec';
// All data changes now sync to Google Sheets
```

### 2. Tracker View CSS Bug

**Issue**: The CRM "Tracker" tab background shows pink/mauve instead of proper card-based styling.

**Evidence**:
- Tab content area has `background-color: var(--rose)` applied to the container instead of individual cards
- Cards are invisible or barely visible against the background

**Fix**:
- Remove `background-color: var(--rose)` from `.tracker-container` or equivalent
- Apply background only to the main page body
- Ensure `.kanban-card`, `.deal-card`, `.contact-card` have white/light backgrounds with proper shadows
- Verify tab CSS in the relevant media query blocks

**CSS Example**:
```css
.tracker-container {
  /* REMOVE: background-color: var(--rose); */
  padding: 1rem;
}

.kanban-card {
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}
```

### 3. All Views Render Empty

**Issue**: No data appears in any tab. Empty state messages show but have no action CTAs.

**Evidence**:
- Dashboard loads but shows no tasks/meetings/stats
- Tracker Tablero is blank
- Contacts list is empty (even though demo data should load)

**Root Cause**: Data loading logic is broken or data is not being read from localStorage correctly.

**Fix**:
1. Verify localStorage key matches: `cosecha_data_v1`
2. Check browser DevTools → Application → LocalStorage → confirm data exists
3. Trace data initialization in JavaScript:
   - Find `loadDemoData()` or similar function
   - Confirm it runs on app startup
   - Verify `renderTasks()`, `renderContacts()`, etc. are called after data load
4. Add console logging to debug:
   ```javascript
   console.log('Loaded data:', window.cosechaData);
   console.log('Tasks:', window.cosechaData?.tareas);
   ```

**Empty State Pattern** (implement for all views):
```html
<div class="empty-state">
  <p>No tasks yet</p>
  <button onclick="showCreateTaskModal()">Create Your First Task</button>
</div>
```

### 4. No Authentication

**Issue**: Anyone with the URL can access the app. No login screen. No access control.

**Critical Security Risk**: Employees' personal data (name, phone, email), time tracking records, and commercial information are exposed.

**Fix Priority**: This must be done BEFORE production deployment.

**Recommended Solution**: Firebase Authentication (free tier)

```javascript
// In index.html, after HTML loads:
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.0/firebase-app.js';
import { getAuth, onAuthStateChanged, signInWithEmailAndPassword } from 'https://www.gstatic.com/firebasejs/10.7.0/firebase-auth.js';

const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

onAuthStateChanged(auth, (user) => {
  if (user) {
    // User is signed in, show app
    document.getElementById('app-container').style.display = 'block';
    window.currentUserId = user.uid;
    window.currentUserEmail = user.email;
    loadAppData();
  } else {
    // User is signed out, show login
    document.getElementById('app-container').style.display = 'none';
    document.getElementById('login-container').style.display = 'block';
  }
});

// Handle login form
document.getElementById('login-form').addEventListener('submit', (e) => {
  e.preventDefault();
  const email = document.getElementById('email').value;
  const password = document.getElementById('password').value;
  
  signInWithEmailAndPassword(auth, email, password)
    .catch(error => {
      alert('Login failed: ' + error.message);
    });
});
```

**Fallback (if Firebase not available)**: Implement PIN-based login for field employees
```javascript
const employeePINs = {
  '1234': { name: 'Juan Garcia', role: 'manager', locationId: 'store-madrid' },
  '5678': { name: 'Maria Lopez', role: 'employee', locationId: 'store-barcelona' },
};

onAppLoad(() => {
  if (!window.currentUser) {
    showPINLoginModal();
  }
});
```

### 5. PWA Manifest Missing Permissions

**Issue**: `manifest.json` does not declare required permissions (geolocation for time tracking, notifications).

**Fix**: Update manifest.json
```json
{
  "name": "Cosecha",
  "short_name": "Cosecha",
  "start_url": "/cosecha/",
  "scope": "/cosecha/",
  "display": "standalone",
  "orientation": "portrait-primary",
  "background_color": "#ffffff",
  "theme_color": "#722F37",
  "icons": [
    {
      "src": "icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ],
  "screenshots": [
    {
      "src": "screenshot-1.png",
      "sizes": "540x720",
      "type": "image/png",
      "form_factor": "narrow"
    }
  ],
  "permissions": [
    "geolocation",
    "notifications"
  ],
  "categories": ["productivity", "business"]
}
```

Also request permissions in JavaScript:
```javascript
async function requestPermissions() {
  try {
    const permResult = await navigator.permissions.query({ name: 'geolocation' });
    if (permResult.state === 'prompt') {
      navigator.geolocation.getCurrentPosition(success, error);
    }
  } catch (e) {
    console.warn('Permissions API not available');
  }
}

if ('Notification' in window && Notification.permission === 'default') {
  Notification.requestPermission();
}
```

### 6. Service Worker Only Caches 3 Files

**Issue**: `sw.js` uses cache-first strategy but only caches index.html, sw.js, manifest.json. Missing all CSS, JS, images, fonts.

**Current**:
```javascript
// sw.js (incomplete)
const CACHE_NAME = 'cosecha-v4';
const filesToCache = [
  '/',
  '/index.html',
  '/manifest.json'
];
```

**Fix**: Implement comprehensive caching + offline fallback

```javascript
// sw.js (improved)
const CACHE_NAME = 'cosecha-v5';
const urlsToCache = [
  '/',
  '/cosecha/',
  '/cosecha/index.html',
  '/cosecha/manifest.json',
  '/cosecha/sw.js',
  '/cosecha/icon-192.png',
  '/cosecha/icon-512.png'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      return cache.addAll(urlsToCache);
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const { request } = event;
  
  // Skip non-GET requests
  if (request.method !== 'GET') return;
  
  // Skip Google Apps Script calls (network only)
  if (request.url.includes('script.google.com')) {
    event.respondWith(fetch(request));
    return;
  }
  
  // Cache-first strategy for assets
  event.respondWith(
    caches.match(request)
      .then(response => response || fetch(request))
      .then(response => {
        // Cache new assets
        if (!response || response.status !== 200) {
          return response;
        }
        
        const responseClone = response.clone();
        caches.open(CACHE_NAME).then(cache => {
          cache.put(request, responseClone);
        });
        
        return response;
      })
      .catch(() => {
        // Offline fallback
        if (request.destination === 'document') {
          return caches.match('/cosecha/index.html');
        }
      })
  );
});
```

**Offline Data Sync** (queue API calls while offline):
```javascript
class OfflineQueue {
  constructor() {
    this.queue = JSON.parse(localStorage.getItem('api_queue') || '[]');
  }
  
  add(request) {
    this.queue.push({
      url: request.url,
      method: request.method,
      body: request.body,
      timestamp: Date.now()
    });
    this.save();
  }
  
  save() {
    localStorage.setItem('api_queue', JSON.stringify(this.queue));
  }
  
  async process() {
    for (const req of this.queue) {
      try {
        const response = await fetch(req.url, {
          method: req.method,
          body: req.body
        });
        if (response.ok) {
          this.queue = this.queue.filter(r => r.timestamp !== req.timestamp);
          this.save();
        }
      } catch (e) {
        console.warn('Sync failed, will retry:', e);
        break; // Stop on first failure
      }
    }
  }
}

// On app load or when connection restored
window.offlineQueue = new OfflineQueue();
window.addEventListener('online', () => {
  window.offlineQueue.process();
});
```

---

## MODULE SPECIFICATIONS

Cosecha is organized into 4 independent modules, each with its own data model, UI, and API endpoints. All modules persist to Google Sheets + sync to Firestore (Phase 2).

### MODULE 1: FICHAJE DIGITAL (Time Clock)

**Priority**: CRITICAL / LEGAL  
**Regulatory**: Real Decreto-ley 8/2019 (Spanish law requiring digital time tracking)  
**Users**: All 50–100 employees

#### Purpose

Provide legally compliant digital time tracking (clock in/out) with geolocation verification. Prove employees worked at assigned locations.

#### Data Model

```
TABLE: Empleados
├─ id (string, PK)
├─ nombre (string)
├─ email (string, unique)
├─ pin (string, 4–6 digits)
├─ rol (enum: admin, manager, empleado, comercial)
├─ ubicacionBase (string, FK → Ubicaciones.id)
├─ activo (boolean)
├─ creado (timestamp)
└─ actualizado (timestamp)

TABLE: Ubicaciones
├─ id (string, PK)
├─ nombre (string) — e.g., "Tienda Madrid Paseo de Gracia"
├─ direccion (string)
├─ latitud (number)
├─ longitud (number)
├─ radioPermitido (number, meters, default 100)
├─ qrCode (string, unique URL-encoded)
├─ activo (boolean)
└─ creado (timestamp)

TABLE: Fichajes
├─ id (string, PK)
├─ empleadoId (string, FK)
├─ empleadoNombre (string, denormalized for reports)
├─ tipo (enum: entrada, salida)
├─ timestamp (timestamp)
├─ latitud (number)
├─ longitud (number)
├─ ubicacion (string, FK → Ubicaciones.id)
├─ distanciaAlcentro (number, meters) — calculated
├─ valido (boolean) — true if within radius
├─ metodo (enum: app, qr, manual) — track how logged
├─ dispositivo (string) — User-Agent
├─ ipAddress (string)
└─ ubicacionManual (string, optional) — if admin overrides

TABLE: Descansos
├─ id (string, PK)
├─ fichajePadreId (string, FK → Fichajes.id)
├─ empleadoId (string, FK)
├─ tiempoDescanso (number, minutes)
├─ tipo (enum: comida, descanso)
└─ timestamp (timestamp)
```

#### Features

**Clock In/Out UI**
- Large button on dashboard: "Fichar" (clock in) or "Terminar Jornada" (clock out)
- Shows status: "📍 Trabajando desde las 09:00" or "⏸️ Pausa (20 min)" or "❌ No fichado"
- One-tap action with immediate geolocation capture
- Confirm modal: "Clock in at Tienda Madrid?" with location name + distance

**Geolocation Verification**
```javascript
async function clockIn() {
  const position = await new Promise((resolve, reject) => {
    navigator.geolocation.getCurrentPosition(resolve, reject, {
      enableHighAccuracy: true,
      timeout: 5000,
      maximumAge: 0
    });
  });
  
  const { latitude, longitude } = position.coords;
  
  // Calculate distance to employee's assigned location
  const distance = calculateDistance(
    latitude, longitude,
    window.currentUser.location.latitud,
    window.currentUser.location.longitud
  );
  
  if (distance > window.currentUser.location.radioPermitido) {
    alert(`⚠️ You are ${Math.round(distance)}m away from your location. Proceed?`);
  }
  
  // Call API
  const result = await apiCall({
    action: 'fichajes',
    method: 'create',
    tipo: 'entrada',
    latitud: latitude,
    longitud: longitude,
    metodo: 'app'
  });
  
  updateUI();
}
```

**QR Code System**
- Each location gets unique QR code (generated in admin panel)
- QR links to: `https://cosecha.example.com/?qr={LOCATION_ID}&token={JWT}`
- Page auto-detects geolocation and submits clock-in without PIN
- Fallback: display location on screen + prompt "Are you here?"

```javascript
// On QR scan page
const params = new URLSearchParams(window.location.search);
const locationId = params.get('qr');

if (locationId && navigator.geolocation) {
  navigator.geolocation.getCurrentPosition(pos => {
    apiCall({
      action: 'fichajes',
      method: 'create',
      tipo: 'entrada',
      latitud: pos.coords.latitude,
      longitud: pos.coords.longitude,
      ubicacion: locationId,
      metodo: 'qr'
    });
  });
}
```

**Daily/Weekly/Monthly Summaries** (for managers)
- View by employee: total hours, breaks taken, late arrivals, location deviations
- Export CSV: for payroll + legal compliance
- Heatmap: show which employees are on-site by location in real-time

**Overtime Calculation**
- Spanish law: standard 40h/week
- Any hours >40 marked as overtime
- Alert manager: "Juan Garcia has 5h overtime this week"
- Include in reports

**Break Time Tracking**
- Spanish law: shifts >6h require tracked breaks
- Employee taps "Pausa" button → start break timer
- System alerts: "Remember to clock back in!" after 1 hour

**Push Notifications**
```javascript
function scheduleShiftReminder() {
  const userSchedule = window.currentUser.schedule; // e.g., 09:00–18:00
  const reminderTime = new Date(userSchedule.inicio);
  reminderTime.setMinutes(reminderTime.getMinutes() - 15);
  
  if ('serviceWorker' in navigator && 'Notification' in window) {
    Notification.requestPermission().then(perm => {
      if (perm === 'granted') {
        // Use Background Sync API if available
        if ('sync' in ServiceWorkerRegistration.prototype) {
          navigator.serviceWorker.ready.then(reg => {
            reg.sync.register('reminder-shift-clock-in');
          });
        }
      }
    });
  }
}
```

**Data Retention**: 4 years (Spanish labor law requirement)

#### API Endpoints

```
POST /exec?action=fichajes&method=create
  Body: { tipo, latitud, longitud, ubicacion, metodo }
  Response: { id, timestamp, valido, distancia }

GET /exec?action=fichajes&method=list&empleadoId=X&desde=DATE&hasta=DATE
  Response: { fichajes: [...] }

GET /exec?action=fichajes&method=summary&empleadoId=X&periodo=week
  Response: { horasTotales, descansos, deviaciones, overtime }

POST /exec?action=descansos&method=create
  Body: { fichajePadreId, tipo, tiempoDescanso }

GET /exec?action=ubicaciones&method=list
  Response: { ubicaciones: [...] }
```

#### Admin Panel Features

- View all employees + their current status (on/off clock)
- Manual clock-in override (for forgotten clocks, emergency)
- Geolocation heatmap by location
- Export for audits/payroll
- Configure location coordinates + allowed radius
- Generate/rotate QR codes

---

### MODULE 2: CRM INTERNO (Internal Communication & Task Management)

**Priority**: HIGH  
**Users**: All 50–100 employees  
**Purpose**: Replace Trello/Notion for daily team collaboration, reduce Slack noise

#### What Needs Fixing

1. **Connect Real Backend** — stop using hardcoded demo data
   - Implement proper GET/POST to Apps Script
   - Persist all changes to Google Sheets
   
2. **Fix Kanban Board Rendering** — CSS bug causing empty display
   - Ensure cards render with proper styling
   - Columns visible and draggable
   
3. **Task Assignment** — integrate with real employee list (from Fichajes module)
   - Multi-select assignees
   - Show assignee avatars + names on cards
   
4. **Task Comments & Mentions**
   - Comment box below task details modal
   - @mention syntax to notify employees
   - Email + in-app notifications
   
5. **File Attachments**
   - Photo upload (already exists)
   - Add generic file upload (PDF, Word, Excel)
   - Store in Google Drive + link in task
   
6. **Pull Google Calendar INTO App**
   - Currently: app pushes meetings to Calendar
   - Change: load meetings from Calendar into Agenda view
   - Show conflicts: "You have a meeting at this time"
   
7. **Announcements System**
   - Bosco/managers post company-wide announcements
   - Pin to dashboard
   - Mark as read by employees
   - Expire announcements after X days

#### Data Model

```
TABLE: Tareas (expanded)
├─ id (string, PK)
├─ título (string)
├─ descripción (string)
├─ columna (enum: backlog, enProgreso, revisión, completado)
├─ prioridad (enum: baja, normal, alta, crítica)
├─ etiqueta (string, multi-valued) — e.g., ["operaciones", "madrid"]
├─ fechaLimite (date)
├─ asignados (array of empleadoId)
├─ proyecto (string, FK → Proyectos.id)
├─ creadoPor (string, FK → Empleados.id)
├─ creado (timestamp)
├─ completado (timestamp, nullable)
├─ actualizadoEn (timestamp)
├─ completadoPor (string, FK → Empleados.id, nullable)
└─ prioridad_urgencia (number) — for AI sorting

TABLE: Comentarios
├─ id (string, PK)
├─ entidadTipo (enum: tarea, contacto, deal, reunión)
├─ entidadId (string, FK)
├─ autorId (string, FK → Empleados.id)
├─ autorNombre (string, denormalized)
├─ texto (string, supports markdown + @mentions)
├─ menciones (array of empleadoId) — extracted from @name
├─ timestamp (timestamp)
├─ actualizadoEn (timestamp)
└─ borradoEn (timestamp, nullable) — soft delete

TABLE: Anuncios
├─ id (string, PK)
├─ título (string)
├─ cuerpo (string, HTML)
├─ autorId (string, FK → Empleados.id)
├─ prioridad (enum: baja, normal, urgente)
├─ destinatarios (enum: todos, ubicacion, equipo, rol) — if ubicacion, include ubicacionId
├─ ubicacionId (string, FK, nullable)
├─ leídoPor (array of empleadoId) — who marked as read
├─ creado (timestamp)
├─ expira (timestamp, nullable)
└─ destacado (boolean) — pin to top

TABLE: Archivos
├─ id (string, PK)
├─ entidadTipo (enum: tarea, contacto, deal, reunión)
├─ entidadId (string, FK)
├─ nombre (string)
├─ url (string) — GCS or Drive link
├─ tipo (enum: imagen, pdf, documento, hoja-calculo, otro)
├─ tamaño (number, bytes)
├─ subidoPor (string, FK → Empleados.id)
├─ timestamp (timestamp)
└─ borradoEn (timestamp, nullable)

TABLE: Proyectos (new)
├─ id (string, PK)
├─ nombre (string)
├─ descripción (string)
├─ lider (string, FK → Empleados.id)
├─ estado (enum: activo, en-pausa, completado)
├─ fechaInicio (date)
├─ fechaFin (date, nullable)
├─ miembros (array of empleadoId)
├─ creado (timestamp)
└─ actualizadoEn (timestamp)
```

#### UI Features

**Dashboard Widget** (show today's key items)
```
┌─────────────────────────────────────┐
│ 📌 Anuncios                         │
│ "Nuevo horario de verano a partir   │
│  del lunes"                          │
├─────────────────────────────────────┤
│ 📋 Mis Tareas Hoy (3)               │
│ □ Llamar a Cliente X (Vence hoy)    │
│ □ Revisar informe (Alta prioridad)  │
│ □ Reunión con equipo (14:00)        │
├─────────────────────────────────────┤
│ 👤 Quien Está Online                │
│ Juan (Madrid), Maria (Barcelona),   │
│ 47 más                              │
└─────────────────────────────────────┘
```

**Kanban Board** (Tablero tab)
```
Backlog        En Progreso        Revisión        Completado
┌──────┐       ┌──────┐           ┌──────┐        ┌──────┐
│Task1 │       │Task5 │           │Task8 │        │Task12│
│█████ │       │ @    │           │ 🔄   │        │ ✓    │
│HIGH  │       │Alta  │           │Alta  │        │Done  │
└──────┘       └──────┘           └──────┘        └──────┘
┌──────┐       ┌──────┐
│Task2 │       │Task6 │
│ @@@  │       │@@@   │
└──────┘       └──────┘
```

**Task Detail Modal** (show comments, attachments, collaborators)
```
┌─ Título: Implementar Module 1 ─────────────┐
│ Prioridad: Alta   |  Límite: 2026-04-20    │
│ Proyecto: Cosecha | Columna: En Progreso  │
│                                             │
│ Asignados: [Juan Garcia] [@Maria López]    │
│ Etiquetas: desarrollo, urgente             │
│                                             │
│ 📝 Descripción                              │
│ Lorem ipsum dolor sit amet                  │
│                                             │
│ 📎 Archivos (2)                             │
│ • spec-v1.pdf (234 KB)                      │
│ • screenshot.png (1.2 MB)                   │
│                                             │
│ 💬 Comentarios (4)                          │
│ Juan Garcia: Empecé la tarea               │
│ Maria López: Necesito acceso a BD           │
│ [You]: Te lo envío en 5 min                 │
│                                             │
│ [Nuevo comentario...                    ]   │
│ [@mention someone]  [📎 Attach] [Enviar]   │
└─────────────────────────────────────────────┘
```

**Announcements Panel**
```
┌─ Anuncios Importantes ───────────┐
│ 🔴 URGENTE: Cambio de horarios   │
│    Nuevo turno a partir de lunes  │
│    [Marcar como leído]            │
│                                   │
│ 🟡 Sistema de fichaje en línea   │
│    Recordatorio: usa la app       │
│    [Marcar como leído]            │
│                                   │
│ 🟢 Evento: Tasting en Barcelona   │
│    Viernes 20h en el local        │
│    [Marcar como leído]            │
└───────────────────────────────────┘
```

**Search** (global search across tasks, contacts, meetings)
```
[🔍 Buscar tareas, contactos, reuniones...]
─ Resultados para "presupuesto"
  ✓ Tarea: Hacer presupuesto para evento (in progress)
  ✓ Contacto: Presupuestos SL (empresa)
  ✓ Meeting: Presentación presupuesto Q2
```

#### API Endpoints

```
POST /exec?action=tareas&method=create
  Body: { título, descripción, columna, prioridad, asignados[], fechaLimite }
  Response: { id, creado }

POST /exec?action=tareas&method=update
  Body: { id, columna, asignados[], estado }
  Response: { success }

POST /exec?action=comentarios&method=create
  Body: { entidadTipo, entidadId, texto }
  Response: { id, timestamp }

POST /exec?action=archivos&method=create
  Body: FormData { entidadTipo, entidadId, file }
  Response: { id, url }

POST /exec?action=anuncios&method=create
  Body: { título, cuerpo, prioridad, destinatarios, expira }
  Response: { id }

GET /exec?action=busqueda&método=search&q=STRING
  Response: { tareas: [...], contactos: [...], reuniones: [...] }
```

---

### MODULE 3: CRM COMERCIAL (Sales Pipeline)

**Priority**: HIGH  
**Users**: Commercial team (5–8), location managers  
**Purpose**: Track visits, deals, orders, events across CODEBA + on-site events

#### Two Separate Pipelines

**CODEBA Distribution Pipeline**:
```
Prospección → Primera Visita → Degustación → Presupuesto → Pedido → Servicio Activo
```

**Events Pipeline**:
```
Lead → Briefing → Propuesta Enviada → Negociación → Confirmado → Ejecutado → Facturado
```

#### Data Model

```
TABLE: VisitasComerciales
├─ id (string, PK)
├─ comercialId (string, FK → Empleados.id)
├─ contactoId (string, FK → Contactos.id)
├─ tipo (enum: presencial, llamada, email, videollamada)
├─ fecha (date)
├─ duracion (number, minutes)
├─ ubicacion (string) — "Tienda Madrid" or "Zoom"
├─ latitud (number, nullable) — for in-person verification
├─ longitud (number, nullable)
├─ distancia (number, nullable) — from commercial's location
├─ notas (string) — what was discussed
├─ siguientePaso (string) — e.g., "Enviar presupuesto"
├─ dealId (string, FK → Deals.id, nullable)
├─ resultado (enum: exitosa, sin-interés, pospuesto)
├─ creadoPor (string, FK → Empleados.id)
├─ creado (timestamp)
└─ actualizado (timestamp)

TABLE: Deals (expanded)
├─ id (string, PK)
├─ título (string)
├─ tipo (enum: codeba, evento)
├─ contactoId (string, FK → Contactos.id)
├─ contactoNombre (string, denormalized)
├─ valor (number, EUR)
├─ valor_esperado (number, EUR) — for probability calc
├─ etapa (string) — matches pipeline stage
├─ probabilidad (number, 0–100) — based on etapa
├─ cierreEsperado (date)
├─ asignado (string, FK → Empleados.id)
├─ notas (string)
├─ historialEtapas (array) — { etapa, fecha, por }
├─ creadoPor (string, FK → Empleados.id)
├─ creado (timestamp)
└─ actualizadoEn (timestamp)

TABLE: Pedidos
├─ id (string, PK)
├─ dealId (string, FK → Deals.id)
├─ contactoId (string, FK → Contactos.id)
├─ productos (array) — { producto, cantidad, precioUnitario }
├─ valorTotal (number, EUR)
├─ estado (enum: pendiente, confirmado, enviado, entregado, facturado)
├─ fechaPedido (date)
├─ fechaEntrega (date, nullable)
├─ referencias (array) — e.g., "PO-2026-001"
├─ notas (string)
├─ creado (timestamp)
└─ actualizado (timestamp)

TABLE: Eventos
├─ id (string, PK)
├─ dealId (string, FK → Deals.id)
├─ contactoId (string, FK → Contactos.id)
├─ nombre (string) — e.g., "Wine Tasting Barcelona"
├─ fecha (date)
├─ ubicacion (string)
├─ tipoEvento (enum: cata, cena, feria, otro)
├─ numPersonas (number)
├─ presupuesto (number, EUR)
├─ presupuestoReal (number, EUR, nullable)
├─ estado (enum: propuesto, confirmado, ejecutado, facturado)
├─ serviciosContratados (array) — which ECDB venues/restaurants involved
├─ notas (string)
├─ creado (timestamp)
└─ actualizado (timestamp)

TABLE: KPIsComerciales
├─ id (string, PK)
├─ comercialId (string, FK → Empleados.id)
├─ periodo (enum: semana, mes, trimestre, año) + date
├─ visitasRealizadas (number)
├─ llamadasRealizadas (number)
├─ dealsCreados (number)
├─ dealsCerrados (number)
├─ valorCerrado (number, EUR)
├─ tasaConversion (number, %) — deals closed / deals created
├─ valorPromedioPorDeal (number, EUR)
├─ tiempoPromedioCierre (number, days)
└─ calculado (timestamp)
```

#### Features

**Visit Logging** (quick 30-second entry)
```
┌─ Registrar Visita ────────────────────┐
│ Tipo: [Presencial ▼]                  │
│ Contacto: [José García - Distribu...] │
│ Notas: Presentó nuevo catálogo        │
│ Interés: [Sí ▼]                       │
│ Próximo paso: Enviar presupuesto      │
│ [Registrar Visita]                    │
└──────────────────────────────────────── ┘
```

**Geolocation Verification** (for in-person visits)
- Capture latitude/longitude when logging visit
- Manager sees: "Juan visited Distribuidor XYZ in Barcelona (142m from location)"
- Prevents false logging

**Deal Board** (visual pipeline)
```
Prospección      Primera Visita    Degustación      Presupuesto
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────┐
│José García   │ │Distribuidor  │ │Wine Fair NYC │ │Event XYZ │
│Distribu. SL  │ │ABC           │ │5000€         │ │2500€     │
│Est: 15k€     │ │Est: 8k€      │ │Prob: 60%     │ │Prob: 30% │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────┘
           │              │              │              │
           └──────────────┴──────────────┴──────────────┘
               Drag to move deals between stages
```

**Route Planning** (for field sales)
```
🗺️ Mis Visitas Hoy (5)
📍 10:00 — Distribuidor ABC (Madrid, 5km)
📍 11:30 — Cliente XYZ (Madrid, 8km)
📍 13:00 — Restaurante El Patio (Madrid, 2km)
📍 15:00 — Tienda Habanos (Madrid, 6km)
📍 17:00 — Despacho Central (Madrid, 1km)
[Optimizar ruta] [Navegar]
```

**Sales Targets & Leaderboard** (by week/month)
```
Leaderboard — Abril 2026

👑 Maria López      €45,000 cerrado | 12 deals
  ↳ 2 visitas pendientes, 92% tasa conversión

2️⃣ Juan García      €28,500 cerrado | 7 deals
  ↳ 1 visita pendiente, 75% tasa conversión

3️⃣ Pedro Sánchez    €18,200 cerrado | 5 deals
```

**Weekly/Monthly Reports** (exportable)
```
Informe Comercial — Semana 15, 2026

Juan García (Comercial)
━━━━━━━━━━━━━━━━━━━━━━
Visitas realizadas:  6 (2 presenciales, 3 llamadas, 1 email)
Calls duración media: 18 minutos
Deals creados:       2 (€8.5k, €6.2k)
Deals cerrados:      1 (€12k)
% Conversión:        50%
Próximo paso:        Presupuesto para 2 clientes
```

#### API Endpoints

```
POST /exec?action=visitasComerciales&method=create
  Body: { comercialId, contactoId, tipo, ubicacion, notas, resultado, dealId }
  Response: { id, latitud, longitud, distancia }

POST /exec?action=deals&method=update
  Body: { id, etapa, probabilidad }
  Response: { success, historial }

GET /exec?action=kpis&method=get&comercialId=X&periodo=mes
  Response: { visitasRealizadas, dealsCreados, dealsCerrados, tasaConversion, ... }

POST /exec?action=pedidos&method=create
  Body: { dealId, productos[], valorTotal }
  Response: { id, referencias }

GET /exec?action=eventos&method=list&estado=confirmado
  Response: { eventos: [...] }
```

---

### MODULE 4: PORTAL DEL EMPLEADO (Employee Self-Service)

**Priority**: MEDIUM  
**Users**: All 50–100 employees  
**Purpose**: Internal help desk, job board, referral program, document management

#### Data Model

```
TABLE: Solicitudes (Help Desk)
├─ id (string, PK)
├─ empleadoId (string, FK → Empleados.id)
├─ categoria (enum: IT, RRHH, Mantenimiento, Admin, Otro)
├─ titulo (string) — e.g., "Reset password", "Request time off"
├─ descripcion (string)
├─ prioridad (enum: baja, normal, alta)
├─ estado (enum: nueva, enProceso, resuelta, cerrada)
├─ asignadoA (string, FK → Empleados.id, nullable)
├─ respuesta (string)
├─ timestamp (timestamp)
├─ resuelto (timestamp, nullable)
└─ satisfaccion (number, 1–5, nullable) — after close

TABLE: OfertasEmpleo
├─ id (string, PK)
├─ titulo (string) — e.g., "Sommelier - Madrid"
├─ ubicacion (string) — FK → Ubicaciones.id (can be multi-location)
├─ departamento (enum: operaciones, comercial, cocina, servicio)
├─ descripcion (string, HTML)
├─ requisitos (array) — e.g., ["3+ años experiencia", "Permiso B"]
├─ salario (string) — e.g., "€18.000–€22.000/año"
├─ tipoContrato (enum: indefinido, temporal, practicas)
├─ estado (enum: abierta, cerrada, completada)
├─ creado (timestamp)
├─ cierre (timestamp)
└─ candidatos (array of Candidatos.id) — who applied

TABLE: Referidos
├─ id (string, PK)
├─ referidoPorId (string, FK → Empleados.id)
├─ referidoPorNombre (string, denormalized)
├─ candidatoNombre (string)
├─ candidatoTelefono (string)
├─ candidatoEmail (string)
├─ puestoId (string, FK → OfertasEmpleo.id, nullable)
├─ puestoTitulo (string, denormalized)
├─ estado (enum: enviado, enProceso, contratado, descartado)
├─ fechaEnvio (timestamp)
├─ fechaContratacion (timestamp, nullable)
├─ fechaBonificacion (timestamp, nullable) — 6 months after hire
├─ montoBonificacion (number, EUR, default 200)
├─ notificacionEnviada (boolean)
├─ notas (string)
└─ creado (timestamp)

TABLE: Documentos
├─ id (string, PK)
├─ empleadoId (string, FK → Empleados.id)
├─ tipo (enum: nomina, contrato, politica, certificado, otro)
├─ titulo (string) — e.g., "Nómina Marzo 2026"
├─ url (string) — Google Drive link
├─ periodo (string) — e.g., "2026-03"
├─ descargado (timestamp, nullable)
├─ creado (timestamp)
└─ expira (timestamp, nullable)

TABLE: OnboardingChecklist
├─ id (string, PK)
├─ empleadoId (string, FK → Empleados.id)
├─ nuevoEmpleado (boolean)
├─ items (array) —
│   {
│     item: "Completar formulario datos personales",
│     completado: boolean,
│     completadoEn: timestamp
│   }
├─ creado (timestamp)
└─ completado (timestamp, nullable)
```

#### Features

**Help Desk Ticket System**
```
┌─ Nueva Solicitud ──────────────────┐
│ Categoría: [IT ▼]                  │
│ Título: Necesito acceso a Drive    │
│ Descripción:                        │
│ [Quiero acceder a la carpeta de ... │
│  ...proyectos]                      │
│                                     │
│ Prioridad: [Normal ▼]               │
│ [Enviar Solicitud]                  │
└─────────────────────────────────────┘

[Mis Solicitudes]
✓ Actualizar contraseña (Resuelta)
⏳ Acceso a Drive (En proceso)
```

**Job Board**
```
┌─ Ofertas de Empleo ──────────────────┐
│                                       │
│ 🏆 Sommelier - Tienda Barcelona       │
│    Salario: €19.000–€23.000           │
│    Tipo: Indefinido                   │
│    📍 Barcelona                        │
│    [Ver detalles] [Referir amigo]     │
│                                       │
│ 👨‍💼 Gerente Operaciones - Madrid         │
│    Salario: €25.000–€30.000           │
│    Tipo: Indefinido                   │
│    📍 Madrid                          │
│    [Ver detalles] [Referir amigo]     │
│                                       │
│ 🍽️ Chef Pastelero - Restaurante       │
│    Salario: €18.000–€21.000           │
│    Tipo: Temporal (6 meses)           │
│    📍 Bilbao                          │
│    [Ver detalles] [Referir amigo]     │
└───────────────────────────────────────┘
```

**Referral Program**
```
┌─ Referir Candidato ────────────────┐
│ Puesto: [Sommelier - Barcelona ▼]  │
│ Nombre: [_______________________]  │
│ Teléfono: [______________________] │
│ Email: [________________________]   │
│ Mensaje: "Juan es un excelente..."  │
│                                     │
│ [Referir]                           │
└────────────────────────────────────┘

[Mis Referidos]
✓ María García       → Sommelier (CONTRATADA!) 🎉
  Bonificación desbloqueada: €200
  [Reclamar]
⏳ Pedro Sánchez     → Chef (En proceso)
  Enviado hace 3 meses
❌ Juan López        → Gerente (Descartado)
```

**Document Portal**
```
┌─ Mis Documentos ──────────────────┐
│                                    │
│ 📄 Nóminas (2026)                  │
│   • Marzo 2026          [Descargar]│
│   • Febrero 2026        [Descargar]│
│   • Enero 2026          [Descargar]│
│                                    │
│ 📋 Contrato                        │
│   • Contrato indefinido [Descargar]│
│                                    │
│ 📘 Políticas                       │
│   • Manual de empleado  [Descargar]│
│   • Código de conducta  [Descargar]│
│                                    │
│ 🎓 Certificados                    │
│   • Certificado seguridad [Descargar]
└────────────────────────────────────┘
```

**Onboarding Checklist** (for new hires)
```
👋 Bienvenido al equipo ECDB!

Tu checklist de onboarding:
[✓] Firmé mi contrato
[✓] Completé datos personales
[  ] Asistí a capacitación laboral
[  ] Configuré mi acceso IT
[  ] Leí el código de conducta
[  ] Pasé capacitación de seguridad
[  ] Conocí a mi equipo
[  ] Fui agregado a sistemas de nómina

Progreso: 3/8 (37%)
Estimado: 5 días laborales
```

#### API Endpoints

```
POST /exec?action=solicitudes&method=create
  Body: { categoria, titulo, descripcion, prioridad }
  Response: { id, estado: "nueva" }

GET /exec?action=solicitudes&method=list&estado=enProceso
  Response: { solicitudes: [...] }

POST /exec?action=referidos&method=create
  Body: { puestoId, candidatoNombre, candidatoEmail, candidatoTelefono }
  Response: { id, estado: "enviado" }

POST /exec?action=referidos&method=checkBonificacion
  Runs daily: find referidos hired 6+ months ago, flag for €200 payment
  Response: { pendientes: [...] }

GET /exec?action=documentos&method=list&empleadoId=X
  Response: { documentos: [...] }

GET /exec?action=documentos&method=descargar&id=X
  Response: Redirect to Google Drive download
```

---

## DATA MODELS

### Core Shared Model: Empleados (Employee)

All modules reference this as the source of truth for employee metadata.

```
TABLE: Empleados
├─ id (string, PK) — UUID
├─ nombre (string) — Full name
├─ email (string, unique)
├─ telefono (string, optional)
├─ pin (string, 4–6 digits) — For touchless login
├─ rol (enum) — Controls permissions:
│   ├─ admin — Full system access (Bosco)
│   ├─ manager — View location + team data, create tasks/announcements
│   ├─ empleado — Clock in, tasks, announcements, help desk
│   ├─ comercial — + Sales/visits, deals, KPIs
│   └─ rrhh — + Help desk admin, payroll export
├─ ubicacionBase (string, FK → Ubicaciones.id)
├─ departamento (enum: operaciones, comercial, cocina, servicio, admin, rrhh)
├─ fotoPerfil (string, URL)
├─ salarioMensual (number, EUR, encrypted)
├─ contratoTipo (enum: indefinido, temporal, practicas)
├─ fechaAlta (date)
├─ numeroSeguroSocial (string, encrypted, PII)
├─ activo (boolean)
├─ ultimaActividadEn (timestamp) — For "online" status
├─ notificacionesActivadas (boolean)
├─ idiomaPreferido (enum: es, en, ca, gl)
├─ creado (timestamp)
├─ actualizadoEn (timestamp)
└─ borradoEn (timestamp, nullable) — Soft delete for GDPR

### Shared: Contactos (Prospects/Clients)

```
TABLE: Contactos
├─ id (string, PK)
├─ nombre (string)
├─ email (string)
├─ telefono (string)
├─ empresa (string, FK → Empresas.id, nullable)
├─ tipo (enum: cliente, prospecto, partner, distribuidor, eventos)
├─ etiquetas (array) — e.g., ["bulk-buyer", "seasonal"]
├─ notas (string)
├─ persona_contacto (string) — Who we know
├─ ultimoContacto (timestamp)
├─ creado (timestamp)
└─ actualizadoEn (timestamp)

TABLE: Empresas
├─ id (string, PK)
├─ nombre (string)
├─ dominio (string)
├─ industria (string)
├─ empleados (number)
├─ ubicacion (string)
├─ telefonoEmpresa (string)
├─ sitioWeb (string)
└─ creado (timestamp)
```

---

## ARCHITECTURE RECOMMENDATIONS

### Current Problem

- **Single HTML file** (~3000 lines) = unmaintainable, no code reuse
- **localStorage only** = no multi-device sync, no real-time collaboration
- **Google Apps Script as database** = bottleneck, limited scalability
- **No build system** = no minification, no tree-shaking, no module support
- **No framework** = vanilla JS callbacks, hard to test, prone to bugs

### Recommended Migration Path

#### Phase 0: Modularize Frontend (2–3 weeks)
- Split `index.html` into ES modules
- Create folder structure:
  ```
  src/
  ├─ modules/
  │  ├─ fichaje/
  │  │  ├─ ui.js
  │  │  ├─ api.js
  │  │  └─ data.js
  │  ├─ crm-interno/
  │  ├─ crm-comercial/
  │  ├─ portal-empleado/
  │  └─ shared/
  │     ├─ auth.js
  │     ├─ api-client.js
  │     ├─ storage.js
  │     └─ ui-components.js
  ├─ styles/
  │  ├─ tokens.css (design system)
  │  ├─ components.css
  │  └─ layouts.css
  └─ index.html (tiny, just imports)
  ```
- Add build tool: **Vite** (5–10 min setup)
  ```bash
  npm create vite@latest cosecha -- --template vanilla
  npm install
  npm run build  # Outputs optimized to dist/
  ```
- Existing logic: no changes, just split into files
- Output: ~100KB gzipped (currently ~300KB uncompressed)

**Cost**: Low risk, high benefit. Can deploy to same GitHub Pages endpoint.

#### Phase 1: Add Authentication (1 week)

**Option A: Firebase Auth** (recommended)
- Free tier: unlimited users
- OAuth/email/phone support
- Integrates with Firestore Phase 2
- Code (in `src/modules/shared/auth.js`):
  ```javascript
  import { initializeApp } from 'firebase/app';
  import { getAuth, onAuthStateChanged, signOut } from 'firebase/auth';
  
  const firebaseConfig = { /* see Phase 2 */ };
  const app = initializeApp(firebaseConfig);
  export const auth = getAuth(app);
  
  export function onAuthReady(callback) {
    onAuthStateChanged(auth, callback);
  }
  
  export async function logout() {
    await signOut(auth);
  }
  ```
- Update `index.html`:
  ```html
  <div id="login-container" style="display: none;">
    <form id="login-form">
      <input type="email" id="email" required />
      <input type="password" id="password" required />
      <button type="submit">Entrar</button>
    </form>
  </div>
  
  <div id="app-container" style="display: none;">
    <!-- Existing app HTML -->
  </div>
  
  <script type="module">
    import { onAuthReady } from './src/modules/shared/auth.js';
    
    onAuthReady((user) => {
      const login = document.getElementById('login-container');
      const app = document.getElementById('app-container');
      
      if (user) {
        login.style.display = 'none';
        app.style.display = 'block';
        window.currentUser = { uid: user.uid, email: user.email };
      } else {
        login.style.display = 'block';
        app.style.display = 'none';
      }
    });
  </script>
  ```

**Option B: Pin-based (if Firebase unavailable)**
- Simple 4-digit PIN per employee
- Keep in encrypted column of Empleados table
- Backend validates PIN, returns session token
- Include token in all API calls

#### Phase 2: Migrate to Firestore (2 weeks)

**Why**: Google Sheets is not a database. Can't query, can't scale, can't sync in real-time.

**Firestore advantages**:
- Real-time sync across devices
- Offline persistence built-in
- Rich queries and indexes
- SDKs for web, iOS, Android
- Free tier: 50K reads, 20K writes, 1GB storage/month
- Integrates seamlessly with Firebase Auth

**Migration steps**:
1. Keep Google Sheets as backup/audit log only
2. Replicate Google Sheets schema to Firestore:
   ```
   firestore/
   ├─ empleados/{id}
   ├─ ubicaciones/{id}
   ├─ fichajes/{id}
   ├─ tareas/{id}
   ├─ contactos/{id}
   ├─ deals/{id}
   ├─ reuniones/{id}
   ├─ comentarios/{entidadTipo}/{entidadId}/comentarios/{id}
   ├─ anuncios/{id}
   └─ documentos/{id}
   ```
3. Update API client in `src/modules/shared/api-client.js`:
   ```javascript
   import { getFirestore, collection, addDoc, query, where, getDocs, updateDoc, deleteDoc } from 'firebase/firestore';
   
   const db = getFirestore(firebaseApp);
   
   export async function createTarea(data) {
     const ref = await addDoc(collection(db, 'tareas'), {
       ...data,
       creado: new Date(),
       creadoPor: window.currentUser.uid
     });
     return ref.id;
   }
   
   export async function getTareas(usuarioId) {
     const q = query(
       collection(db, 'tareas'),
       where('asignados', 'array-contains', usuarioId)
     );
     const snapshot = await getDocs(q);
     return snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
   }
   
   // ... other CRUD operations
   ```
4. Update existing code to use new API (gradual rollout)
5. Run data migration script (move Google Sheets → Firestore)
6. Decommission Google Apps Script (keep Calendar/Granola only)

**Cost**: Medium effort, high value. Near-zero downtime with feature flag.

#### Phase 3: Implement Offline + Push Notifications (1 week)

**Offline**: Firestore has built-in offline persistence. Enable in app initialization:
```javascript
import { enableIndexedDbPersistence } from 'firebase/firestore';

enableIndexedDbPersistence(db)
  .catch(err => {
    if (err.code === 'failed-precondition') {
      console.log('Multiple tabs open, persistence disabled');
    } else if (err.code === 'unimplemented') {
      console.log('Browser does not support offline persistence');
    }
  });
```

**Push Notifications**: Use Firebase Cloud Messaging (free tier)
```javascript
import { getMessaging, getToken, onMessage } from 'firebase/messaging';

const messaging = getMessaging(firebaseApp);

// Request permission + get token
Notification.requestPermission().then(perm => {
  if (perm === 'granted') {
    getToken(messaging, {
      vapidKey: 'YOUR_VAPID_KEY'
    }).then(token => {
      // Send token to backend for future notifications
      console.log('FCM Token:', token);
    });
  }
});

// Listen for incoming notifications
onMessage(messaging, (payload) => {
  console.log('Message received:', payload);
  new Notification(payload.notification.title, {
    body: payload.notification.body,
    icon: payload.notification.icon
  });
});
```

#### Phase 4: Add Testing (ongoing)

**Unit Tests** (Vitest):
```bash
npm install -D vitest happy-dom
```

`src/modules/fichaje/overtime.test.js`:
```javascript
import { describe, it, expect } from 'vitest';
import { calculateOvertime } from './overtime.js';

describe('Overtime Calculation', () => {
  it('calculates overtime for 45h week', () => {
    const hours = [9, 8, 8, 8, 8, 4]; // Mon–Fri + Sat morning
    const overtime = calculateOvertime(hours);
    expect(overtime).toBe(5); // 45 - 40 = 5h
  });
  
  it('returns 0 for 40h week', () => {
    const hours = [8, 8, 8, 8, 8];
    expect(calculateOvertime(hours)).toBe(0);
  });
});
```

**E2E Tests** (Playwright):
```bash
npm install -D @playwright/test
```

`e2e/clock-in.spec.js`:
```javascript
import { test, expect } from '@playwright/test';

test('Clock in with valid geolocation', async ({ page }) => {
  await page.goto('http://localhost:5173');
  
  // Login
  await page.fill('#email', 'juan@ecdb.es');
  await page.fill('#password', 'password123');
  await page.click('#login-form button');
  await page.waitForSelector('[data-testid="dashboard"]');
  
  // Mock geolocation
  await page.context().grantPermissions(['geolocation']);
  await page.context().setGeolocation({ latitude: 40.4168, longitude: -3.7038 });
  
  // Click clock-in
  await page.click('[data-testid="clock-in-btn"]');
  
  // Verify success
  await expect(page.locator('[data-testid="status"]')).toContainText('Trabajando');
});
```

### Framework Recommendation

Choose **Vue.js** or **React**:

| Criteria | Vue | React |
|----------|-----|-------|
| Learning curve | Easier | Steeper |
| PWA support | Excellent | Good |
| Community | Growing | Largest |
| For ECDB | Recommended | Alternative |

**Vue.js setup** (for Phase 0+):
```bash
npm create vite@latest cosecha -- --template vue
npm install pinia # State management (replaces localStorage)
npm install axios # HTTP client
npm install vee-validate # Form validation
```

**App.vue**:
```vue
<template>
  <div v-if="!user" class="login-page">
    <LoginForm @submit="handleLogin" />
  </div>
  <div v-else class="app">
    <NavBar />
    <RouterView />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

const authStore = useAuthStore();
const router = useRouter();

const user = computed(() => authStore.user);

const handleLogin = async (email, password) => {
  await authStore.login(email, password);
  router.push('/');
};
</script>
```

---

## UI/UX GUIDELINES

### Design System

**Color Palette** (from ECDB brand):
```css
:root {
  /* Primary burgundy (wine) */
  --primary: #722F37;
  --primary-light: #a8515a;
  --primary-dark: #4a1f23;
  
  /* Gold accents */
  --accent: #d4a574;
  --accent-light: #e8c9a8;
  
  /* Rose (use sparingly, not as background!) */
  --rose: #d9a5a5;
  
  /* Neutrals */
  --white: #ffffff;
  --light: #f5f3f0;
  --gray-light: #e8e6e3;
  --gray: #a8a8a8;
  --gray-dark: #5a5a5a;
  --dark: #2d2d2d;
  
  /* Semantic */
  --success: #4caf50;
  --warning: #ff9800;
  --error: #f44336;
  --info: #2196f3;
  
  /* Spacing */
  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;
  
  /* Typography */
  --font-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', sans-serif;
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-md: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-xxl: 1.5rem;
  
  /* Border radius */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-full: 9999px;
  
  /* Shadows */
  --shadow-xs: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.1);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
}
```

### Component Library

**Button Variants**:
```html
<!-- Primary action -->
<button class="btn btn-primary">Enviar</button>

<!-- Secondary action -->
<button class="btn btn-secondary">Cancelar</button>

<!-- Destructive action -->
<button class="btn btn-danger">Eliminar</button>

<!-- Loading state -->
<button class="btn btn-primary" disabled>
  <span class="spinner"></span> Guardando...
</button>
```

**Form Patterns**:
```html
<div class="form-group">
  <label for="email" class="form-label">Email <span class="required">*</span></label>
  <input type="email" id="email" class="form-input" required />
  <span class="form-error" id="email-error"></span>
</div>
```

**Card Pattern**:
```html
<div class="card">
  <div class="card-header">
    <h3 class="card-title">Título</h3>
    <span class="card-badge badge-primary">Etiqueta</span>
  </div>
  <div class="card-body">Contenido</div>
  <div class="card-footer">
    <button class="btn btn-secondary">Acción</button>
  </div>
</div>
```

**Modal Sheet** (for creation, since app already uses this pattern):
```html
<div class="sheet-overlay" id="sheet-overlay">
  <div class="sheet">
    <div class="sheet-header">
      <h2>Nueva Tarea</h2>
      <button class="sheet-close" onclick="closeSheet()">&times;</button>
    </div>
    <div class="sheet-content">
      <!-- Form here -->
    </div>
    <div class="sheet-footer">
      <button class="btn btn-secondary" onclick="closeSheet()">Cancelar</button>
      <button class="btn btn-primary" onclick="submitForm()">Crear</button>
    </div>
  </div>
</div>
```

### Mobile-First Design

- **Viewport**: `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">`
- **Bottom navigation**: Keep 5-tab pattern, but reduce padding on mobile
- **Touch targets**: Minimum 44px × 44px (accessibility)
- **Responsive breakpoints**:
  ```css
  @media (max-width: 640px) { /* Mobile */ }
  @media (min-width: 641px) and (max-width: 1024px) { /* Tablet */ }
  @media (min-width: 1025px) { /* Desktop */ }
  ```

### Empty States

**Pattern**: Icon + headline + description + CTA

```html
<div class="empty-state">
  <div class="empty-state-icon">📋</div>
  <h3 class="empty-state-title">No tienes tareas</h3>
  <p class="empty-state-description">
    Crea tu primera tarea para empezar a organizarte
  </p>
  <button class="btn btn-primary" onclick="showCreateModal()">
    + Crear Tarea
  </button>
</div>
```

### Loading States

Use skeleton screens instead of spinners:
```html
<div class="task-card skeleton">
  <div class="skeleton-line" style="width: 70%;"></div>
  <div class="skeleton-line" style="width: 100%;"></div>
  <div class="skeleton-line" style="width: 50%;"></div>
</div>

<style>
.skeleton {
  background: linear-gradient(
    90deg,
    var(--gray-light) 0%,
    var(--white) 50%,
    var(--gray-light) 100%
  );
  background-size: 200% 100%;
  animation: loading 1.5s infinite;
}

@keyframes loading {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
</style>
```

### Error Handling

**Toast notifications** (temporary messages):
```javascript
function showToast(message, type = 'info', duration = 3000) {
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.textContent = message;
  document.body.appendChild(toast);
  
  setTimeout(() => {
    toast.classList.add('toast-exit');
    setTimeout(() => toast.remove(), 300);
  }, duration);
}

// Usage
try {
  await createTask(taskData);
  showToast('Tarea creada correctamente', 'success');
} catch (error) {
  showToast('Error: ' + error.message, 'error');
}
```

### Accessibility

- **Color contrast**: WCAG AA minimum (4.5:1 for text)
- **Focus states**: Every interactive element visible when focused
- **Alt text**: All images have meaningful `alt` attributes
- **Semantic HTML**: Use `<button>`, `<label>`, `<fieldset>`, not `<div>` for interaction
- **ARIA**: Use `aria-label`, `aria-describedby`, `role` where semantic HTML insufficient

---

## ENVIRONMENT & DEPLOYMENT

### Current

- **Hosting**: GitHub Pages (static, no server)
- **Backend**: Google Apps Script (free tier)
- **Database**: Google Sheets (not a real database)
- **Problem**: Can't handle real-time sync, no file uploads, limited scaling

### Recommended: Firebase Hosting + Firestore

**Setup** (30 minutes):

1. **Create Firebase project**:
   - Go to [console.firebase.google.com](https://console.firebase.google.com)
   - Create project "cosecha"
   - Enable Firestore, Authentication, Hosting, Cloud Storage

2. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase init
   ```
   
   Select:
   - Firestore
   - Authentication
   - Hosting
   - Cloud Functions (optional, for scheduled tasks)

3. **Configure `firebase.json`**:
   ```json
   {
     "hosting": {
       "public": "dist",
       "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
       "rewrites": [
         {
           "source": "**",
           "destination": "/index.html"
         }
       ]
     },
     "firestore": {
       "rules": "firestore.rules",
       "indexes": "firestore.indexes.json"
     },
     "storage": {
       "rules": "storage.rules"
     }
   }
   ```

4. **Firestore security rules** (`firestore.rules`):
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users can only read/write their own data
       match /empleados/{uid} {
         allow read, write: if request.auth.uid == uid || isAdmin();
       }
       
       // Tasks: read own, read assigned, write own
       match /tareas/{document=**} {
         allow read: if request.auth != null;
         allow create: if request.auth != null;
         allow update, delete: if isOwner() || isAdmin();
       }
       
       // Helper functions
       function isAdmin() {
         return get(/databases/$(database)/documents/empleados/$(request.auth.uid)).data.rol == 'admin';
       }
       
       function isOwner() {
         return resource.data.creadoPor == request.auth.uid;
       }
     }
   }
   ```

5. **Build & deploy**:
   ```bash
   npm run build
   firebase deploy
   ```
   
   App live at: `https://cosecha.firebaseapp.com`

### CI/CD with GitHub Actions

`.github/workflows/deploy.yml`:
```yaml
name: Deploy to Firebase

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - run: npm ci
      - run: npm run build
      
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: cosecha
```

### Environment Variables

Create `.env.local` (never commit):
```
VITE_FIREBASE_API_KEY=AIzaSyD...
VITE_FIREBASE_AUTH_DOMAIN=cosecha.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=cosecha
VITE_FIREBASE_STORAGE_BUCKET=cosecha.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789
VITE_FIREBASE_APP_ID=1:123456789:web:abc123...
```

Load in `src/firebase.js`:
```javascript
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  // ...
};
```

---

## SECURITY REQUIREMENTS

### Authentication & Authorization

1. **Require login for all endpoints**
   - No public access to any data
   - Session timeout: 30 minutes inactivity
   - Re-authentication for sensitive actions (delete, export)

2. **Role-based access control** (RBAC)
   - **Admin** (Bosco): Full system access
   - **Manager**: View location + team data, approve help desk requests
   - **Employee**: Own data only (tasks, time tracking), read public announcements
   - **Commercial**: + Sales data, visit logs, deals
   - **RRHH**: + Help desk admin, payroll access

3. **Enforce at database level** (Firestore rules, not just frontend)
   ```
   // Only employees can see their own documents
   match /empleados/{uid} {
     allow read, write: if request.auth.uid == uid;
   }
   
   // Managers can see team members at their location
   match /empleados/{uid} {
     allow read: if isManagerOfLocation(uid);
   }
   ```

### Data Protection

1. **Encryption at rest**
   - Firebase encryption included (all Firestore data encrypted)
   - Sensitive fields (SSN, salary) stored in separate collection with tighter rules

2. **Encryption in transit**
   - HTTPS only (Firebase Hosting enforces)
   - TLS 1.2+ for all API calls

3. **PII (Personally Identifiable Information)**
   - SSN, phone, salary: encrypted fields with restricted access
   - Never log to console or error messages
   - Backup retention: 7 days (Firebase default)

### API Security

1. **No API keys in client code**
   - Firebase SDK handles auth transparently
   - Google Apps Script deployment: use Firebase Auth token, not API key

2. **Rate limiting** (if using Cloud Functions)
   ```javascript
   import * as functions from 'firebase-functions';
   import * as rateLimit from 'express-rate-limit';
   
   const limiter = rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 100, // 100 requests per window
     keyGenerator: (req) => req.user.uid // Per-user limit
   });
   
   exports.createTask = functions.https.onRequest(
     limiter,
     async (req, res) => { /* handler */ }
   );
   ```

3. **Input validation**
   - Validate ALL user input on client AND server
   - Use schema validation (e.g., Zod, Joi)
   ```javascript
   import { z } from 'zod';
   
   const CreateTaskSchema = z.object({
     titulo: z.string().min(3).max(100),
     descripcion: z.string().max(1000),
     prioridad: z.enum(['baja', 'normal', 'alta', 'crítica']),
     fechaLimite: z.string().datetime().optional()
   });
   
   async function createTask(data) {
     const validated = CreateTaskSchema.parse(data);
     // Proceed with validated data only
   }
   ```

### Session Management

1. **No stored passwords on device**
   - Firebase handles auth token storage securely
   - Use `onAuthStateChanged` to persist login across page reloads

2. **Session timeout**
   ```javascript
   let inactivityTimer;
   
   function resetInactivityTimer() {
     clearTimeout(inactivityTimer);
     inactivityTimer = setTimeout(() => {
       showModal('Sesión expirada. Por favor, inicia sesión de nuevo.');
       auth.signOut();
     }, 30 * 60 * 1000); // 30 minutes
   }
   
   document.addEventListener('click', resetInactivityTimer);
   document.addEventListener('keypress', resetInactivityTimer);
   ```

3. **Logout on device lock** (for PWA)
   ```javascript
   document.addEventListener('visibilitychange', () => {
     if (document.hidden) {
       // Device locked or app backgrounded
       // Don't logout immediately, but clear sensitive UI
     }
   });
   ```

### Audit Logging

Track sensitive operations:
```javascript
async function logAuditEvent(action, entityType, entityId, details) {
  await addDoc(collection(db, 'auditLog'), {
    user: window.currentUser.uid,
    email: window.currentUser.email,
    action,
    entityType,
    entityId,
    details,
    ipAddress: await getClientIP(),
    timestamp: serverTimestamp(),
    userAgent: navigator.userAgent
  });
}

// Usage
await createTask(data);
await logAuditEvent('CREATE', 'tarea', taskId, { titulo });

await deleteTask(taskId);
await logAuditEvent('DELETE', 'tarea', taskId, {});
```

### GDPR Compliance

1. **Right to access**: Employees can download their data
   ```javascript
   async function downloadMyData(userId) {
     const data = {
       fichajes: await getMyFichajes(userId),
       tareas: await getMyTareas(userId),
       contactos: await getMyContactos(userId),
     };
     downloadJSON(data, `my-data-${new Date().toISOString()}.json`);
   }
   ```

2. **Right to erasure**: Implement soft deletes + scheduled hard deletes
   ```javascript
   // Soft delete (user can request)
   await updateDoc(doc(db, 'empleados', userId), {
     borradoEn: serverTimestamp()
   });
   
   // Cloud Function: hard delete after 30 days
   exports.hardDeleteExpiredUsers = functions.pubsub
     .schedule('every 24 hours')
     .onRun(async () => {
       const cutoff = new Date();
       cutoff.setDate(cutoff.getDate() - 30);
       
       const snapshot = await db.collection('empleados')
         .where('borradoEn', '<', cutoff)
         .get();
       
       snapshot.forEach(doc => doc.ref.delete());
     });
   ```

3. **Data retention policy**: Document what you keep and for how long
   - Fichajes: 4 years (labor law)
   - Tasks/comments: 2 years
   - Audit logs: 1 year
   - Deleted employee data: 30 days

---

## TESTING STRATEGY

### Unit Tests (with Vitest)

Test business logic in isolation:

`src/modules/fichaje/calculations.test.js`:
```javascript
import { describe, it, expect } from 'vitest';
import {
  calculateOvertime,
  calculateBreakRequirement,
  calculatePayroll
} from './calculations.js';

describe('Fichaje Calculations', () => {
  describe('Overtime', () => {
    it('returns 0 for 40h week', () => {
      expect(calculateOvertime([8, 8, 8, 8, 8])).toBe(0);
    });
    
    it('calculates 5h overtime for 45h week', () => {
      expect(calculateOvertime([9, 9, 9, 9, 9])).toBe(5);
    });
    
    it('caps at maximum 80h/month per Spanish law', () => {
      // 20 days × 8h + 80h = 240h (max 320h including rest)
      const hours = Array(20).fill(16); // 16h/day × 20 days
      expect(calculateOvertime(hours)).toBeLessThanOrEqual(80);
    });
  });
  
  describe('Break Requirements', () => {
    it('requires 15min break for 6h shift', () => {
      expect(calculateBreakRequirement(360)).toBe(15);
    });
    
    it('requires 30min break for 9h shift', () => {
      expect(calculateBreakRequirement(540)).toBe(30);
    });
  });
});
```

`src/modules/crm-comercial/pipeline.test.js`:
```javascript
import { describe, it, expect } from 'vitest';
import { calculateProbability, calculatePayoutAmount } from './pipeline.js';

describe('Sales Pipeline', () => {
  it('calculates probability based on stage', () => {
    expect(calculateProbability('Prospección')).toBe(10);
    expect(calculateProbability('Presupuesto')).toBe(50);
    expect(calculateProbability('Confirmado')).toBe(90);
  });
  
  it('calculates expected value (deal amount × probability)', () => {
    const deal = { valor: 10000, etapa: 'Presupuesto' };
    expect(calculatePayoutAmount(deal)).toBe(5000); // 10k × 50%
  });
});
```

### Integration Tests (with Vitest + MSW for API mocking)

Test multiple modules working together:

`src/modules/crm-comercial/visit-to-deal.test.js`:
```javascript
import { describe, it, expect, beforeAll, afterEach } from 'vitest';
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';
import { logVisit, createDealFromVisit } from './integration.js';

const mockGasServer = setupServer(
  http.post('*/exec', async ({ request }) => {
    const body = await request.json();
    
    if (body.action === 'visitasComerciales') {
      return HttpResponse.json({ id: 'visit-123' });
    }
    if (body.action === 'deals') {
      return HttpResponse.json({ id: 'deal-456' });
    }
  })
);

beforeAll(() => mockGasServer.listen());
afterEach(() => mockGasServer.resetHandlers());

describe('Visit to Deal Workflow', () => {
  it('logs visit and creates deal in one flow', async () => {
    const visitId = await logVisit({
      comercialId: 'juan-123',
      contactoId: 'cliente-456'
    });
    
    const dealId = await createDealFromVisit(visitId, {
      valor: 15000,
      titulo: 'Venta Distribuidor'
    });
    
    expect(visitId).toBeDefined();
    expect(dealId).toBeDefined();
  });
});
```

### E2E Tests (with Playwright)

Test complete user journeys:

`e2e/clock-in-complete-day.spec.js`:
```javascript
import { test, expect } from '@playwright/test';

test.describe('Complete Working Day', () => {
  test.beforeEach(async ({ page }) => {
    // Setup: create test employee
    await page.goto('http://localhost:5173');
    
    // Login
    await page.fill('input[type="email"]', 'juan@test.es');
    await page.fill('input[type="password"]', 'password123');
    await page.click('button:has-text("Entrar")');
    
    await page.waitForSelector('[data-testid="dashboard"]');
  });
  
  test('employee clocks in, takes break, clocks out', async ({ page, context }) => {
    // Grant geolocation + set position
    await context.grantPermissions(['geolocation']);
    await context.setGeolocation({ latitude: 40.4168, longitude: -3.7038 });
    
    // Clock in
    await page.click('[data-testid="btn-clock-in"]');
    await expect(page.locator('[data-testid="status"]')).toContainText('Trabajando desde');
    
    // Verify fichaje created
    const fichaje = await page.locator('[data-testid="current-fichaje"]');
    const horaEntrada = await fichaje.getAttribute('data-hora');
    expect(horaEntrada).toMatch(/\d{2}:\d{2}/);
    
    // Take break
    await page.click('[data-testid="btn-break"]');
    await expect(page.locator('[data-testid="status"]')).toContainText('Pausa');
    
    // End break
    await page.click('[data-testid="btn-end-break"]');
    await expect(page.locator('[data-testid="status"]')).toContainText('Trabajando');
    
    // Clock out
    await page.click('[data-testid="btn-clock-out"]');
    await expect(page.locator('[data-testid="status"]')).toContainText('No fichado');
    
    // Verify daily summary
    await page.click('[data-testid="tab-more"]');
    await page.click('[data-testid="link-activity"]');
    
    const summary = page.locator('[data-testid="daily-summary"]');
    await expect(summary).toContainText('8h 45m'); // Example total
    await expect(summary).toContainText('15min descanso');
  });
});
```

`e2e/sales-visit-to-order.spec.js`:
```javascript
import { test, expect } from '@playwright/test';

test('Commercial logs visit → creates deal → generates order', async ({ page, context }) => {
  // Login as commercial
  await page.goto('http://localhost:5173');
  await page.fill('input[type="email"]', 'maria@comercial.es');
  await page.fill('input[type="password"]', 'password123');
  await page.click('button:has-text("Entrar")');
  
  // Navigate to Tracker
  await page.click('[data-testid="tab-tracker"]');
  
  // Quick log visit
  await page.click('[data-testid="fab-create"]');
  await page.click('[data-testid="option-visit"]');
  
  await page.selectOption('select[name="tipo"]', 'presencial');
  await page.fill('input[name="contacto"]', 'Distribuidor XYZ');
  await page.fill('textarea[name="notas"]', 'Interesado en vinos tintos');
  await page.click('button:has-text("Registrar")');
  
  // Verify visit logged
  const toast = page.locator('[role="alert"]');
  await expect(toast).toContainText('Visita registrada');
  
  // Create deal from visit
  const visitCard = page.locator('[data-testid="visit-distribuidor-xyz"]');
  await visitCard.hover();
  await page.click('[data-testid="btn-create-deal"]');
  
  await page.fill('input[name="titulo"]', 'Venta Distribuidor XYZ');
  await page.fill('input[name="valor"]', '15000');
  await page.click('button:has-text("Crear Deal")');
  
  // Verify deal appears in pipeline
  await page.click('[data-testid="tab-tracker"]');
  const dealCard = page.locator('[data-testid="deal-venta-distribuidor"]');
  await expect(dealCard).toBeVisible();
  await expect(dealCard).toContainText('€15,000');
});
```

### Performance Tests

Track key metrics:

`e2e/performance.spec.js`:
```javascript
import { test, expect } from '@playwright/test';

test('Page load performance', async ({ page }) => {
  const metrics = await page.evaluate(() => {
    const nav = performance.getEntriesByType('navigation')[0];
    return {
      dns: nav.domainLookupEnd - nav.domainLookupStart,
      tcp: nav.connectEnd - nav.connectStart,
      ttfb: nav.responseStart - nav.requestStart,
      domInteractive: nav.domInteractive - nav.fetchStart,
      domComplete: nav.domComplete - nav.fetchStart,
      loadComplete: nav.loadEventEnd - nav.fetchStart
    };
  });
  
  // All metrics under 3s (4G)
  expect(metrics.loadComplete).toBeLessThan(3000);
});
```

### Test Coverage Goals

- **Unit**: 80%+ coverage of business logic
- **Integration**: All major workflows
- **E2E**: Critical user paths (clock-in, task creation, deal closure)
- **Performance**: Page load, interaction latency

Run locally:
```bash
npm run test:unit        # Vitest
npm run test:e2e         # Playwright
npm run test:coverage    # Coverage report
npm run test:watch       # Watch mode during development
```

---

## DEVELOPMENT ROADMAP

### Sprint 1 (Weeks 1–2): Fix Critical Bugs
- [ ] Configure backend URL + test Google Apps Script sync
- [ ] Fix CSS bug in Tracker tab
- [ ] Populate empty states with CTAs
- [ ] Implement basic PIN login (temporary, until Firebase Auth)
- [ ] Expand service worker caching to all assets
- **Deliverable**: App works with real data, minimal security

### Sprint 2 (Weeks 3–4): Phase 0 Modularization + Phase 1 Auth
- [ ] Split HTML into ES modules (Vite build setup)
- [ ] Implement Firebase Auth (email/password, PIN fallback)
- [ ] Add login/logout flows
- [ ] Create shell for Module 1 (Fichaje)
- **Deliverable**: Modular codebase, login required

### Sprint 3 (Weeks 5–7): Module 1 MVP (Fichaje Digital)
- [ ] Create Empleados + Ubicaciones tables in Sheets
- [ ] Implement clock-in/out with geolocation
- [ ] Add daily summary view
- [ ] QR code generation + scanning
- [ ] Basic reports (daily/weekly hours)
- [ ] Push notification reminders
- **Deliverable**: Time tracking functional, legal compliant

### Sprint 4 (Weeks 8–10): Phase 2 Migration (Firestore)
- [ ] Set up Firestore project
- [ ] Create data schemas in Firestore
- [ ] Build migration script (Google Sheets → Firestore)
- [ ] Implement Firestore SDK in API client
- [ ] Test end-to-end sync
- [ ] Sunset Google Apps Script (keep Calendar/Granola only)
- **Deliverable**: Real-time database, offline support

### Sprint 5 (Weeks 11–13): Module 2 Full Implementation (CRM Interno)
- [ ] Connect real employee list to task assignments
- [ ] Implement Kanban board with drag-drop
- [ ] Add comments + @mentions
- [ ] File upload support
- [ ] Announcements system
- [ ] Global search
- [ ] Real-time notifications
- **Deliverable**: Full team collaboration platform

### Sprint 6 (Weeks 14–16): Module 3 MVP (CRM Comercial)
- [ ] Create CODEBA + Events pipelines
- [ ] Visit logging with geolocation
- [ ] Deal management UI
- [ ] Sales KPI dashboards
- [ ] Weekly reports
- **Deliverable**: Sales team can track pipeline

### Sprint 7 (Weeks 17–19): Module 4 + Polish
- [ ] Help desk ticket system
- [ ] Job board
- [ ] Referral program + auto-bonus calculation
- [ ] Document portal
- [ ] Onboarding checklist
- [ ] Accessibility audit (WCAG AA)
- [ ] Bug fixes + performance optimization
- **Deliverable**: All modules complete, production-ready

### Sprint 8 (Weeks 20–21): Testing + Hardening
- [ ] Unit tests (80%+ coverage)
- [ ] E2E tests for critical flows
- [ ] Security audit
- [ ] Load testing (simulate 50–100 users)
- [ ] GDPR compliance review
- [ ] User documentation
- **Deliverable**: Production release

### Ongoing
- [ ] Monitoring + error tracking (Sentry)
- [ ] User feedback loops
- [ ] Feature requests backlog
- [ ] Monthly retrospectives

---

## APPENDIX: Key Contacts & Resources

- **Repository**: https://github.com/bosco-blanco/cosecha
- **Live App**: https://bosco-blanco.github.io/cosecha/ (GitHub Pages) → Firebase Hosting (post-Phase 2)
- **Firebase Console**: https://console.firebase.google.com
- **Google Apps Script**: https://script.google.com (keep for Calendar/Granola)
- **Design System**: Color palette + component library in this spec
- **Legal**: Real Decreto-ley 8/2019 (Spanish time tracking law)

---

**Document prepared for**: AI coding assistants, Bosco (product owner), development team

**Last updated**: 2026-04-12  
**Next review**: After Sprint 3 (post-Fichaje MVP)
