# 02 — Modelo de entidades

Todas las tablas del sistema, organizadas por módulo.

---

## M1 — Seguridad

### Sucursal

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| nombre | VARCHAR(100) | |
| codigo | VARCHAR(20) | Único |
| activa | BOOLEAN | default true |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### Usuario

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| nombre_usuario | VARCHAR(50) | Único |
| clave_hash | VARCHAR(255) | bcrypt |
| email | VARCHAR(100) | |
| sucursal_id | UUID | FK → Sucursal, NULL = admin global |
| sector_id | UUID | FK → Ubicacion, nullable |
| perfil_id | UUID | FK → Perfil |
| es_administrador | BOOLEAN | Derechos reservados (usuario "SGM") |
| supervisa_sucursales | BOOLEAN | Ve todas sin ser admin |
| supervisa_solicitudes_ot | ENUM | `ninguna` · `de_su_sector` · `todas` |
| supervisa_solicitudes_oc | BOOLEAN | |
| monto_maximo_oc | DECIMAL(15,2) | Tope de autorización OC, nullable |
| activo | BOOLEAN | |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### Perfil

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| nombre | VARCHAR(100) | ej: "Técnico", "Pañolero" |
| descripcion | TEXT | nullable |
| activo | BOOLEAN | |

### Derecho

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| parent_id | UUID | FK → Derecho, nullable = raíz |
| codigo | VARCHAR(100) | Único, ej: `archivos.equipos.agregar` |
| nombre | VARCHAR(200) | Legible |
| orden | INT | Para renderizar el árbol |

### PerfilDerecho

| Campo | Tipo | Notas |
|-------|------|-------|
| perfil_id | UUID | PK compuesta |
| derecho_id | UUID | PK compuesta |
| habilitado | BOOLEAN | Total o parcial |

---

## M2 — Planta

### Ubicacion

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| sucursal_id | UUID | FK → Sucursal |
| parent_id | UUID | FK → Ubicacion, nullable = raíz |
| nombre | VARCHAR(200) | |
| orden | INT | Posición entre hermanos |
| activa | BOOLEAN | |

### TipoEquipo

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| nombre | VARCHAR(100) | |
| campos_detalle | JSONB | Definición dinámica de campos |
| campos_lectura | JSONB | Contadores: horas, km, ciclos… |
| activo | BOOLEAN | |

### Equipo

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| ubicacion_id | UUID | FK → nodo hoja del árbol |
| tipo_equipo_id | UUID | FK → TipoEquipo |
| nombre | VARCHAR(200) | |
| codigo | VARCHAR(50) | |
| detalle | JSONB | Valores según campos_detalle del tipo |
| fuera_de_servicio | BOOLEAN | default false |
| fecha_baja | DATE | nullable |
| activo | BOOLEAN | |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### Componente

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| equipo_id | UUID | FK → Equipo |
| nombre | VARCHAR(200) | |
| codigo | VARCHAR(50) | nullable |
| detalle | JSONB | nullable |
| activo | BOOLEAN | |

### Lectura

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| equipo_id | UUID | FK → Equipo |
| tipo | VARCHAR(50) | horas, km, ciclos… |
| valor | DECIMAL(15,2) | |
| fecha | TIMESTAMPTZ | |
| usuario_id | UUID | FK → Usuario |
| ot_id | UUID | FK → OrdenTrabajo, nullable |

---

## M3 — Mantenimiento

### Procedimiento

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| sucursal_id | UUID | FK → Sucursal |
| nombre | VARCHAR(200) | |
| tipo | ENUM | `preventivo` · `predictivo` · `correctivo` |
| tipo_procedimiento_id | UUID | FK → catálogo |
| sector_responsable_id | UUID | FK → Ubicacion |
| descripcion | TEXT | |
| planilla_lecturas | JSONB | Checklist de lecturas |
| periodicidad_tipo | ENUM | `tiempo` · `contador` |
| periodicidad_valor | INT | Días o umbral de contador |
| duracion_estimada | INT | Minutos |
| hs_hombre | DECIMAL(8,2) | |
| cant_operarios | INT | |
| indisponibilidad_estimada | INT | Minutos |
| costo_estimado | DECIMAL(15,2) | |
| version_actual | INT | default 1 |
| activo | BOOLEAN | |

### ProcedimientoEquipo

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| procedimiento_id | UUID | FK |
| equipo_id | UUID | FK |
| estado | ENUM | `activo` · `suspendido` · `baja` |
| fecha_asociacion | DATE | |
| ultima_emision | DATE | nullable |

