# Faltantes — Módulo 3 (Mantenimiento)

Estado actual: **Ola 1 cerrada** · Demo Planta Virrey · Web Flutter operativo.

**Estado global:** [`../00-estado-proyecto.md`](../00-estado-proyecto.md)  
**Paridad visual Sika:** [`sgwing-paridad.md`](sgwing-paridad.md) (32 pantallas en `docs/images/`)

---

## Qué ya está

### Backend

- Tablas: `procedimientos`, `procedimiento_equipos`, `procedimiento_alcances`, `ordenes_trabajo`, `ot_estado_historial`, `solicitudes_trabajo`, `historial_equipo`
- CRUD procedimientos + asociar equipo + asociar alcance (planta/sector)
- `GET /ot/necesarias` con lógica periodicidad + `POST /ot/necesarias/emitir`
- Emitir OT manual, asignar técnico, cambiar estado
- Checklist, firma y cierre de OT
- Anular OT
- Solicitudes: crear, conformidad con calificación, emitir OT
- Resumen dashboard (`GET /ot/resumen`)
- Timeline de estados por OT
- Historial de equipo + procedimientos por equipo
- Campos Ola 1: `observaciones` procedimiento/solicitud, `planillaLecturas`

### Seed demo (Planta Virrey)

- Árbol: Silos Externos → Sector Losa → SILO-103/104, Molienda → MOL-01
- 2 procedimientos (preventivo + correctivo)
- OT #1001 pendiente, #1002 en ejecución, #1003 realizada
- 2 solicitudes de trabajo (pendiente + conformada)
- SILO-104 con OT realizada hace 40 días → aparece en necesarias

### Flutter Web

| Ruta | Estado |
|------|--------|
| `/procedimientos` | Formulario, asociaciones equipo/sector/planta, planilla, observaciones |
| `/planta` | Explorer + ficha tabs (general, lecturas, historial, procedimientos, fuera servicio) |
| `/ot` | Listado, filtros, detalle, ciclo de vida técnico |
| `/ot/necesarias` | Lista + emisión masiva |
| `/ot/emitir-no-periodica` | Mapa de planta |
| `/solicitudes` | Master-detail, conformidad, emitir OT con mapa |
| `/contadores` | Listado equipos |
| `/home` | Métricas OT |

---

## Ola 2 — Prioridad SGwing (siguiente)

Ver detalle en [`sgwing-paridad.md`](sgwing-paridad.md). Resumen P0:

| # | Ítem | Pantalla SGwing |
|---|------|-----------------|
| 1 | Mapa en Buscar OT + mapa en detalle | 16, 32 |
| 2 | Mapa en OT necesarias + vista previa + técnico | 30, 31 |
| 3 | Colores OT verde/rojo/amarillo | 17 |
| 4 | PDF OT | 12, 31 |
| 5 | Push al asignar técnico | 25, 31 |
| 6 | Procedimientos asociados filtrados por nodo planta/sector | 14 |

---

## Qué falta (resto)

| Ítem | Prioridad |
|------|-----------|
| Filtros avanzados OT (fechas, sector, motivo…) | P1 |
| Columnas OT extendidas (recibe, GUT, HH real…) | P1 |
| OT derivada | P2 |
| Gantt programación | P2 |
| Reserva materiales en procedimiento | P1 (M4) |
| Búsqueda avanzada procedimientos | P2 |
| Versiones / histórico procedimiento | P3 |
| Documentos adjuntos equipo | P1 |
| Contadores: gráfico + reinicio admin | P1 |
| Emisión automática cron | P2 |
| Emisión por contador/umbral | P2 |
| Fotos en OT | P1 |
| Mano de obra y materiales en OT | P1 (M4) |
| Flutter Android flujo técnico | P0 (paralelo Sprint B) |
| Shell móvil global (`AdaptiveScaffold` + bottom nav por rol) | P0 |
| Vistas móviles supervisor / gerencia | P1 |
| Offline + sync OT | Fase 3 |
| RLS PostgreSQL M3 | Alta (prod) |
| Tests e2e OT | Media |

---

## Demo sugerida (5 min)

1. Login `supervisor` / `Sika123!`
2. `/procedimientos` → asociar procedimiento a **PLANTA_VIRREY** o sector
3. `/ot/necesarias` → ver SILO-104 vencido → emitir
4. `/solicitudes` → conformar pendiente → emitir OT con mapa
5. Logout → `tecnico` → `/ot` → cerrar OT en ejecución

---

## Referencias

- [`sgwing-paridad.md`](sgwing-paridad.md) — checklist 32 pantallas
- [`../images/Sistema_SGwing.md`](../images/Sistema_SGwing.md) — documento visual Sika
- [`../referencias/MATRIZ-PARIDAD.md`](../referencias/MATRIZ-PARIDAD.md) — manual SGMWin
- [`../01-modulos.md`](../01-modulos.md) — alcance M3
- [`../09-roadmap.md`](../09-roadmap.md) — fases
