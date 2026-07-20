# Inventario de la aplicación — Gestión de Mantenimiento Sika

**Fecha:** 2026-07-20  
**Plataforma:** Flutter (Web + Android) + NestJS API (`/v1`)  
**Estado maestro:** [`00-estado-proyecto.md`](00-estado-proyecto.md)

Este documento responde: **qué tiene la app hoy**, **qué puede hacer cada rol**, y **qué conviene mejorar**.

---

## 1. Visión en una frase

Sistema de mantenimiento industrial (paridad SGMWin / SGwing) para planta Sika: planta y equipos, procedimientos, órdenes de trabajo, pañol/stock, solicitudes, notificaciones push — usable en **oficina (web)** y **planta (Android)**.

---

## 2. Módulos y cobertura

| Módulo | Qué incluye | Estado |
|--------|-------------|--------|
| **M1 Seguridad** | Login, usuarios, perfiles, derechos, sucursales, RLS, sesiones | ~92% |
| **M2 Planta** | Árbol planta→sector→equipo, ficha, documentos, lecturas, historial | ~90% |
| **M3 Mantenimiento** | Procedimientos, OT (emitir/asignar/ejecutar/cerrar), solicitudes trabajo, PDF, Motivos | ~92% |
| **M4 Pañol** | Stock, materiales, solicitudes desde OT, pedidos reposición, movimientos, alertas mín. | ~95% |
| **M5 Compras** | OC / proveedores | 0% |
| **M6 Indicadores** | Dashboard KPIs (TMEF, ICO, Pareto, Gantt) | ~5% (resumen OT en home) |
| **M7 Notificaciones** | FCM Android, deep-link a Mis OT | ~95% |

---

## 3. Usuarios demo (seed)

Clave común: **`Sika123!`**  
Planta principal: **PLANTA_VIRREY** (también existe ROSARIO vacía).

| Usuario | Rol / perfil | Enfoque |
|---------|--------------|---------|
| `admin` | Administrador global | Todo: config + planta + OT + stock |
| `admin.virrey` | Admin Sucursal | Config de su sucursal + operación |
| `supervisor` | Supervisor | Programación OT, procedimientos, planta, solicitudes |
| `tecnico` | Técnico | Solo **Mis OT** + perfil |
| `panolero` | Pañolero | Solo shell **Pañol** (stock / pedidos / seguimiento) |

---

## 4. Qué puede hacer cada rol

Los menús se arman por **derechos** (no por hardcode de plataforma). Los shells de técnico y pañolero están acotados a propósito.

### 4.1 Técnico (`tecnico`)

| Puede | No puede (por diseño) |
|-------|------------------------|
| Ver **Mis OT** (asignadas) | Emitir OT, programar, config |
| Abrir detalle, checklist, fotos/firma | CRUD usuarios / planta completa |
| Pasar a ejecución, cerrar OT | Aprobar materiales de pañol |
| **Solicitar materiales** al pañol | Ver indicadores gerenciales |
| Recibir **push** al asignar OT (Android) | |
| Cambiar clave / URL API / ver sesiones | |

**Flujo típico:** Login → Mis OT → ejecutar → (opcional pedir material) → checklist → firma → cerrar.

### 4.2 Pañolero (`panolero`)

| Puede | Pantallas |
|-------|-----------|
| Ver / editar stock, mínimos, entradas/salidas | `/panol/stock` |
| Ver solicitudes de materiales de OT; aprobar / rechazar | `/panol/pedidos` |
| Pedidos de reposición (analizar bajo mínimo → pedir → completar) | `/panol/pedidos` |
| Historial de movimientos | `/panol/seguimiento` |
| Dashboard de pedidos | `/panol/dashboard` (web; en móvil se omite el tab) |
| Push de nueva solicitud / stock bajo mínimo | Android |

**Flujo típico:** Login → Stock o Pedidos → aprobar material → (si hace falta) pedir stock → completar entrada.

### 4.3 Supervisor (`supervisor`)

| Área | Acciones |
|------|----------|
| **Planta / Equipos** | Explorar mapa, fichas, historial, procedimientos asociados |
| **Procedimientos** | Listar, alta/edición, asociar a planta/sector/equipo |
| **OT** | Buscar, filtrar, asignar técnico, emitir no periódica / necesarias, derivar, anular/reabrir (según derecho) |
| **Solicitudes de trabajo** | Listar, conformidad, emitir OT |
| **Contadores / lecturas** | Consulta y reinicio (si aplica) |
| **Home** | Resumen de OT |

No suele tener Config (usuarios) ni modo total de stock (salvo que se le agreguen derechos).

### 4.4 Admin sucursal (`admin.virrey`)

Todo lo del supervisor **más**:

- Usuarios, perfiles, editor de derechos, sucursales (`/config`)
- Árbol de derechos (consulta)

### 4.5 Admin global (`admin`)

Todo lo anterior en todas las sucursales (`esAdministrador` + `supervisaSucursales`), bypass de derechos en guards.

---

## 5. Mapa de pantallas (Flutter)