### OrdenTrabajo

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| numero | SERIAL | Número visible |
| sucursal_id | UUID | FK → Sucursal |
| ubicacion_id | UUID | FK → Ubicacion |
| equipo_id | UUID | FK → Equipo |
| procedimiento_id | UUID | FK, nullable si correctiva libre |
| tipo | ENUM | `preventivo` · `predictivo` · `correctivo` · `mejora` |
| estado | ENUM | Ver estados abajo |
| tecnico_asignado_id | UUID | FK → Usuario, nullable |
| fecha_programacion | DATE | |
| fecha_ejecucion | DATE | nullable |
| tolerancia | INT | Días de tolerancia |
| prioridad | ENUM | `baja` · `media` · `alta` · `urgente` |
| motivo_pendiente_id | UUID | FK → catálogo, nullable |
| comentarios | TEXT | |
| novedades_fuera_de_programa | TEXT | nullable |
| firma_digital | TEXT | Base64 o URL |
| fotos | JSONB | Array de URLs |
| ot_reemplazada_id | UUID | FK → OrdenTrabajo, nullable |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

**Estados:** `necesaria_de_emitir` · `pendiente` · `pendiente_pañol` · `en_ejecucion` · `realizada` · `anulada`

### OTManoDeObra

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| ot_id | UUID | FK → OrdenTrabajo |
| mano_obra_id | UUID | FK → catálogo ManoDeObra |
| horas_normales | DECIMAL(6,2) | |
| horas_extra | DECIMAL(6,2) | |
| horas_100 | DECIMAL(6,2) | |
| horas_200 | DECIMAL(6,2) | |

### OTMaterial

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| ot_id | UUID | FK → OrdenTrabajo |
| material_id | UUID | FK → Material |
| cantidad | DECIMAL(10,2) | |
| unidad | VARCHAR(20) | |

### SolicitudTrabajo

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| sucursal_id | UUID | FK |
| solicitante | VARCHAR(200) | |
| descripcion | TEXT | |
| urgente | BOOLEAN | |
| estado | ENUM | `pendiente` · `conformada` · `rechazada` |
| ot_generada_id | UUID | FK → OrdenTrabajo, nullable |
| created_at | TIMESTAMPTZ | |

### HistorialEquipo

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| equipo_id | UUID | FK |
| ot_id | UUID | FK, nullable |
| tipo_evento | VARCHAR(50) | |
| descripcion | TEXT | |
| fecha | TIMESTAMPTZ | |
| usuario_id | UUID | FK |

---

## M4 — Pañol

### Pañol

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| sucursal_id | UUID | FK |
| nombre | VARCHAR(100) | |
| activo | BOOLEAN | |

### Material

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| nombre | VARCHAR(200) | |
| codigo | VARCHAR(50) | |
| marca | VARCHAR(100) | nullable |
| unidad_id | UUID | FK → catálogo Unidad |
| precio_actual | DECIMAL(15,2) | |
| activo | BOOLEAN | |

### MaterialPrecioHistorial

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| material_id | UUID | FK |
| precio | DECIMAL(15,2) | |
| fecha | TIMESTAMPTZ | |
| usuario_id | UUID | FK |

### StockItem

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| pañol_id | UUID | FK → Pañol |
| material_id | UUID | FK → Material |
| cantidad_actual | DECIMAL(10,2) | |
| cantidad_minima | DECIMAL(10,2) | |
| cantidad_reservada | DECIMAL(10,2) | default 0 |

### MovimientoStock

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| pañol_id | UUID | FK |
| material_id | UUID | FK |
| tipo | ENUM | `entrada` · `salida` · `reserva` · `devolucion` · `transferencia` |
| cantidad | DECIMAL(10,2) | |
| ot_id | UUID | FK, nullable |
| orden_compra_id | UUID | FK, nullable |
| usuario_id | UUID | FK |
| fecha | TIMESTAMPTZ | |
| origen | VARCHAR(50) | compra, OC, transferencia… |
| notas | TEXT | nullable |

### SolicitudMaterial

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| ot_id | UUID | FK → OrdenTrabajo |
| material_id | UUID | FK → Material |
| cantidad_solicitada | DECIMAL(10,2) | |
| estado | ENUM | `pendiente` · `aprobado` · `rechazado` |
| pañolero_id | UUID | FK → Usuario, nullable |
| fecha_solicitud | TIMESTAMPTZ | |
| fecha_resolucion | TIMESTAMPTZ | nullable |
| motivo_rechazo | TEXT | nullable |

