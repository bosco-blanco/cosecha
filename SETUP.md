# 🍇 Cosecha — Guía de despliegue

Guía paso a paso para dejar Cosecha funcionando con tu propia cuenta de Google Workspace. **Tiempo estimado: 10 minutos**. **Coste: 0 €**.

> 💡 **¿No quieres copiar-pegar cada cambio?** Si ya tienes un despliegue inicial funcionando, lee [DEPLOY.md](./DEPLOY.md) para automatizarlo con `clasp` + GitHub Actions. A partir de ese momento, cada commit al repo se sincroniza solo con Apps Script.

---

## Parte 1 — El backend (Google Apps Script)

Esto es lo que hace que la app deje el modo demo y empiece a enviar emails reales, guardar datos en Google Sheets, crear eventos en Calendar, etc.

### Paso 1.1 — Abre Apps Script

1. Ve a 👉 **[script.google.com](https://script.google.com)** con tu cuenta **bosco@encopadebalon.com** (importante que sea esta, no una personal).
2. Arriba a la izquierda pulsa **"+ Nuevo proyecto"**.
3. Cambia el nombre del proyecto (arriba, donde pone "Proyecto sin título") a **"Cosecha Backend"**.

### Paso 1.2 — Pega los archivos

Cosecha tiene 7 archivos de código que hay que crear en tu proyecto Apps Script.

**A. El archivo principal**

Verás que ya hay un archivo `Code.gs` creado automáticamente.

1. Abre el archivo `apps-script/Code.gs` de este repo, copia TODO su contenido.
2. Pégalo en el editor de Apps Script sobreescribiendo lo que haya.
3. Guarda con **Ctrl/Cmd+S**.

**B. Los demás archivos**

Para cada uno de estos archivos, en el panel izquierdo haz clic en el **+** junto a "Archivos" → **Script**, escribe el nombre exacto (sin `.gs`), pega el contenido y guarda:

| Nombre del archivo | Fichero del repo | Qué hace |
|---|---|---|
| `Auth`     | `apps-script/Auth.gs`     | Login passwordless por email |
| `Checkin`  | `apps-script/Checkin.gs`  | Fichajes + usuarios + roles |
| `Database` | `apps-script/Database.gs` | CRUD sobre Google Sheets |
| `Calendar` | `apps-script/Calendar.gs` | Integración con Google Calendar |
| `Slack`    | `apps-script/Slack.gs`    | Notificaciones a Slack |
| `Granola`  | `apps-script/Granola.gs`  | Importar notas de Granola |

**C. El manifiesto**

1. Arriba a la izquierda pulsa el icono del engranaje ⚙️ ("Configuración del proyecto").
2. Marca la casilla **"Mostrar el archivo de manifiesto 'appsscript.json' en el editor"**.
3. Vuelve a "Editor" (icono `<>`).
4. Ahora verás el archivo `appsscript.json` en la lista de archivos. Ábrelo.
5. Copia el contenido de `apps-script/appsscript.json` del repo, sobreescribe el que hay, y guarda.

### Paso 1.3 — Autoriza y despliega

1. Pulsa **"Desplegar"** (arriba a la derecha) → **"Nueva implementación"**.
2. En el icono del engranaje de "Seleccionar tipo", elige **"Aplicación web"**.
3. Rellena así:
   - **Descripción**: `Cosecha v1`
   - **Ejecutar como**: `Yo (bosco@encopadebalon.com)`
   - **Quién tiene acceso**: `Cualquier usuario`
4. Pulsa **"Implementar"**.
5. La primera vez te pedirá autorizar los permisos (Gmail, Sheets, Drive, Calendar). Pulsa **"Autorizar acceso"** → elige tu cuenta → "Configuración avanzada" → "Ir a Cosecha Backend (no seguro)" → "Permitir". Esto es normal, tu propio proyecto no está verificado por Google pero es tuyo.
6. Cuando termine, copia la **URL de la aplicación web** (empieza por `https://script.google.com/macros/s/.../exec`).

**⚠️ Importante**: guarda esta URL. La vas a pegar en la app en el paso 2.

---

## Parte 2 — Conectar la app al backend

1. Abre Cosecha (GitHub Pages o el archivo local).
2. Toca el icono **⚙️** arriba a la derecha → "Configuración".
3. En el campo **"🔗 URL Backend (Apps Script)"** pega la URL que copiaste.
4. Pulsa **"💾 Guardar configuración"**.
5. Pulsa **"🔄 Probar conexión"** — debería mostrar ✅ Backend OK.
6. Haz logout (icono de tu perfil → Cerrar sesión).
7. Vuelve a iniciar sesión con tu email real. **Recibirás un email real con el código** 🎉

A partir de ahora el modo demo desaparece y todo funciona contra tu Google Sheet real.

---

## Parte 3 — Slack (opcional)

Si quieres recibir notificaciones en Slack cuando se completen tareas, se creen reuniones, etc.

### Paso 3.1 — Crear Incoming Webhook

1. Ve a 👉 **[api.slack.com/apps](https://api.slack.com/apps)**.
2. **"Create New App"** → **"From scratch"**.
3. Nombre: `Cosecha`, workspace: el tuyo.
4. En el menú izquierdo → **"Incoming Webhooks"** → activa **"Activate Incoming Webhooks"**.
5. Abajo pulsa **"Add New Webhook to Workspace"** → elige el canal `#cosecha-crm` (o el que quieras).
6. Copia la URL del webhook (empieza por `https://hooks.slack.com/services/...`).

### Paso 3.2 — Guardar en Cosecha

Dos opciones:

**Opción A — Desde la app** (recomendado):
1. ⚙️ → Configuración → campo "💬 Webhook Slack" → pega la URL → Guardar.

**Opción B — Directamente en el Sheet**:
1. Abre tu Google Sheet "Cosecha CRM" (se creó automáticamente al desplegar el Apps Script).
2. Ve a la pestaña **Config**.
3. Añade una fila: `SLACK_WEBHOOK_URL` | `https://hooks.slack.com/services/...`.

---

## Parte 4 — Configuración avanzada

### Cambiar el dominio corporativo

Por defecto solo se aceptan emails `@encopadebalon.com`. Si necesitas cambiarlo:

1. Abre tu Google Sheet "Cosecha CRM" → pestaña **Config**.
2. Añade la fila: `AUTH_DOMAIN` | `tudominio.com` (sin `@`).

### Gestionar roles

1. Los roles se editan desde el panel admin dentro de la app (chip de usuario → 👑 Panel admin).
2. También puedes editarlos directamente en la pestaña **Usuarios** del Sheet, columna `rol`:
   - `admin` — ve todo, gestiona usuarios
   - `comercial` — foco CRM, reuniones con clientes, pipeline
   - `equipo` — foco gestión de proyectos, tareas, tableros

### Limpieza automática de sesiones expiradas

1. En Apps Script → menú izquierdo → icono del reloj ⏰ "Activadores".
2. **"+ Añadir activador"**:
   - Función: `cleanupAuth`
   - Evento: `Basado en tiempo` → `Cada día` → hora que prefieras
3. Guardar.

---

## Problemas frecuentes

**"No se pudo contactar el backend"**
- ¿La URL termina en `/exec`?
- ¿Has redesplegado tras modificar el código? (Cada cambio requiere "Desplegar" → "Gestionar implementaciones" → lápiz → "Nueva versión")

**"Only emails @encopadebalon.com"**
- Revisa el valor de `AUTH_DOMAIN` en la pestaña Config del Sheet.

**No llega el email**
- Mira la carpeta de Spam.
- En Apps Script → menú "Ejecuciones" → comprueba que `sendAuthEmail_` no tenga errores.
- Revisa la cuota diaria de Gmail (1.500 emails/día en Workspace Business Starter — sobra).

**Error de CORS al hacer POST desde la app**
- Apps Script web apps con `Quién tiene acceso = Cualquier usuario` funcionan con `mode: no-cors`. La app ya lo hace así. Si aun así falla, comprueba que desplegaste como "Aplicación web" y no como "API ejecutable".

---

## Qué crea automáticamente el backend

La primera vez que el backend reciba una petición, creará automáticamente una hoja de cálculo llamada **"Cosecha CRM"** en tu Drive con estas pestañas:

- **Usuarios** — miembros del equipo con roles
- **Fichajes** — entradas/salidas diarias con GPS
- **Contactos** — clientes/proveedores/partners/leads
- **Deals** — oportunidades del pipeline
- **Tareas** — tablero Kanban
- **Reuniones** — transcripciones + metadata
- **Actividad** — log de todo lo que pasa
- **Auth** — códigos y sesiones (se auto-limpia)
- **Config** — pares clave/valor (webhook Slack, dominio, etc.)

Todo en tu Drive, todo tuyo, todo gratis.

---

¿Te has atascado en algún paso? Abre un issue en el repo o dímelo y lo clarifico.
