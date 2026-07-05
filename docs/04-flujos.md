# 04 — Flujos de negocio

Procesos del sistema, no pantallas. Cada flujo define: actores, estados, transiciones y eventos de notificación.

---

## F1 — Emisión de OT periódica (automática)

**Actor:** Sistema (cron backend)
**Trigger:** Periodicidad de tiempo o umbral de contador

```mermaid
sequenceDiagram
    participant Cron as Cron Backend
    participant API as NestJS
    participant DB as PostgreSQL
    participant FCM as Firebase FCM
    participant Tec as Técnico (Android)

    Cron->>API: Revisar ProcedimientoEquipo activos
    API->>DB: Consultar última emisión + periodicidad
    alt Periodicidad cumplida
        API->>DB: Crear OrdenTrabajo (estado: pendiente)
        API->>DB: Actualizar ultima_emision
        API->>FCM: Push "Nueva OT asignada"
        FCM->>Tec: Notificación
    end
```

**Mejora vs SGMWin:** En el original esto corre en un PC prendido. Acá corre en la nube.

---

## F2 — Emisión de OT manual / no periódica

**Actores:** Derivador OT, Supervisor

```
1. Seleccionar equipo (árbol de ubicaciones)
2. Seleccionar procedimiento (o crear correctiva libre)
3. Definir fecha programación, técnico, prioridad
4. Verificar stock de materiales (si aplica)
   ├── Stock OK → estado: pendiente
   └── Falta stock → estado: pendiente_pañol
5. Notificar técnico (push)
```

---

## F3 — Solicitud de Trabajo → OT

**Actores:** Solicitante externo, Supervisor

```mermaid
stateDiagram-v2
    [*] --> pendiente: Crear solicitud
    pendiente --> conformada: Supervisor da conformidad
    pendiente --> rechazada: Supervisor rechaza
    conformada --> [*]: Se emite OT (F2)
    rechazada --> [*]
```

Si `urgente = true` → push al supervisor inmediato.

---

## F4 — Ciclo de vida de OT (completo)

```mermaid
stateDiagram-v2
    [*] --> necesaria_de_emitir: Procedimiento vence
    necesaria_de_emitir --> pendiente: Emitir y asignar
    pendiente --> pendiente_pañol: Técnico solicita materiales
    pendiente_pañol --> pendiente: Pañolero aprueba
    pendiente_pañol --> pendiente: Pañolero rechaza (reintento)
    pendiente --> en_ejecucion: Técnico inicia ejecución
    en_ejecucion --> realizada: Técnico cierra (checklist + firma)
    pendiente --> anulada: Supervisor anula
    en_ejecucion --> anulada: Supervisor anula
    realizada --> pendiente: Admin reabre
```

### Ejecución en campo (Android)

```
1. Técnico abre OT asignada
2. Completa checklist (planilla de lecturas)
3. Registra lecturas de contadores
4. Carga mano de obra (horas normales/extra)
5. Solicita materiales (si no lo hizo antes) → F5
6. Toma fotos
7. Firma digital
8. Marca como realizada
9. Stock se actualiza automáticamente
10. HistorialEquipo se genera
```

---

## F5 — Flujo OT + Pañol (aprobación de materiales)

**Actores:** Técnico, Pañolero
**Nuevo respecto a SGMWin**

```mermaid
sequenceDiagram
    participant Tec as Técnico
    participant API as NestJS
    participant DB as PostgreSQL
    participant FCM as FCM
    participant Pan as Pañolero

    Tec->>API: Solicitar materiales para OT
    API->>DB: Crear SolicitudMaterial (pendiente)
    API->>FCM: Push al pañolero
    FCM->>Pan: "Solicitud de materiales OT #1234"

    alt Aprueba
        Pan->>API: Aprobar solicitud
        API->>DB: Verificar stock disponible
        API->>DB: Reservar stock (MovimientoStock tipo: reserva)
        API->>DB: SolicitudMaterial → aprobado
        API->>DB: OT → pendiente (o en_ejecucion)
        API->>FCM: Push al técnico "Materiales aprobados"
    else Rechaza
        Pan->>API: Rechazar con motivo
        API->>DB: SolicitudMaterial → rechazado
        API->>FCM: Push al técnico "Materiales rechazados"
        Note over Tec: Puede reintentar con otro material
    end

    Tec->>API: Retirar materiales reservados
    API->>DB: MovimientoStock tipo: salida
    API->>DB: Actualizar cantidad_actual y cantidad_reservada
```

