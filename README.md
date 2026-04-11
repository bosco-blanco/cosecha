# 🍇 Cosecha

**CRM y gestión para En Copa de Balón**

Progressive Web App con backend en Google Apps Script y base de datos en Google Sheets. Pensada para funcionar sobre Google Workspace Business Starter sin coste adicional.

---

## 🌐 Entornos

| Entorno | URL | Notas |
|---|---|---|
| **App (frontend)** | Pendiente de activar GitHub Pages | PWA instalable en móvil y escritorio |
| **Backend (Apps Script)** | [Web App](https://script.google.com/macros/s/AKfycbwgkECbvdFVNGSzFhIBKtlY3lmvyDj5F2gmDR3AWNw6QCcCxBxSEfFhy23I61ZDebXe/exec) | Protegido por token de sesión, solo responde a peticiones autenticadas |

La URL del backend es segura de exponer: todos los endpoints sensibles requieren un token de sesión válido, que solo se obtiene tras verificar un código de 6 dígitos enviado a un email del dominio corporativo `@encopadebalon.com`.

### Configuración actual del backend

| Campo | Valor |
|---|---|
| **Deployment ID** | `AKfycbwgkECbvdFVNGSzFhIBKtlY3lmvyDj5F2gmDR3AWNw6QCcCxBxSEfFhy23I61ZDebXe` |
| **Runtime** | Google Apps Script V8 |
| **Timezone** | Europe/Madrid |
| **Ejecutar como** | `bosco@encopadebalon.com` |
| **Quién tiene acceso** | Cualquier usuario (anónimo) |
| **Dominio permitido para login** | `@encopadebalon.com` |

---

## 📦 Funcionalidades

### Para todos los roles
- 🔐 **Login passwordless** — código de 6 dígitos por email, sin contraseñas
- ⏱️ **Check-in / Fichajes** — entrada y salida con GPS, historial diario
- 🏠 **Dashboard** — KPIs en vivo del pipeline, tareas y reuniones
- 🎙️ **Reuniones** — grabación con transcripción en vivo, resumen automático
- 📋 **Tareas** — tablero Kanban con prioridades, asignaciones y subtareas
- 📣 **Actividad** — feed en tiempo real de todo lo que pasa en la empresa

### Para comerciales
- 👥 **Contactos** — CRM con clientes, proveedores, partners, leads
- 💰 **Pipeline** — oportunidades kanban con valor ponderado
- 📍 **Reuniones geolocalizadas** (próximamente) — captura ubicación y crea ficha de cliente automáticamente

### Para admin
- 👑 **Panel admin** — gestión de usuarios y roles del equipo
- 📊 **Visión global** — fichajes de todos, actividad completa
- ⚙️ **Configuración** — webhooks Slack, dominio corporativo, etc.

### Integraciones
- 📧 **Gmail** — emails de código de acceso y notificaciones
- 📁 **Google Drive** — almacenamiento automático de transcripciones de reuniones
- 📅 **Google Calendar** — sincronización de reuniones como eventos
- 💬 **Slack** — notificaciones vía incoming webhook
- 🗺️ **OpenStreetMap Nominatim** — reverse geocoding para check-ins (gratis, sin API key)

---

## 🏗️ Arquitectura

```
┌─────────────────┐        ┌──────────────────────┐        ┌───────────────┐
│   PWA Frontend  │ ─────▶ │  Apps Script Web App │ ─────▶ │ Google Sheets │
│   (index.html)  │        │    (apps-script/)    │        │ (auto-creada) │
└─────────────────┘        └──────────────────────┘        └───────────────┘
       │                            │
       │                            ├──▶ GmailApp (envío de códigos)
       │                            ├──▶ Google Drive (transcripciones)
       │                            ├──▶ Google Calendar (eventos)
       │                            └──▶ Slack webhook (notificaciones)
       │
       └──▶ LocalStorage (offline-first, persistencia local)
```

**Sin servidor propio. Sin dependencias de pago. Sin base de datos externa.**

---

## 📁 Estructura del repo

```
cosecha/
├── index.html                # PWA completa (HTML + CSS + JS en un solo archivo)
├── manifest.json             # PWA manifest
├── sw.js                     # Service worker (offline-first)
├── icon-192.png              # Icono PWA
├── icon-512.png              # Icono PWA
│
├── apps-script/              # Backend Google Apps Script
│   ├── appsscript.json       # Manifest (scopes, timezone, runtime)
│   ├── Code.gs               # Router API REST (doGet/doPost)
│   ├── Auth.gs               # Login passwordless + tokens de sesión
│   ├── Checkin.gs            # Fichajes, usuarios, roles, panel admin
│   ├── Database.gs           # CRUD sobre Google Sheets (auto-creación)
│   ├── Calendar.gs           # Integración Google Calendar
│   ├── Slack.gs              # Webhook Slack con Block Kit
│   └── Granola.gs            # Importar notas de Granola
│
├── .github/workflows/
│   └── deploy-apps-script.yml  # Despliegue automático en cada push
│
├── package.json              # Scripts npm para clasp (push, deploy, logs)
├── .clasp.json.example       # Template de config clasp (gitignored real)
├── .gitignore                # node_modules, credenciales clasp
│
├── README.md                 # Este archivo
├── SETUP.md                  # Guía de despliegue inicial (manual)
└── DEPLOY.md                 # Guía de despliegue automático (clasp + Actions)
```

---

## 🚀 Empezar

### Ya desplegado (uso)

1. Abre la app desde GitHub Pages (URL pendiente) o clona el repo y abre `index.html` localmente
2. Inicia sesión con tu email `@encopadebalon.com`
3. Introduce el código de 6 dígitos que te llega por email
4. ¡Dentro!

### Desarrollo local

```bash
# Clonar y servir el frontend
git clone https://github.com/bosco-blanco/cosecha.git
cd cosecha
python3 -m http.server 8000
# Abrir http://localhost:8000

# Para desplegar cambios al backend (una vez configurado clasp)
npm run deploy
```

Ver [DEPLOY.md](./DEPLOY.md) para el setup de clasp (despliegue sin copiar-pegar).

### Despliegue desde cero

1. [SETUP.md](./SETUP.md) — guía paso a paso del despliegue inicial del backend (10 minutos)
2. [DEPLOY.md](./DEPLOY.md) — automatización con clasp + GitHub Actions (para que cada commit despliegue solo)

---

## 👥 Roles del equipo

| Rol | Experiencia | Módulos con foco |
|---|---|---|
| 👑 **admin** | Ve todo, gestiona usuarios | Panel admin, KPIs globales, fichajes del equipo |
| 💼 **comercial** | CRM al uso | Contactos, pipeline, reuniones con clientes |
| 👥 **equipo** | Gestión de proyectos | Tableros, tareas, reuniones internas |

Los roles se editan desde el panel admin de la app, o directamente en la pestaña **Usuarios** del Google Sheet.

---

## 💰 Coste

**0 €.** Todo corre sobre Google Workspace Business Starter (ya pagado) + servicios gratuitos:

- Google Apps Script · gratis
- Google Sheets como DB · gratis
- Google Drive / Gmail / Calendar · incluido en Workspace
- Slack Incoming Webhooks · gratis (plan free)
- OpenStreetMap Nominatim (geocoding) · gratis
- GitHub Pages (hosting frontend) · gratis
- GitHub Actions (CI/CD) · gratis (hasta 2000 min/mes)

---

## 📄 Licencia

Proyecto privado de En Copa de Balón.

---

🍇 *Cosecha — La gestión de tu empresa, como una buena vendimia: todo en su tiempo y sin desperdicio.*
