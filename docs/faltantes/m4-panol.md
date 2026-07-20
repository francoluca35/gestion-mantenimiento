# Faltantes — Módulo 4 (Pañol)

**Estado:** 🟢 ~95% — cerrado para demo (2026-07-20)

**Estado global:** [`../00-estado-proyecto.md`](../00-estado-proyecto.md)

---

## Qué ya está

### Backend

- Schema Prisma: `Panol`, `Unidad`, `Material` (+ `uso`), `StockItem`, `MovimientoStock`, `SolicitudMaterial`, `PedidoStock`
- Migraciones `20260717180000_m4_panol` · `20260717190000_m4_panol_ui`
- Seed Virrey: Pañol Central + 10 materiales con uso + pedidos demo
- API:
  - `GET/POST/PATCH /v1/panoles`
  - `GET/POST/PATCH /v1/materiales` (+ unidades; create puede crear stock)
  - `GET/PATCH /v1/stock`, `POST/GET /v1/stock/movimientos`, `GET /v1/stock/alertas`
  - `GET/POST /v1/solicitudes-materiales` · aprobar / rechazar
  - `GET/POST/PATCH /v1/pedidos-stock` (PD-####; completar → entrada)
- Flujo OT: solicitar → `pendiente_panol` · aprobar → reserva · rechazar → `pendiente`
- **Cerrar OT (`realizada`)** → salida + libera reserva (`origen: ot_cierre`)
- **Anular OT** → libera reserva sin descontar físico (`origen: ot_anulada`)
- Cron diario 7:00 → push stock bajo mínimo (`STOCK_ALERT_CRON_ENABLED=false` para apagar)
- Push: nueva solicitud / rechazo / alerta mínimo

### Flutter — rol Pañolero

| Ruta | Contenido |
|------|-----------|
| `/panol` | Home pañol |
| `/panol/stock` | Tabla stock + bajo mínimo + EDITAR/AÑADIR/UTILIZAR |
| `/panol/pedidos` | Analizar / pedir stock + solicitudes OT |
| `/panol/seguimiento` | Historial de movimientos |
| Login `panolero` | Redirige a `/panol` (shell propio) |

También: sheet «Solicitar materiales» desde OT / Mis OT.

### Derechos

- `stock.pañol.solicitudes_materiales.*`
- `stock.pañol.alertas_stock_minimo.*`
- Perfil pañolero: `stock.*` modo total

---

## Diferido (post-M4 / M5)

| Ítem | Prioridad | Notas |
|------|-----------|--------|
| Herramientas / préstamos | Baja | |
| Transferencia entre pañoles | Media | Enum ya existe |
| Reserva automática al emitir OT | Media | Configurable SGMWin |
| M5 Órdenes de compra | — | Reposición formal |
| Mano de obra HH en OT | — | Extensión OT |

---

## Demo rápida

1. `panolero` / `Sika123!` → STOCK / PEDIDOS / SEGUIMIENTO
2. STOCK → Añadir / Utilizar / ver bajo mínimo
3. PEDIDOS → Analizar → Pedir stock → Completar pedido
4. `tecnico` → Mis OT → Solicitar materiales → `panolero` aprueba
5. Técnico cierra OT → stock baja (movimiento `ot_cierre`)