### Herramienta

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| nombre | VARCHAR(200) | |
| codigo | VARCHAR(50) | |
| pañol_id | UUID | FK |
| activa | BOOLEAN | |

### PrestamoHerramienta

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| herramienta_id | UUID | FK |
| usuario_id | UUID | FK (quien retira) |
| ot_id | UUID | FK, nullable |
| fecha_retiro | TIMESTAMPTZ | |
| fecha_devolucion | TIMESTAMPTZ | nullable |
| estado | ENUM | `prestada` · `devuelta` |

---

## M5 — Compras

### Proveedor

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| nombre | VARCHAR(200) | |
| cuit | VARCHAR(20) | nullable |
| contacto | VARCHAR(200) | nullable |
| calificacion | DECIMAL(3,1) | nullable, post OC |
| activo | BOOLEAN | |

### OrdenCompra

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| numero | SERIAL | |
| sucursal_id | UUID | FK |
| proveedor_id | UUID | FK |
| estado | ENUM | `solicitada` · `autorizada` · `no_autorizada` · `anulada` |
| monto_total | DECIMAL(15,2) | |
| autorizado_por | UUID | FK → Usuario, nullable |
| fecha_solicitud | TIMESTAMPTZ | |
| fecha_autorizacion | TIMESTAMPTZ | nullable |
| notas | TEXT | nullable |

### OrdenCompraDetalle

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| orden_compra_id | UUID | FK |
| material_id | UUID | FK |
| cantidad | DECIMAL(10,2) | |
| precio_unitario | DECIMAL(15,2) | |

### ValeConsumo

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| sucursal_id | UUID | FK |
| ot_id | UUID | FK |
| materiales | JSONB | Detalle de materiales consumidos |
| fecha | TIMESTAMPTZ | |
| impreso | BOOLEAN | default false |

---

## M6 — Indicadores (vistas / materializadas)

No son tablas transaccionales. Se alimentan de M3 y M4.

### Vista: indices_equipo

| Campo | Tipo | Fórmula |
|-------|------|---------|
| equipo_id | UUID | |
| tmef | DECIMAL | Hs. Funcionamiento / Cant. OT Correctivas |
| tmpr | DECIMAL | Hs. Indisp. correctivas / Cant. OT Correctivas |
| temp | DECIMAL | Hs. Funcionamiento / Cant. OT Preventivas |
| tpmp | DECIMAL | Hs. Indisp. preventivas / Cant. OT Preventivas |
| imc | DECIMAL | % tiempo en correctivo |
| imp | DECIMAL | % tiempo en preventivo |
| ico | DECIMAL | (Hs. Func. − Hs. Indisp.) / Hs. Func. |
| icm | DECIMAL | Costo Mant. / Costo Reposición |

---

## M7 — Notificaciones

### Notificacion

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| usuario_id | UUID | FK → destinatario |
| tipo | VARCHAR(50) | ot_asignada, material_solicitado, etc. |
| titulo | VARCHAR(200) | |
| cuerpo | TEXT | |
| entidad_tipo | VARCHAR(50) | ot, solicitud_material, orden_compra… |
| entidad_id | UUID | ID de la entidad relacionada |
| leida | BOOLEAN | default false |
| enviada_push | BOOLEAN | default false |
| created_at | TIMESTAMPTZ | |

### DispositivoFCM

| Campo | Tipo | Notas |
|-------|------|-------|
| id | UUID | PK |
| usuario_id | UUID | FK |
| token | VARCHAR(500) | FCM token |
| plataforma | ENUM | `android` · `web` |
| activo | BOOLEAN | |
| updated_at | TIMESTAMPTZ | |

---

## Catálogos generales (M2/M3)

Entidades simples: `id`, `nombre`, `activo`. Algunas con campos extra.

| Catálogo | Campos extra |
|----------|-------------|
| TipoProcedimiento | — |
| Procedimiento (tipo) | — |
| Evento | — |
| Tarea | — |
| MotivoOTPendiente | — |
| Unidad | símbolo |
| Destino | — |
| Condicion | — |
| IVA | porcentaje |
| Provincia | pais_id |
| Pais | — |
| Causa | — |
| Objeto | — |
| Sintoma | — |
| Accion | — |
| Rubro | — |
| ManoDeObra | costo_hora |
| Recurso | costo |
| Responsable | — |
