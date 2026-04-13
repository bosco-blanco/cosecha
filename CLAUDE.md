# Cosecha — Guía del Proyecto

## Qué es
App interna de **En Copa de Balón (ECDB)** para ~100 empleados en 15+ locales (tiendas, restaurantes, noche, distribución). Flutter + Supabase.

## Stack
- **Frontend**: Flutter (Dart) — iOS + Android + Web
- **Backend**: Supabase (`kvwufrjagqkhrmteldhp`) — PostgreSQL + Auth + RLS + Realtime
- **State**: Riverpod 2
- **Routing**: GoRouter
- **Branch activo**: `claude/cosecha-flutter-app-9GY0n`

## Arrancar en local
```bash
cd ~/Desktop/cosecha-app
git checkout claude/cosecha-flutter-app-9GY0n
echo 'SUPABASE_URL=https://kvwufrjagqkhrmteldhp.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt2d3VmcmphZ3FraHJtdGVsZGhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwMjcwMzMsImV4cCI6MjA5MTYwMzAzM30.4uph3p5ILXS5JUejTfMFu_Q8vL9f-NXMH7TMBfRMHKk' > .env
flutter pub get
flutter run -d chrome
```

## PINs de prueba
| PIN | Nombre | Rol |
|-----|--------|-----|
| 0000 | Bosco Blanco | admin |
| 1111 | Carlos Ruiz | manager |
| 2222 | María López | empleado |
| 3333 | Pablo Fernández | comercial |
| 4444 | Laura Martín | empleado |

## Arquitectura
```
lib/
├── main.dart                    # Entry point
├── app.dart                     # GoRouter + MaterialApp + BottomNav
├── core/
│   ├── theme/                   # Colores burdeos/oro, tipografía ECDB
│   ├── constants/               # 15 ubicaciones ECDB + config
│   ├── models/                  # 11 modelos Dart (empleado, fichaje, tarea, deal...)
│   ├── providers/               # Riverpod: auth, fichaje, tareas, crm, portal
│   ├── services/                # Supabase, geolocalización, QR, offline sync
│   └── utils/                   # Geo (Haversine), fechas ES, CSV, validadores
├── features/
│   ├── auth/                    # Login PIN + email
│   ├── dashboard/               # Home: clock widget + KPIs + empleados activos
│   ├── fichaje/                 # Historial, control horario, kiosk QR, detalle
│   ├── tareas/                  # Kanban drag&drop + crear + detalle + comentarios
│   ├── crm/                     # Pipeline CODEBA/Eventos + contactos
│   ├── agenda/                  # Placeholder
│   ├── portal/                  # Solicitudes, ofertas empleo, referidos (200€)
│   └── admin/                   # Gestión empleados (PINs), QR generator
├── shared/widgets/              # AppBar, BottomNav, Card, Button, EmptyState, Loading, Toast
supabase/migrations/             # 11 SQL files con tablas + RLS + RPC
```

## Qué está construido (funcionando)
- **Auth**: Login por PIN (4 dígitos) via RPC `validate_pin()`
- **Fichaje**: Entrada/salida con geolocalización, timer en vivo, historial con calendario
- **Kiosk**: QR en cada local → empleado escanea → PIN → fichaje (sin app instalada)
- **Tareas**: Kanban con 4 columnas, drag&drop, crear, detalle con comentarios
- **CRM**: Pipeline CODEBA (6 etapas) + Eventos (7 etapas), contactos, deals
- **Portal**: Solicitudes (IT/RRHH/Mant), bolsa empleo, referidos con bonificación
- **Admin**: Crear empleados con PIN auto-generado, generar QR por ubicación
- **Tema**: Identidad visual ECDB (burdeos + oro + Cormorant Garamond + Inter)

## Qué falta por construir
- [ ] Agenda: Calendario con reuniones (integrar Google Calendar API)
- [ ] Anuncios: Feed de noticias/comunicados de managers (tabla existe, falta UI en dashboard)
- [ ] Visitas comerciales: Registro con geolocalización + quick-log
- [ ] Documentos: Nóminas, contratos (Supabase Storage)
- [ ] Búsqueda global: Buscar en tareas, contactos, anuncios
- [ ] Notificaciones push: Firebase Cloud Messaging
- [ ] Offline completo: Drift (SQLite) sync para todos los módulos
- [ ] Onboarding: Checklist para nuevos empleados
- [ ] Supabase Auth real: Migrar de PIN-only a Supabase Auth para producción
- [ ] Tests: Widget tests, integration tests
- [ ] Build nativo: iOS (TestFlight) + Android (Play Console)

## Documentación de referencia
- `COSECHA_SPEC.md` — Especificación técnica completa (modelos, módulos, UI, seguridad)
- `docs/Cosecha_Auditoria_Producto_Abril2026.pdf` — Auditoría del estado anterior (PWA)

## Base de datos (Supabase)
- 15+ tablas: empleados, ubicaciones, fichajes, descansos, tareas, proyectos, comentarios, anuncios, archivos, contactos, deals, visitas_comerciales, pedidos, solicitudes, ofertas_empleo, referidos, documentos
- RLS habilitado en todas las tablas
- Modo dev: políticas `anon` permisivas (producción necesita Supabase Auth + RLS estricto)
- RPC: `validate_pin(pin_code TEXT)` — valida PIN y devuelve empleado
- Realtime habilitado en fichajes

## Reglas importantes
- **No inventar ubicaciones** — solo las 15 de la lista canónica
- **Fichajes inmutables** — empleados no pueden editar/borrar
- **Español en UI** — código en inglés, textos visibles en español
- **Mobile-first** — botones grandes, gestos naturales
- **Retención legal** — 4 años para fichajes (RD-ley 8/2019)
- **No hardcodear secrets** — usar .env (está en .gitignore)
