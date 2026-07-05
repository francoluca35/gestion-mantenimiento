# 06 — APIs REST

Contrato de la API NestJS, organizado por módulo.
Base URL: `https://api.{dominio}/v1`

---

## Convenciones

| Aspecto | Estándar |
|---------|----------|
| Autenticación | Bearer JWT en header `Authorization` |
| Formato | JSON (`Content-Type: application/json`) |
| Errores | `{ "statusCode": 400, "message": "...", "error": "Bad Request" }` |
| Paginación | `?page=1&limit=20` → `{ data: [], meta: { total, page, limit } }` |
| Filtros | Query params: `?estado=pendiente&tecnico_id=uuid` |
| Sucursal | Contexto automático del JWT (RLS en DB) |
| Permisos | Guard `@RequiereDerecho('codigo')` en cada endpoint |
| Idempotencia | Header `Idempotency-Key` en POST críticos |

---

## M1 — Seguridad

### Auth

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| POST | `/auth/login` | Login (usuario + clave) | Público |
| POST | `/auth/refresh` | Renovar token | Autenticado |
| POST | `/auth/logout` | Invalidar sesión | Autenticado |
| GET | `/auth/me` | Usuario actual + permisos | Autenticado |

**POST /auth/login**
```json
// Request
{ "nombre_usuario": "jperez", "clave": "..." }

// Response
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "usuario": {
    "id": "uuid",
    "nombre_usuario": "jperez",
    "sucursal": { "id": "uuid", "nombre": "Planta Virrey" },
    "perfil": { "id": "uuid", "nombre": "Técnico" },
    "derechos": ["programacion.ordenes_trabajo.buscar_y_actualizar", "..."]
  }
}
```

### Usuarios

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/usuarios` | Listar (filtro sucursal) | `configuracion.usuarios.listar` |
| GET | `/usuarios/:id` | Detalle | `configuracion.usuarios.listar` |
| POST | `/usuarios` | Crear | `configuracion.usuarios.agregar` |
| PATCH | `/usuarios/:id` | Modificar | `configuracion.usuarios.modificar` |
| DELETE | `/usuarios/:id` | Desactivar | `configuracion.usuarios.borrar` |

### Perfiles

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/perfiles` | Listar | `configuracion.perfiles.listar` |
| POST | `/perfiles` | Crear | `configuracion.perfiles.agregar` |
| PATCH | `/perfiles/:id` | Modificar | `configuracion.perfiles.modificar` |
| DELETE | `/perfiles/:id` | Eliminar | `configuracion.perfiles.borrar` |
| GET | `/perfiles/:id/derechos` | Árbol con estado | `configuracion.perfiles.definir_derechos` |
| PUT | `/perfiles/:id/derechos` | Actualizar derechos | `configuracion.perfiles.definir_derechos` |

### Derechos

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/derechos/tree` | Árbol completo | Autenticado |

### Sucursales

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/sucursales` | Listar | Autenticado |
| GET | `/sucursales/:id` | Detalle | Autenticado |
| POST | `/sucursales` | Crear | `configuracion.sucursales.agregar` |
| PATCH | `/sucursales/:id` | Modificar | `configuracion.sucursales.agregar` |
| DELETE | `/sucursales/:id` | Desactivar | `configuracion.sucursales.borrar` |

---

## M2 — Planta

### Ubicaciones

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/ubicaciones/tree` | Árbol completo de sucursal | `archivos.ubicaciones.listar` |
| POST | `/ubicaciones` | Crear nodo | `archivos.ubicaciones.agregar_nodo` |
| PATCH | `/ubicaciones/:id` | Modificar | `archivos.ubicaciones.modificar_nodo` |
| DELETE | `/ubicaciones/:id` | Eliminar (sin hijos ni equipos) | `archivos.ubicaciones.borrar_nodo` |
| POST | `/ubicaciones/:id/mover` | Mover en el árbol | `archivos.ubicaciones.mover_nodo` |

### Equipos

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/equipos` | Listar (filtros) | `archivos.equipos.listar` |
| GET | `/equipos/:id` | Detalle + historial | `archivos.equipos.listar` |
| POST | `/equipos` | Crear | `archivos.equipos.agregar` |
| PATCH | `/equipos/:id` | Modificar | `archivos.equipos.modificar` |
| DELETE | `/equipos/:id` | Desactivar | `archivos.equipos.borrar` |
| POST | `/equipos/:id/mover` | Mover a otra ubicación | `archivos.equipos.mover` |
| POST | `/equipos/:id/fuera-de-servicio` | Marcar fuera de servicio | `archivos.equipos.marcar_fuera_de_servicio` |

