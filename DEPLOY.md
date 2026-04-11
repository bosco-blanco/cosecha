# 🚀 Despliegue automático de Apps Script

Esta guía te ahorra tener que copiar-pegar archivos a Apps Script cada vez que cambia algo. Hay dos opciones, puedes montar las dos o solo la que te guste.

---

## 🎯 Opción 1 — Automático en cada push (recomendado)

**Cómo funciona**: cada vez que hay un commit en el repo que toque `apps-script/`, GitHub Actions despliega el código a Apps Script automáticamente. Tú solo trabajas con git.

### Prerequisitos

- Haber creado ya el proyecto de Apps Script (aunque sea vacío, con `clasp create` o manualmente)
- Tener el **Script ID** a mano (está en la URL de tu proyecto: `https://script.google.com/d/SCRIPT_ID/edit`)

### Setup (10 minutos, una sola vez)

#### 1️⃣ Instalar clasp en tu Mac

```bash
npm install -g @google/clasp
```

> Si no tienes `node`/`npm`: instala Node.js desde https://nodejs.org (versión LTS).

#### 2️⃣ Habilitar la API de Apps Script

Ve a https://script.google.com/home/usersettings y activa **"API de Google Apps Script"**. Si no lo haces, clasp dará error.

#### 3️⃣ Hacer login con tu cuenta

```bash
clasp login
```

Se abre el navegador → inicias sesión con **bosco@encopadebalon.com** → "Permitir". Esto genera un archivo `~/.clasprc.json` con tus credenciales.

#### 4️⃣ Conectar el repo a tu proyecto Apps Script

En la carpeta del repo:

```bash
# Si ya tienes un proyecto creado (normal):
clasp clone TU_SCRIPT_ID --rootDir apps-script

# O si quieres que cree uno nuevo desde cero:
clasp create --type standalone --title "Cosecha Backend" --rootDir apps-script
```

Esto crea un archivo `.clasp.json` en la raíz del repo con el `scriptId`. **No lo subas** (ya está en `.gitignore`).

#### 5️⃣ Probar que funciona (desde local)

```bash
npm run push
```

Deberías ver los 7 archivos subiéndose. Si todo va bien, abre https://script.google.com y verás el código actualizado.

#### 6️⃣ Configurar GitHub Actions (para que sea automático)

Ve a tu repo en GitHub → **Settings** → **Secrets and variables** → **Actions** → botón **"New repository secret"** y añade estos dos secrets:

**Secret 1: `CLASPRC`**
- Nombre: `CLASPRC`
- Valor: el contenido completo del archivo `~/.clasprc.json` de tu Mac
- Para verlo en terminal: `cat ~/.clasprc.json` → copia todo → pégalo en el campo valor

**Secret 2: `CLASP_JSON`**
- Nombre: `CLASP_JSON`
- Valor: el contenido del archivo `.clasp.json` de la raíz del repo
- Para verlo: `cat .clasp.json` → copia todo → pégalo

#### 7️⃣ Listo

A partir de ahora, **cada commit al repo** que toque la carpeta `apps-script/` se despliega automáticamente. Lo puedes ver en la pestaña **"Actions"** de GitHub.

---

## 🎯 Opción 2 — Manual desde tu terminal

Si prefieres desplegar tú a mano cuando te dé la gana (útil para probar cambios puntuales):

```bash
# Despliega el código sin crear versión nueva
npm run push

# Despliega y crea una versión nueva (recomendado)
npm run deploy

# Descarga los cambios si editaste algo directamente en Apps Script
npm run pull

# Abre el proyecto en el navegador
npm run open

# Ver logs en tiempo real
npm run logs
```

El paso `npm run deploy` también crea una nueva **versión** del Apps Script, lo que significa que la URL del web app sirve inmediatamente el código nuevo (sin tener que redesplegar manualmente).

---

## 🤝 Flujo día a día cuando ya está montado

Con el setup completo, el flujo queda así:

1. Yo (o tú) hacemos cambios al código del backend (`apps-script/*.gs`)
2. `git commit` + `git push`
3. GitHub Actions se dispara automáticamente
4. En ~1 minuto el backend está actualizado
5. Refrescas la app y los cambios están live

**Cero copiar-pegar. Cero entrar a script.google.com.**

---

## ❓ Problemas frecuentes

**`clasp login` no abre el navegador**
Ejecuta con `--no-localhost`: `clasp login --no-localhost`. Te dará una URL que abres manualmente.

**`User has not enabled the Apps Script API`**
Te falta activarla en https://script.google.com/home/usersettings

**`ScriptError: Cannot read scriptId`**
El `.clasp.json` no está bien. Ejecuta `clasp clone TU_SCRIPT_ID --rootDir apps-script` otra vez.

**La GitHub Action falla con "missing CLASPRC"**
Los secrets no están puestos o están mal nombrados. Revisa Settings → Secrets → Actions.

**Los cambios no se reflejan en la URL del web app**
Apps Script tiene "Versiones" vs "Nuevas implementaciones". El flag `--force` de `clasp push` solo actualiza el código; `clasp deploy` crea una versión desplegada. Para que la URL sirva lo último: `npm run deploy` (en vez de `npm run push`).

---

## 🔐 Seguridad

- El secret `CLASPRC` da acceso a tu Apps Script. **No lo compartas ni lo commitees jamás.**
- Los archivos `.clasprc.json` y `.clasp.json` ya están en `.gitignore`.
- Si expones accidentalmente el token: `clasp logout` → `clasp login` de nuevo genera uno nuevo.
