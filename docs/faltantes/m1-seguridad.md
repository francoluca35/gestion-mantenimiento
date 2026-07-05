# Faltantes — Módulo 1 (Seguridad)

Estado actual: **fundación usable**, no módulo cerrado.

Sirve para seguir con M2/M3 (auth + guards en API). Falta cerrar administración, RLS y UI completa.

---

## Criterio de “terminado” (docs/01-modulos.md)

| Criterio | Estado |
|----------|--------|
| Todo endpoint valida permisos contra el árbol de Derechos | Hecho (`JwtAuthGuard` + `DerechoGuard`) |
| RLS de PostgreSQL filtra por `sucursal_id` | **Falta** |
| Admin global (`sucursal_id = NULL`) ve todas las sucursales | Hecho |

---

## Qué ya está

### Backend

- Login / refresh / logout / `GET /auth/me` (JWT)
- Tablas: `sucursales`, `usuarios`, `perfiles`, `derechos`, `perfil_derechos`, `sesiones`
- CRUD API: usuarios, perfiles, sucursales
- Árbol de derechos (seed parcial) + resolución Total/Parcial en `PermisosService`
- Flags: `es_administrador`, `supervisa_sucursales`, `supervisa_solicitudes_ot/oc`, `monto_maximo_oc`
- Aislamiento por sucursal en **lógica NestJS** (no en DB)
- Seed demo: `admin`, `tecnico`, `panolero`, `supervisor`, `admin.virrey` (clave `Sika123!`)

### Flutter

- Login real + sesión persistida
- Redirect según autenticación
- Home con pestaña Config (si tiene permiso)
- Listados de solo lectura: Usuarios, Perfiles, Sucursales
- Perfil + logout

---

## Qué falta

### 1. Row-Level Security (PostgreSQL) — prioridad alta

Hoy el filtro por sucursal es solo en servicios NestJS. Si hay un bug o query mal armada, se puede filtrar mal.

Falta:

- Políticas RLS en tablas con `sucursal_id` (usuarios y las que vengan en M2+)
- Setear contexto de sesión por request (`app.current_sucursal_id`, `app.es_admin_global`, `app.supervisa_sucursales`)
- Probar que un usuario de Virrey no ve datos de Rosario aunque se equivoque el service

Referencia: `docs/03-relaciones.md`

---

### 2. UI de administración (Flutter) — prioridad alta

La API ya permite crear/editar; la app solo lista.

| Pantalla | Falta |
|----------|-------|
| Usuarios | Formulario alta / edición / desactivar; asignar sucursal, perfil, flags |
| Perfiles | Alta / edición / desactivar |
| Sucursales | Alta / edición / desactivar |
| Derechos por perfil | Editor checklist Total/Parcial (sección 12 del spec) |

Sin esto, la configuración se hace solo por seed o llamadas manuales a la API.

---

### 3. Editor de derechos Total/Parcial — prioridad alta

API lista:

- `GET /perfiles/:id/derechos`
- `PUT /perfiles/:id/derechos`

Falta en Flutter:

- Árbol expandible
- Checkbox por nodo
- Modo **Total** (padre habilita todos los hijos) vs **Parcial** (hijos sueltos)
- Guardar y recargar estado

Es la pantalla que en SGMWin define el perfil; sin ella el modelo de permisos no se administra desde la app.

---

### 4. Árbol de derechos completo 1:1 SGMWin — prioridad media

El seed actual es un **subconjunto** útil para M1–M3 (archivos, programación, stock/pañol, análisis, configuración).

Falta completar según `docs/05-permisos.md`:

- Catálogos generales (eventos, tareas, causas, síntomas, etc.)
- Contadores, gestión (backlog, Gantt, presupuesto)
- Movimientos, reserva, vale de consumo, préstamo de herramientas
- Análisis de stock completo
- Parámetros, reportes, copia de seguridad
- Nodos reservados documentados (reabrir OT, etc.)

No bloquea desarrollo, pero sí la paridad con el manual.

---

### 5. `sector_id` en Usuario — prioridad media

El campo existe en el modelo, pero:

- No hay FK real a `Ubicacion` (M2 aún no existe)
- No hay UI para asignar sector al usuario
- No se usa en filtros de “solo su sector”

Depende de **M2 — Planta** (árbol de ubicaciones). Completar cuando exista Ubicacion.

---

### 6. Validaciones y reglas de negocio finas — prioridad media

| Regla | Estado |
|-------|--------|
| No desactivar el propio usuario | Hecho |
| Solo admin crea otros administradores | Hecho |
| No listar usuarios de otra sucursal (sin supervisar) | Hecho en service |
| Forzar `es_administrador` / generar perfiles solo por flag (no por árbol) | Parcial (flag existe; UI no lo refleja del todo) |
| Historial de sesiones / “cerrar todas las sesiones” | Falta |
| Cambio de clave por el propio usuario | Falta |
| Recuperación de clave / bloqueo por intentos fallidos | Falta (opcional) |

---

### 7. Pantallas / flujos pendientes del spec — prioridad baja

Del spec original (sección 12):

- Pantalla **admin_sucursal** (dashboard con rama Configuración, no Análisis)
- Asignar usuarios a sucursal desde la ficha de sucursal
- Ver árbol de derechos global (`GET /derechos/tree`) en UI (solo lectura, para soporte)

---

### 8. Tests — prioridad media

Falta:

- Tests e2e de login / refresh / logout
- Tests de permisos (técnico no lista usuarios; admin sí)
- Tests de aislamiento por sucursal
- Tests de resolución Total/Parcial del árbol

---

## Orden sugerido para cerrar M1

1. Formularios CRUD en Flutter (usuarios, perfiles, sucursales)
2. Editor de derechos Total/Parcial
3. RLS en PostgreSQL
4. Ampliar seed del árbol de derechos
5. Tests de auth y permisos
6. `sector_id` cuando exista M2
7. Extras (cambio de clave, admin_sucursal)

---

## Qué no hace falta para avanzar a M2

Se puede empezar **M2 — Planta** con lo actual:

- Auth JWT funciona
- Guards protegen endpoints nuevos con `@RequiereDerecho(...)`
- Usuarios demo listos para probar roles

Lo pendiente de M1 se puede ir cerrando en paralelo o en un sprint de “hardening” antes de producción.

---

## Referencias

- `docs/01-modulos.md` — alcance M1
- `docs/05-permisos.md` — árbol completo y reglas
- `docs/06-apis.md` — contrato REST M1
- `docs/07-pantallas.md` — D-01 a D-05 (login, usuarios, perfiles, derechos, sucursales)
- `docs/09-roadmap.md` — Sprint 1–2
