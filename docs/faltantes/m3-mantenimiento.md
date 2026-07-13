# Faltantes — Módulo 3 (Mantenimiento)

Estado actual: **módulo cerrado para desarrollo** (~95%).

**Estado global:** [`../00-estado-proyecto.md`](../00-estado-proyecto.md)  
**Paridad visual Sika:** [`sgwing-paridad.md`](sgwing-paridad.md)

---

## Qué ya está

### Backend

- Ciclo de vida OT completo (emitir, asignar, ejecutar, checklist, firma, anular, reabrir)
- `GET /ot` con filtros: fechas, estado, tipo, técnico, equipo, ubicación, **prioridad, nº OT, sector, motivo, tipo equipo**
- `GET /ot/necesarias` por **tiempo** y **contador/umbral**
- `POST /ot/necesarias/emitir` + **cron diario** (`OtCronService`, 6:00 AM)
- `PATCH /ot/:id/motivo-pendiente` — asignar motivo de pendiente
- `GET/POST/PATCH/DELETE /motivos-ot-pendiente` — catálogo de motivos
- `POST /ot/:id/derivar` — OT derivada correctiva
- Procedimientos CRUD + asociaciones + periodicidad tiempo/contador
- Solicitudes de trabajo + conformidad + emitir OT
- PDF OT (HTML imprimible)
- Fotos en ejecución (`fotos` JSONB + presign)
- FCM push (código listo; requiere service account + Android)
- Tests e2e: `apps/api/test/ot.e2e-spec.ts` (4/4)

### Flutter

| Ruta | Estado |
|------|--------|
| `/ot` | Filtros avanzados, GUT estimada, mapa, derivar OT, **toolbar masivo**, **export CSV**, **vista previa / imprimir** |
| `/ot/necesarias` | Mapa, select-all, técnico por fila, vista previa |
| `/ot/emitir-no-periodica` | Equipo en mapa, fechas inicio/límite, recibe, PDF |
| `/solicitudes` | Master-detail + conformidad |
| `/procedimientos` | Periodicidad tiempo **y contador** |
| `/contadores` | Gráfico por equipo + reinicio con clave admin |
| `/mis-ot` | Flujo técnico móvil |

---

## Qué falta (post-M3 / otros módulos)

| Ítem | Prioridad | Notas |
|------|-----------|-------|
| FCM push real en Android | Media | Config `.env` Firebase |
| Gantt programación | P2 | Mejor en M6 |
| Búsqueda avanzada procedimientos | — | ✅ Sprint 1: filtros tipo/sector/periodicidad/tipo equipo + texto |
| Toolbar procedimientos + export CSV | — | ✅ Sprint 1 |
| Versiones / histórico procedimiento | P3 | |
| Mano de obra y materiales en OT | M4 | Pañol |
| Reserva materiales | M4 | |
| Offline + sync | Fase 3 | |
| Columnas GUT/HH real (schema) | P2 | Requiere migración |

---

## Demo sugerida (5 min)

1. `supervisor` → `/ot` → filtros por prioridad/sector/motivo pendiente
2. Seleccionar varias OT → toolbar → reasignar / motivo pendiente / export CSV
3. `/ot/necesarias` → emitir SILO-104 vencido
4. OT realizada → **OT derivada**
5. `/contadores` → expandir equipo → gráfico → reiniciar (admin)

---

## Referencias

- [`sgwing-paridad.md`](sgwing-paridad.md)
- [`../01-modulos.md`](../01-modulos.md)
