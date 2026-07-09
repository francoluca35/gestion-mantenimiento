# Faltantes — Módulo 1 (Seguridad)

Estado actual: **módulo cerrado para desarrollo** (~92%). Pendiente solo paridad 1:1 SGMWin y extras opcionales.

**Estado global:** [`../00-estado-proyecto.md`](../00-estado-proyecto.md)

---

## Criterio de “terminado” (docs/01-modulos.md)

| Criterio | Estado |
|----------|--------|
| Todo endpoint valida permisos contra el árbol de Derechos | Hecho (`JwtAuthGuard` + `DerechoGuard`) |
| RLS de PostgreSQL filtra por `sucursal_id` | **Hecho** — migración `20260709040000_rls_sucursal` |
| Admin global (`sucursal_id = NULL`) ve todas las sucursales | Hecho (flag + RLS `app.es_admin_global`) |

---

## Qué ya está

### Backend

- Login / refresh / logout / `GET /auth/me` (JWT)
- `PATCH /auth/clave`, `GET /auth/sesiones`, `POST /auth/sesiones/revocar-todas`
- Tablas: `sucursales`, `usuarios`, `perfiles`, `derechos`, `perfil_derechos`, `sesiones`
- CRUD API: usuarios, perfiles, sucursales
- `sectorId` en usuarios (FK a `ubicaciones`)
- Árbol de derechos (seed parcial) + resolución Total/Parcial en `PermisosService`
- Flags: `es_administrador`, `supervisa_sucursales`, `supervisa_solicitudes_ot/oc`, `monto_maximo_oc`
- Aislamiento por sucursal en **NestJS + RLS PostgreSQL**
- RLS contexto por request (`RlsInterceptor` + `PrismaService` con `set_config`)
- Seed demo: `admin`, `tecnico`, `panolero`, `supervisor`, `admin.virrey` (clave `Sika123!`)
- Tests e2e: `apps/api/test/auth-security.e2e-spec.ts` (6 casos)

### Flutter

- Login real + sesión persistida
- Redirect según autenticación y rol (técnico → `/mis-ot`)
- Home con pestaña Config (si tiene permiso)
- CRUD: Usuarios, Perfiles, Sucursales (formularios sheet)
- Editor derechos Total/Parcial (`/perfiles/:id/derechos`)
- Árbol derechos solo lectura (`/derechos`)
- Perfil: cambio de clave, listado de sesiones, revocar todas
- Usuario: asignación de sector (árbol ubicaciones por sucursal)

---

## Qué falta (no bloquea M2/M3)

### 1. Árbol de derechos completo 1:1 SGMWin — prioridad media

El seed actual es un **subconjunto** útil para M1–M3. Falta completar según `docs/05-permisos.md` (catálogos, Gantt, stock, etc.).

### 2. Validaciones opcionales — prioridad baja

| Regla | Estado |
|-------|--------|
| Recuperación de clave / bloqueo por intentos | Falta (opcional) |
| Invalidar JWT access al cambiar clave | Parcial — se revocan sesiones DB; access token sigue válido hasta expirar |
| Pantalla **admin_sucursal** (dashboard dedicado) | Falta (opcional) |

### 3. Tests adicionales — prioridad baja

- Resolución Total/Parcial del árbol (unit)
- Más casos RLS directos en DB (equipos cross-sucursal por ID)

---

## Referencias

- `docs/01-modulos.md` — alcance M1
- `docs/05-permisos.md` — árbol completo y reglas
- `docs/06-apis.md` — contrato REST M1
- `docs/07-pantallas.md` — D-01 a D-05
