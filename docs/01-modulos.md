# 01 — Módulos del sistema

SGMWin define **qué** debe hacer el sistema. Este documento define **cómo** se organiza el reemplazo moderno.

## Principio rector

> Organizar por **módulos de dominio**, no por pantallas.
> Cada módulo tiene un contrato claro (entidades, APIs, permisos) y se desarrolla de forma independiente.

## Mapa de módulos

```
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACIÓN                      │
│  Flutter Web (admin)          Flutter Android (campo)        │
└──────────────────────────┬──────────────────────────────────┘
                           │ REST API (HTTPS)
┌──────────────────────────▼──────────────────────────────────┐
│                      NestJS API                              │
├──────────┬──────────┬──────────┬──────────┬─────────────────┤
│ M1       │ M2       │ M3       │ M4       │ M5 · M6 · M7    │
│ Seguridad│ Planta   │ Manten.  │ Pañol    │ Compras · KPIs  │
│          │          │ (corazón)│          │ · Notificaciones│
└──────────┴──────────┴──────────┴──────────┴─────────────────┘
                           │
                    PostgreSQL + RLS
```

## Dependencias entre módulos

```
M1 Seguridad ──► base de todo (auth, permisos, sucursales)
       │
M2 Planta ─────► catálogos necesarios para emitir OT
       │
M3 Mantenimiento ──► corazón del sistema (OT, procedimientos)
       │
       ├──► M7 Notificaciones (escucha eventos de M3, M4, M5)
       │
M4 Pañol ──────► depende de M3 (solicitudes desde OT)
       │
M5 Compras ────► depende de M4 (reposición de stock)
       │
M6 Indicadores ► depende de M3 (datos de OT para KPIs)
```

---

## Módulo 1 — Seguridad

**Estado:** Fundación. Una vez terminado, no se reescribe.

### Alcance

| Funcionalidad | Descripción |
|---------------|-------------|
| Login | Autenticación JWT + refresh token |
| Usuarios | CRUD con asignación a sucursal/sector/perfil |
| Perfiles | Plantillas de permisos reutilizables |
| Derechos | Árbol fijo de permisos (réplica 1:1 SGMWin) |
| Sucursales | Aislamiento de datos por sucursal |

### Entidades

`Sucursal`, `Usuario`, `Perfil`, `Derecho`, `PerfilDerecho`, `Sesion`

### Criterio de "terminado"

- Todo endpoint posterior valida permisos contra el árbol de Derechos.
- RLS de PostgreSQL filtra por `sucursal_id` en cada query.
- Usuario administrador global (`sucursal_id = NULL`) ve todas las sucursales.

### Roles operativos → configuración

| Rol | Configuración |
|-----|---------------|
| Casa Central / Gerencia General | `sucursal_id = NULL`, `supervisa_sucursales = true` |
| Administrador de Sucursal | `sucursal_id` fijo + perfil con Configuración |
| Gerente de Sucursal | `sucursal_id` fijo + perfil con Proveedores/Análisis/Costos |
| Supervisor de Sucursal | `supervisa_solicitudes_ot = todas` + reabrir/reasignar OT |
| Derivador de OT | Perfil sobre Ubicaciones + Programación |
| Técnico | `sector_id` fijo + perfil acotado a OT asignadas |
| Pañolero | Perfil con derechos de Stock |

---

## Módulo 2 — Planta

### Jerarquía real (SGMWin / Sika)

El usuario **siempre pertenece a una planta** (`usuario.sucursal_id`).
No ve el árbol de otras plantas (salvo admin global / supervisa_sucursales).

```
SIKA                             ← empresa (fijo en la UI)
  └── PLANTA_VIRREY              ← planta del usuario logueado (Sucursal)
        └── ubicaciones…         ← las crea el usuario
              └── sectores…      ← dentro de ubicaciones
                    └── máquinas ← en nodos hoja
```

El usuario **solo ve su planta**. Al inicio el árbol bajo la planta está vacío.
Profundidad **variable**: ubicación → máquina, o ubicación → sector → máquina.
La **máquina** (`Equipo`) solo cuelga de un **nodo hoja**.

| Concepto Sika/SGMWin | Modelo en la app |
|----------------------|------------------|
| Empresa (SIKA S.A.I.C.) | Constante / futuro `Empresa` |
| Planta (PLANTA_VIRREY) | `Sucursal` + `usuario.sucursal_id` |
| Ubicación / Sector / Zona | `Ubicacion` (árbol libre) |
| Máquina / Equipo | `Equipo` en nodo hoja |

### Alcance

