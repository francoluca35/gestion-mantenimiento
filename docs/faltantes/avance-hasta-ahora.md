# Avance del proyecto — resumen hasta ahora

**Fecha:** 2026-07-17  
**Rama actual:** `Sprint-4/1-comunicacion`  
**Estado Sprint 4:** ✅ **CERRADO**  
**Último commit de cierre:** ver historial de la rama (FCM + Mis OT + shell móvil)

Documento de cierre: **qué se hizo** vs **qué queda fuera de Sprint 4**.

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

### M3 — Mantenimiento (~92%)

- Ciclo de vida OT: emitir, asignar, ejecutar, checklist, firma, anular, reabrir, derivar.
- OT necesarias (tiempo + contador) + emisión en lote + cron diario.
- Motivos de pendiente (catálogo + asignación).
- Solicitudes de trabajo + conformidad + emitir OT.
- PDF / HTML imprimible de OT.
- Filtros avanzados OT, colores de estado, mapa contextual.
- Contadores con gráfico + reinicio con clave admin.

### Sprint 1 — Procedimientos ✅

- Filtros avanzados, toolbar + export CSV, asociar + emitir primera OT.

### Sprint 2 — Planta / equipos ✅ (PR #6)

- Toolbar sector/equipo, impresión, documentos, UX ficha/mapa.

### Sprint 3 — OT profundidad ✅ (PR #7)

- Filtros OT, GUT, export CSV, OtPrint, OT no periódica, contadores, fix firma PDF.

### Sprint 4 — Comunicación / FCM ✅ CERRADO (2026-07-17)

Detalle: [`sprint-4-fcm.md`](sprint-4-fcm.md)

#### API
- `PushService` FCM (firebase-admin v14).
- Push al asignar / emitir; lote = 1 resumen por técnico.
- Prune tokens inválidos; log `FCM listo` / `FCM deshabilitado`.

#### Flutter Android
- Token + refresh + logout; handlers → `/mis-ot?numero=`.
- SnackBar foreground; canal `ot_asignadas`; cleartext local.

#### Mis OT + shell
- Rango amplio, refresh, deep-link, layout móvil/tablet cómodo.
- Bottom nav **Más** (↑) con todos los destinos.
- URL API editable en Perfil + `android-adb-reverse.ps1`.

#### Tooling
- Smoke bot API + Playwright UI smoke.
- CI build API; `*.apk` en gitignore.

---

## Cómo probar (referencia rápida)

| Qué | Cómo |
|-----|------|
| API | `npm run start:dev` en `apps/api` → `FCM listo` |
| Web | `flutter run -d chrome --web-port=8080` |
| Smoke API | `npm run smoke` (desde API) |
| Push FCM | Android (web no registra token) |
| APK / USB | Perfil → `http://127.0.0.1:3000/v1` + `android-adb-reverse.ps1` |

Usuarios demo: `admin` / `supervisor` / `tecnico` — clave `Sika123!`.

---

## Qué falta (fuera de Sprint 4)

### Ops residual Sprint 4 (no bloquea merge)

| Ítem | Notas |
|------|--------|
| Smoke push en dispositivo físico | Login técnico → asignar OT → verificar bandeja |
| Rotar service account Firebase | Solo si la private key se filtró |

### Paridad SGwing / producto

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
| Indicadores / reportes avanzados | — | **M6** (~5%) |
| Offline + sync móvil | — | Fase 3 |
| Columnas GUT/HH real en schema | P2 | M3 |
| Ampliar árbol de derechos 1:1 SGMWin | — | M1 |
| Recuperación de clave | Opcional | M1 |
| CI Playwright UI | — | Tooling (diferido) |

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
