# Avance del proyecto — resumen hasta ahora

**Fecha:** 2026-07-16  
**Rama actual:** `Sprint-4/1-comunicacion`  
**Último commit relevante:** `0c3cac8` — Sprint 4: push FCM, Mis OT móvil y bots de smoke  
**Cierre óptimo (local):** deep-link OT, URL API runtime, adb reverse, docs M7, gitignore APK, CI build API

Documento de cierre parcial: **qué se hizo** vs **qué falta** (sección aparte).

---

## Qué se hizo

### Fundación

- Monorepo: NestJS (`apps/api`) + Flutter (`apps/client`) + Docker (PostgreSQL, Redis, MinIO).
- Auth JWT + refresh + guards por derecho.
- Seed demo Planta Virrey: `admin` / `supervisor` / `tecnico` / `panolero` (clave `Sika123!`).
- Documentación funcional (`docs/01`–`10`), manual SGMWin, checklist paridad SGwing.

### M1 — Seguridad (~92%)

- Login / logout / sesión persistida.
- CRUD usuarios, perfiles, sucursales.
- Editor de derechos Total/Parcial.
- Perfil: cambio de clave, sesiones, revocar todas.
- RLS PostgreSQL por sucursal.
- Tests e2e auth.

### M2 — Planta (~90–95%)

- Mapa planta → sector → equipo.
- Toolbar: agregar, modificar, eliminar, listar, copiar, pegar, mover, fuera de servicio.
- Historial OT / procedimientos por equipo.
- Documentos de equipo (storage MinIO).
- Lecturas / contadores por equipo.
- Impresión HTML / CSV (`PlantaPrint`).
- Procedimientos asociados filtrados por planta/sector/equipo.

### M3 — Mantenimiento (~90–95% web)

- Ciclo de vida OT: emitir, asignar, ejecutar, checklist, firma, anular, reabrir, derivar.
- OT necesarias (tiempo + contador) + emisión en lote + cron diario.
- Motivos de pendiente (catálogo + asignación).
- Solicitudes de trabajo + conformidad + emitir OT.
- PDF / HTML imprimible de OT.
- Filtros avanzados OT, colores de estado, mapa contextual.
- Contadores con gráfico + reinicio con clave admin.

### Sprint 1 — Procedimientos

- Filtros avanzados (tipo, sector, periodicidad, tipo equipo, texto).
- Toolbar + export CSV.
- Asociar a planta / sector / equipo + emitir primera OT + imprimir.

### Sprint 2 — Planta / equipos (PR #6)

- Toolbar y acciones de sector/equipo.
- Impresión / listados.
- Documentos con URL de apertura.
- Pulido de UX en ficha y mapa.

### Sprint 3 — OT profundidad (PR #7)

- Filtros OT, GUT estimada, export CSV, vista previa / imprimir (`OtPrint`).
- OT no periódica: fechas inicio/límite, recibe.
- Contadores: reinicio con clave admin.
- Fix firma PDF (stroke negro sobre transparente para impresión).

### Sprint 4 — Comunicación / FCM (en curso)

#### API

- `PushService` centraliza FCM (API modular firebase-admin v14: `cert` + `getMessaging`).
- Push al asignar / emitir OT.
- Emisión en lote: **una notificación resumen por técnico**.
- Prune de tokens FCM inválidos.
- Arranque: log `FCM listo (credenciales cargadas)` con `FIREBASE_*` en `.env`.

#### Flutter Android

- `FcmService` + bootstrap: registro de token, refresh, logout borra token.
- Handlers foreground / background / tap → `/mis-ot`.
- SnackBar en foreground con acción “Ver”.
- Permiso `POST_NOTIFICATIONS` + canal `ot_asignadas`.
- `minSdk 23`, NDK 27, `usesCleartextTraffic` para HTTP local.

#### Mis OT (móvil)

- Rango de fechas amplio (~1 año / +60 días).
- Pull-to-refresh + botón actualizar.
- Empty state orientado al técnico.