---

## F6 — Alerta stock mínimo

**Actor:** Sistema
**Trigger:** `cantidad_actual - cantidad_reservada < cantidad_minima`

```
1. Job periódico revisa StockItem
2. Si stock bajo mínimo → crear Notificacion
3. Push al pañolero
4. Si OT pendiente depende de ese material → alerta preventiva
```

---

## F7 — Orden de Compra

**Actores:** Solicitante, Autorizador (con `monto_maximo_oc`)

```mermaid
stateDiagram-v2
    [*] --> solicitada: Crear OC
    solicitada --> autorizada: Autorizador aprueba (monto ≤ tope)
    solicitada --> no_autorizada: Autorizador rechaza
    autorizada --> [*]: Recepción → MovimientoStock entrada
    solicitada --> anulada: Anular
    no_autorizada --> [*]
```

Si `monto_total > umbral_configurado` → push al gerente.

---

## F8 — Emisión automática de OT (cron)

**Frecuencia:** Diario (configurable por sucursal)

```
Para cada ProcedimientoEquipo activo:
  1. Calcular próxima fecha según periodicidad_tipo:
     - tiempo: ultima_emision + periodicidad_valor días
     - contador: última lectura + periodicidad_valor unidades
  2. Si vencido → crear OT con estado necesaria_de_emitir
  3. Si auto_emitir configurado → pasar a pendiente y asignar
  4. Notificar técnico y supervisor
```

---

## F9 — Cálculo de índices (KPIs)

**Actor:** Sistema (job nocturno)
**Esquema:** `analytics`

```
1. Job corre en horario de baja carga (ej: 02:00)
2. Lee datos de orden_trabajo, lectura, ot_mano_obra
3. Calcula por equipo: TMEF, TMPR, TEMP, TPMP, IMC, IMP, ICO, ICM
4. Materializa en analytics.indices_equipo
5. Dashboard lee de analytics (sin impactar transaccional)
```

---

## F10 — Sincronización offline (Fase 3)

**Actor:** Técnico en zona sin señal

```mermaid
sequenceDiagram
    participant App as Flutter Android
    participant SQLite as SQLite local
    participant API as NestJS
    participant DB as PostgreSQL

    Note over App,SQLite: Sin conexión
    App->>SQLite: Guardar checklist, fotos, firma en cola
    App->>SQLite: Marcar OT como "pendiente_sync"

    Note over App,API: Conexión recuperada
    App->>API: Enviar cola de cambios (batch)
    API->>DB: Aplicar cambios (con resolución de conflictos)
    API-->>App: Confirmar sync + datos actualizados
    App->>SQLite: Limpiar cola sincronizada
```

**Regla de conflictos:** El servidor gana (last-write-wins con timestamp del servidor).

---

## Resumen de flujos por fase

| Flujo | Fase | Módulos |
|-------|------|---------|
| F2 — OT manual | 1 | M2, M3, M7 |
| F4 — Ciclo OT (básico) | 1 | M3, M7 |
| F3 — Solicitud trabajo | 1 | M3 |
| F5 — Pañol aprobación | 2 | M3, M4, M7 |
| F1 — OT automática | 2 | M3, M7 |
| F7 — Orden de compra | 2 | M5, M7 |
| F6 — Alerta stock | 2 | M4, M7 |
| F8 — Cron emisión | 2 | M3 |
| F9 — KPIs | 3 | M6 |
| F10 — Offline sync | 3 | M3 |