| Ruta | Nombre | Quién la usa |
|------|--------|--------------|
| `/login` | Inicio de sesión | Todos |
| `/home` | Inicio / resumen | Admin, supervisor |
| `/mis-ot` | Mis órdenes | Técnico |
| `/ot` | Buscar / gestionar OT | Supervisor, admin |
| `/ot/necesarias` | Emitir OT periódicas vencidas | Supervisor, admin |
| `/ot/emitir-no-periodica` | Emitir OT correctiva / no periódica | Supervisor, admin |
| `/ot/emitir-periodica` | Emitir periódica (flujo dedicado) | Supervisor, admin |
| `/procedimientos` | Catálogo de procedimientos | Supervisor, admin |
| `/planta` | Explorador planta y equipos | Supervisor, admin |
| `/solicitudes` | Solicitudes de trabajo | Supervisor, admin |
| `/contadores` | Contadores / lecturas | Supervisor, admin |
| `/panol/*` | Shell pañol | Pañolero |
| `/stock` | Stock (shell general) | Admin con derecho stock |
| `/solicitudes-materiales` | Alias → pedidos pañol | Admin / pañol |
| `/config` | Hub configuración | Admin |
| `/usuarios` `/perfiles` `/sucursales` `/derechos` | Seguridad | Admin |
| `/perfil` | Mi perfil | Todos |

---

## 6. Capacidades por dominio (detalle)

### Seguridad
- JWT + refresh, logout, cambio de clave, listado/revocación de sesiones
- CRUD usuarios / perfiles / sucursales
- Derechos Total / Parcial por perfil
- RLS PostgreSQL por `sucursal_id`

### Planta
- Árbol ubicaciones + equipos, mover, copiar/pegar, fuera de servicio
- Ficha: general, lecturas, historial OT/proc, documentos (MinIO)
- Toolbar adaptativa (en móvil: menú **Acciones**)
- Impresión / CSV

### Mantenimiento
- Procedimientos + alcances (planta / sector / equipo)
- OT: estados `necesaria` → `pendiente` → `pendiente_panol` → `en_ejecucion` → `realizada` / `anulada`
- Checklist, firma, PDF HTML imprimible, derivar OT
- Emisión lote OT necesarias + push resumen por técnico
- Cron diario emisión OT (configurable)
- Solicitudes de trabajo + conformidad

### Pañol
- Materiales, unidades, stock por pañol (actual / mínimo / reservado)
- Solicitud desde OT → reserva al aprobar → **descuento al cerrar OT** → liberación si se anula
- Pedidos stock (PD-####), movimientos, `GET /stock/alertas`, cron alertas mínimo

### Notificaciones
- Registro token FCM (Android)
- Push: OT asignada, material rechazado, solicitud a pañol, stock bajo mínimo
- Deep-link `/mis-ot?numero=N`

---

## 7. Web vs móvil

| Tema | Web | Android |
|------|-----|---------|
| Layout | Sidebar / paneles | Bottom nav + sheet **Más** |
| Técnico | Mis OT | Mismo + push |
| Pañolero | Tabs completos | Sin tab Dashboard |
| Planta / OT densas | Cómodas | Usables; toolbar compacta |
| FCM | No | Sí |
| URL API en runtime | Perfil → Servidor API | Igual (clave en planta) |

---

## 8. Qué falta / qué mejorar

### Prioridad alta (producto demo)
1. **Host demo estable** (Sprint 5) — no depender de la notebook  
2. **Pulir móvil supervisor** — conformidad y OT de sector más rápidas  
3. **Fotos / evidencias** en ejecución OT (endurecer flujo)  
4. **Mano de obra / HH** y materiales consumidos visibles en la OT  

### Prioridad media (paridad SGMWin)
5. **M5 Compras** — reposición formal desde mínimos  
6. **M6 Indicadores** — TMEF, ICO, Pareto, dashboard gerencial  
7. **Gantt** de programación OT  
8. Transferencia entre pañoles; reserva automática al emitir OT  

### Prioridad baja / largo plazo
9. Offline + sync del técnico  
10. Versiones de procedimiento  
11. Árbol de derechos 1:1 completo SGMWin  
12. Recuperación de clave; PDF binario (Puppeteer); e2e CI ampliado  

### Mejoras UX (rápidas)
- Contraste y densidad en tablas oscuras (seguir el patrón de toolbar Planta)  
- Empty states y mensajes de error más humanos  
- Unificar labels “Mat. pañol” / “Pedidos”  
- Home con KPIs mínimos aunque M6 no esté completo  

---

## 9. Stack técnico (resumen)

| Capa | Tecnología |
|------|------------|
| App | Flutter + Riverpod + GoRouter |
| API | NestJS + Prisma + PostgreSQL |
| Auth | JWT + guards por derecho |
| Storage | MinIO (dev) / R2-S3 (prod) |
| Push | Firebase Cloud Messaging |
| Infra local | Docker Compose (Postgres, Redis, MinIO) |
| Infra demo | `docker-compose.demo.yml` + backups |

---

## 10. Documentos relacionados

| Doc | Contenido |
|-----|-----------|
| [`manual-de-uso.md`](manual-de-uso.md) | Manual paso a paso por rol |
| [`00-estado-proyecto.md`](00-estado-proyecto.md) | Estado y backlog |
| [`faltantes/sgwing-paridad.md`](faltantes/sgwing-paridad.md) | Checklist pantallas SGwing |
| [`faltantes/m4-panol.md`](faltantes/m4-panol.md) | Detalle Pañol |
| [`faltantes/sprint-5-infra-demo.md`](faltantes/sprint-5-infra-demo.md) | Deploy demo |
| [`05-permisos.md`](05-permisos.md) | Árbol de derechos |
| [`07-pantallas.md`](07-pantallas.md) | Inventario UX histórico |