| Funcionalidad | Descripción |
|---------------|-------------|
| Ubicaciones | Árbol libre bajo la planta del usuario |
| Equipos (máquinas) | Activo en hoja del árbol; tipo, detalle, fuera de servicio |
| Tipos de Equipo | Campos dinámicos (detalle + lecturas) |
| Componentes | Sub-partes de una máquina (si aplica) |
| Contadores | Lecturas de horas, km, ciclos, etc. |

---

## Módulo 3 — Mantenimiento (corazón)

Todo el sistema gira alrededor de la **Orden de Trabajo**.

### Alcance

| Funcionalidad | Descripción |
|---------------|-------------|
| Procedimientos | Preventivo, predictivo, correctivo — con periodicidad |
| Órdenes de Trabajo | Ciclo completo de estados |
| Solicitudes de Trabajo | Pedidos externos que derivan en OT |
| Checklist | Planilla de lecturas y tareas del procedimiento |
| Fotos | Adjuntas a la OT desde el celular |
| Firma digital | Cierre de OT con firma táctil |
| Historial | Eventos por equipo vinculados a OT |
| Emisión automática | Cron en backend (no depende de PC prendido) |
| PDF | Generado on-demand desde backend |

### Estados de OT

```
necesaria_de_emitir → pendiente → pendiente_pañol → en_ejecucion → realizada
                                                          ↘ anulada
```

### Tipos de OT

`preventivo` · `predictivo` · `correctivo` · `mejora`

---

## Módulo 4 — Pañol

### Alcance

| Funcionalidad | Descripción |
|---------------|-------------|
| Materiales | Catálogo con marca, unidad, precio, historial |
| Stock por pañol | Cantidad actual y mínima por material |
| Movimientos | Entrada, salida, reserva, devolución, transferencia |
| Solicitud de materiales | **Nuevo** — flujo de aprobación pañolero |
| Herramientas | Catálogo + préstamo/retiro/devolución |
| Alertas stock mínimo | Notificación antes de que se frene una OT |

### Flujo OT + Pañol

```
OT asignada (pendiente_pañol)
  → técnico solicita materiales
  → pañolero revisa stock
  → rechaza (notifica técnico, reintentable) o aprueba y reserva
  → técnico ejecuta, retira repuestos
  → OT realizada, stock actualizado
```

### Lógica conservada de SGMWin

- Reserva automática de materiales al emitir OT.
- Impedir emisión si falta stock (configurable).

---

## Módulo 5 — Compras

### Alcance

| Funcionalidad | Descripción |
|---------------|-------------|
| Proveedores | Catálogo con calificación post OC |
| Órdenes de Compra | Solicitud → autorización → recepción |
| Vale de Consumo | Materiales consumidos en OT |
| Autorización por monto | `monto_maximo_oc` por usuario |

### Estados de OC

`solicitada` → `autorizada` / `no_autorizada` → `anulada`

---

## Módulo 6 — Indicadores

### Alcance

| Funcionalidad | Descripción |
|---------------|-------------|
| KPIs | TMEF, TMPR, TEMP, TPMP, IMC, IMP, ICO, ICM |
| Pareto de fallas | Gráfico por causa/síntoma |
| Costos | Por equipo, sector, tipo de trabajo |
| Gantt | Programado vs realizado |
| Dashboard | Vista consolidada gerencial |
| Backlog | Evolución de OT pendientes |

### Principio

Carga analítica **separada** de la transaccional.
Los técnicos en campo no compiten con queries de KPI.

---

## Módulo 7 — Notificaciones

Salto tecnológico respecto a SGMWin (que no notifica nada).

### Eventos

| Evento | Destinatario | Canal |
|--------|--------------|-------|
| OT asignada | Técnico | Push FCM |
| Solicitud de materiales | Pañolero | Push FCM |
| Material aprobado/rechazado | Técnico | Push FCM |
| Stock bajo mínimo | Pañolero | Push FCM |
| OC mayor a umbral | Gerente | Push FCM + email |
| OT vencidas en sucursal | Casa Central | Push FCM + email |
| Solicitud de trabajo urgente | Supervisor | Push FCM |

### Arquitectura

Eventos de dominio en NestJS → cola interna → FCM.
El módulo escucha cambios de M3, M4, M5 — desacoplado de la UI.

---

## Orden de desarrollo

| Prioridad | Módulo | Fase |
|-----------|--------|------|
| 1 | M1 Seguridad | 1 |
| 2 | M2 Planta | 1 |
| 3 | M3 Mantenimiento (MVP) | 1 |
| 4 | M7 Notificaciones (básico) | 1 |
| 5 | M4 Pañol | 2 |
| 6 | M5 Compras | 2 |
| 7 | M3 extensión (emisión automática) | 2 |
| 8 | M6 Indicadores | 3 |
| 9 | M3 offline (SQLite + sync) | 3 |