#### Tooling / calidad

- Smoke bot API: `scripts/smoke-bot.mjs` (`npm run smoke`).
- Playwright UI smoke: `scripts/playwright/` (login vía tokens SharedPreferences).
- Semantics habilitadas en web para pruebas.

#### Build APK de prueba

- APK release generada localmente (no versionar): `apps/client/gestion-mantenimiento.apk`.
- Firebase client: proyecto `mantenimiento-app-75a63`.
- Firebase server: service account en `.env` / `apps/api/.env` (no commitear).
- **URL API editable** en Perfil (Android) sin regenerar APK.
- Script USB: `scripts/android-adb-reverse.ps1` → `http://127.0.0.1:3000/v1`.
- Deep-link: tap / “Ver” → `/mis-ot?numero=N` y selección de la OT.

---

## Cómo probar lo hecho (referencia rápida)

| Qué | Cómo |
|-----|------|
| API | `npm run start:dev` en `apps/api` → debe loguear `FCM listo` |
| Web | `flutter run -d chrome --web-port=8080` |
| Smoke API | `npm run smoke` (desde API) |
| Playwright | ver `scripts/playwright/README.md` |
| Push FCM | Solo Android real (web no registra token) |
| APK / USB | Instalar APK → Perfil → URL `http://127.0.0.1:3000/v1` + `android-adb-reverse.ps1` |

Usuarios demo: `admin` / `supervisor` / `tecnico` — clave `Sika123!`.

---

## Qué falta

### Sprint 4 / FCM (pendiente de validar en dispositivo)

| Ítem | Estado |
|------|--------|
| Deep-link a OT desde notificación | ✅ `/mis-ot?numero=` |
| URL API sin rebuild | ✅ Perfil → Servidor API |
| Script adb reverse + docs conectividad | ✅ |
| `*.apk` en gitignore | ✅ |
| Docs M7 actualizadas | ✅ |
| CI build API | ✅ workflow |
| Probar push end-to-end en Android | ⏳ pendiente dispositivo |
| Rotar service account Firebase | ⏳ manual (si la key se filtró) |
| Notificación local más rica (canal nativo foreground) | Diferido (SnackBar OK) |

### Paridad SGwing / producto (no Sprint 4)

| Ítem | Prioridad | Módulo |
|------|-----------|--------|
| Gantt de programación OT | P2 | M3 / M6 |
| Versiones / histórico de procedimiento | P3 | M3 |
| Solicitudes: pulir listado / acciones | P2 | M3 |
| Reserva de materiales en procedimiento | P1 | **M4 Pañol** |
| Mano de obra y materiales en OT | — | **M4** |
| Repuestos por equipo | P2 | **M4** |
| Módulo Pañol completo | — | **M4** (0%) |
| Módulo Compras | — | **M5** (0%) |
| Indicadores / reportes avanzados | — | **M6** (~5%, solo resumen home) |
| Offline + sync móvil | — | Fase 3 |
| Columnas GUT/HH real en schema (migración) | P2 | M3 |
| Ampliar árbol de derechos 1:1 SGMWin | — | M1 |
| Recuperación de clave | Opcional | M1 |
| CI Playwright UI | — | Tooling (diferido; lento) |

### Infra / ops

| Ítem | Notas |
|------|--------|
| Node ≥ 22 (aviso AWS SDK) | Hoy Node 20; warning no bloqueante |
| Smoke E2E en CI con Docker | Diferido; CI hoy hace `nest build` |

---

## Referencias

- [`00-estado-proyecto.md`](../00-estado-proyecto.md)
- [`sprint-4-fcm.md`](sprint-4-fcm.md)
- [`m3-mantenimiento.md`](m3-mantenimiento.md)
- [`sgwing-paridad.md`](sgwing-paridad.md)
- [`m2-planta.md`](m2-planta.md)
- [`m1-seguridad.md`](m1-seguridad.md)