### Tipos de Equipo

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/tipos-equipo` | Listar | `archivos.tipos_equipo.listar` |
| POST | `/tipos-equipo` | Crear | `archivos.tipos_equipo.agregar` |
| PATCH | `/tipos-equipo/:id` | Modificar campos dinámicos | `archivos.tipos_equipo.modificar` |

### Lecturas / Contadores

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/equipos/:id/lecturas` | Historial | `programacion.contadores.buscar_equipo` |
| POST | `/equipos/:id/lecturas` | Agregar lectura | `programacion.contadores.agregar_lectura` |
| GET | `/equipos/:id/lecturas/grafico` | Datos para gráfico | `programacion.contadores.graficar` |

---

## M3 — Mantenimiento

### Procedimientos

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/procedimientos` | Listar | `archivos.procedimientos.listar` |
| GET | `/procedimientos/:id` | Detalle + versiones | `archivos.procedimientos.listar` |
| POST | `/procedimientos` | Crear | `archivos.procedimientos.agregar` |
| PATCH | `/procedimientos/:id` | Modificar (nueva versión) | `archivos.procedimientos.modificar` |
| POST | `/procedimientos/:id/asociar-equipo` | Asociar a equipo | `archivos.procedimientos.asociar_a_equipo` |

### Órdenes de Trabajo

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/ot` | Buscar (filtros avanzados) | `programacion.ordenes_trabajo.buscar_y_actualizar` |
| GET | `/ot/:id` | Detalle completo | `programacion.ordenes_trabajo.buscar_y_actualizar` |
| POST | `/ot/emitir` | Emitir OT manual | `programacion.ordenes_trabajo.emitir_no_periodica` |
| POST | `/ot/emitir-periodica` | Emitir por procedimiento | `programacion.ordenes_trabajo.emitir_periodica` |
| PATCH | `/ot/:id/asignar` | Asignar técnico | `programacion.ordenes_trabajo.buscar_y_actualizar` |
| PATCH | `/ot/:id/estado` | Cambiar estado | Según transición |
| POST | `/ot/:id/checklist` | Completar checklist | Técnico asignado |
| POST | `/ot/:id/fotos` | Subir foto | Técnico asignado |
| POST | `/ot/:id/firma` | Registrar firma | Técnico asignado |
| POST | `/ot/:id/mano-obra` | Cargar mano de obra | Técnico asignado |
| POST | `/ot/:id/materiales` | Cargar materiales usados | Técnico asignado |
| POST | `/ot/:id/reabrir` | Reabrir OT | `es_administrador` |
| POST | `/ot/:id/anular` | Anular | `programacion.ordenes_trabajo.anular` |
| GET | `/ot/:id/pdf` | Generar PDF | `programacion.ordenes_trabajo.reimprimir` |
| GET | `/ot/reportes/estado` | OT por estado | `programacion.ordenes_trabajo.ver_reportes_estado` |

**GET /ot** (filtros)
```
?estado=pendiente,en_ejecucion
&tecnico_id=uuid
&equipo_id=uuid
&fecha_desde=2026-01-01
&fecha_hasta=2026-12-31
&tipo=preventivo
&prioridad=alta,urgente
&ubicacion_id=uuid
&page=1&limit=20
```

### Solicitudes de Trabajo

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/solicitudes-trabajo` | Listar | `programacion.solicitudes_trabajo.listar` |
| POST | `/solicitudes-trabajo` | Crear | `programacion.solicitudes_trabajo.agregar` |
| PATCH | `/solicitudes-trabajo/:id/conformidad` | Dar conformidad | `programacion.solicitudes_trabajo.dar_conformidad` |
| POST | `/solicitudes-trabajo/:id/emitir-ot` | Generar OT | `programacion.solicitudes_trabajo.emitir_ot_desde_solicitud` |

---

## M4 — Pañol

### Stock

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/stock` | Stock por pañol | `stock.materiales_en_stock.ver` |
| PATCH | `/stock/:id` | Modificar mínimos | `stock.pañol.alertas_stock_minimo.configurar_minimo` |
| GET | `/stock/alertas` | Stock bajo mínimo | `stock.pañol.alertas_stock_minimo.ver` |

### Movimientos

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/movimientos` | Listar | `stock.movimientos.listar` |
| POST | `/movimientos/entrada` | Alta por compra/OC | `stock.movimientos.alta_por_compra` |
| POST | `/movimientos/salida` | Baja | `stock.movimientos.baja` |
| POST | `/movimientos/transferencia` | Entre pañoles | `stock.movimientos.alta_por_transferencia` |

### Solicitudes de Materiales

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/solicitudes-material` | Listar pendientes | `stock.pañol.solicitudes_materiales.ver_pendientes` |
| POST | `/solicitudes-material` | Crear (desde OT) | Técnico asignado |
| PATCH | `/solicitudes-material/:id/aprobar` | Aprobar | `stock.pañol.solicitudes_materiales.aprobar` |
| PATCH | `/solicitudes-material/:id/rechazar` | Rechazar | `stock.pañol.solicitudes_materiales.rechazar` |

### Herramientas

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/herramientas` | Listar | `stock.prestamo_herramientas.listar` |
| POST | `/herramientas/:id/retirar` | Préstamo | `stock.prestamo_herramientas.retirar` |
| POST | `/herramientas/:id/devolver` | Devolución | `stock.prestamo_herramientas.devolver` |

---

## M5 — Compras

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/proveedores` | Listar | `archivos.proveedores.listar` |
| POST | `/proveedores` | Crear | `archivos.proveedores.agregar` |
| GET | `/ordenes-compra` | Listar | `stock.ordenes_compra.buscar_y_actualizar` |
| POST | `/ordenes-compra` | Crear | `stock.ordenes_compra.emitir` |
| PATCH | `/ordenes-compra/:id/autorizar` | Autorizar (valida monto) | `stock.ordenes_compra.emitir` |
| PATCH | `/ordenes-compra/:id/anular` | Anular | `stock.ordenes_compra.anular` |
| POST | `/vales-consumo` | Emitir vale | `stock.vale_consumo.emitir` |
| GET | `/vales-consumo/:id/pdf` | Reimprimir | `stock.vale_consumo.reimprimir` |

---

## M6 — Indicadores

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/analytics/indices/:equipoId` | KPIs de un equipo | `analisis.trabajos.indices_gestion` |
| GET | `/analytics/pareto-fallas` | Pareto | `analisis.trabajos.pareto_fallas` |
| GET | `/analytics/costos` | Costos por período | `analisis.trabajos.costos` |
| GET | `/analytics/gantt` | Programado vs realizado | `programacion.gestion.programado_vs_realizado` |
| GET | `/analytics/backlog` | Evolución backlog | `programacion.gestion.backlog` |
| GET | `/analytics/dashboard` | Resumen gerencial | `programacion.gestion.resumen_situacion` |

---

## M7 — Notificaciones

| Método | Endpoint | Descripción | Derecho |
|--------|----------|-------------|---------|
| GET | `/notificaciones` | Listar (paginado) | Autenticado |
| PATCH | `/notificaciones/:id/leer` | Marcar leída | Autenticado |
| PATCH | `/notificaciones/leer-todas` | Marcar todas | Autenticado |
| POST | `/dispositivos/fcm` | Registrar token FCM | Autenticado |
| DELETE | `/dispositivos/fcm/:token` | Desregistrar | Autenticado |

---

## M3 — Sync offline (Fase 3)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/sync/pull` | Descargar cambios desde último sync |
| POST | `/sync/push` | Enviar cola de cambios locales |
| GET | `/sync/status` | Estado de sincronización |

**POST /sync/push**
```json
{
  "ultimo_sync": "2026-03-15T10:00:00Z",
  "cambios": [
    {
      "entidad": "orden_trabajo",
      "id": "uuid",
      "accion": "update",
      "datos": { "estado": "realizada", "firma_digital": "base64..." },
      "timestamp_local": "2026-03-15T09:45:00Z"
    }
  ]
}
```

---

## Webhooks internos (eventos de dominio)

No son endpoints públicos. Eventos que disparan notificaciones:

| Evento | Módulo origen | Destinatarios |
|--------|---------------|---------------|
| `ot.asignada` | M3 | Técnico |
| `ot.estado_cambiado` | M3 | Supervisor, técnico |
| `solicitud_material.creada` | M4 | Pañolero |
| `solicitud_material.resuelta` | M4 | Técnico |
| `stock.bajo_minimo` | M4 | Pañolero |
| `orden_compra.solicitada` | M5 | Autorizador, gerente |
| `orden_compra.autorizada` | M5 | Solicitante |
| `solicitud_trabajo.urgente` | M3 | Supervisor |
| `ot.vencidas_sucursal` | M3 | Casa Central |
