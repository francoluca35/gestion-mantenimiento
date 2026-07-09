# Paridad SGwing — checklist por pantalla

Checklist imagen a imagen contra el documento visual de referencia de Sika.

**Fuente:** [`docs/images/Sistema_SGwing.md`](../images/Sistema_SGwing.md) (capturas `sgwing-01` … `sgwing-32`)

**Leyenda:** ✅ Listo · 🟡 Parcial · ❌ Falta · 🚀 Mejora pedida por Sika (no existía igual en SGMWin)

**Última revisión:** 2026-07-08

---

## Resumen por bloque

| Bloque | Pantallas | Paridad | Prioridad siguiente |
|--------|-----------|---------|---------------------|
| Procedimientos | 01–07 | 🟡 ~55% | Diálogo asociar completo, búsqueda avanzada |
| Equipos | 08–15 | 🟡 ~50% | Proc. asociados por nodo, documentos, reportes |
| OT / Programación | 16–32 | 🟡 ~75% | Filtros avanzados, columnas extendidas (P1) |

---

## Procedimientos (01–07)

| # | Captura | Función SGwing | Ruta / API | Estado | Prioridad |
|---|---------|----------------|------------|--------|-----------|
| 01 | `sgwing-01` | Buscar por descripción o código | `/procedimientos` | 🟡 | P2 |
| 02 | `sgwing-02` | Búsqueda avanzada (sector, tipo, etc.) | — | ❌ | P2 |
| 03 | `sgwing-03` | Agregar procedimiento (form completo) | `/procedimientos` | 🟡 | P2 |
| 04 | `sgwing-04` | Reservar materiales | placeholder | ❌ | P1 (M4) |
| 05 | `sgwing-05` | Resultado: Excel, modificar, eliminar, asociar si preventivo | `/procedimientos` | 🟡 | P2 |
| 06 | `sgwing-06` | Asociar a planta / sector / equipo + imprimir OT + emitir OT | mapa + `asociar-equipo` / `asociar-alcance` | 🟡 | **P0** |
| 07 | `sgwing-07` | Versiones del procedimiento | — | ❌ | P3 |

### Detalle 06 — asociar procedimiento

| Ítem | Estado |
|------|--------|
| Seleccionar **planta** sin expandir equipos | ✅ `procedimiento_alcances` + picker |
| Seleccionar **sector** sin expandir equipos | ✅ |
| Seleccionar **equipo** individual | ✅ |
| Varios procedimientos por misma máquina | ✅ |
| Emitir primera OT al asociar (solo equipos nuevos) | 🟡 |
| Imprimir OT / copias desde diálogo | ❌ |
| Columna habilitado / fecha programación en grilla asociados | ❌ |

---

## Equipos (08–15)

| # | Captura | Función SGwing | Ruta / API | Estado | Prioridad |
|---|---------|----------------|------------|--------|-----------|
| 08 | `sgwing-08` | Mapa planta SIKA → sector → equipo | `/planta` | ✅ | — |
| 09 | `sgwing-09` | Toolbar: agregar, modificar, eliminar, listar, copiar, mover, pegar | `/planta` | 🟡 | P2 |
| 10 | `sgwing-10` | Historial OT y procedimientos | tab Historial + `GET equipos/:id/historial` | 🟡 | P2 |
| 11 | `sgwing-11` | Agregar equipo con campos opcionales dinámicos | `/planta` | 🟡 | P1 |
| 12 | `sgwing-12` | Reportes / impresión con vista previa | — | ❌ | P1 |
| 13 | `sgwing-13` | Procedimientos asociados desde equipo/sector | tab Procedimientos | 🟡 | **P0** |
| 14 | `sgwing-14` | En planta: solo proc. de **esa** planta (no todos) | alcance API sí; filtro UI | 🟡 | **P0** |
| 15 | `sgwing-15` | Documentos (planos, videos, informes) | — | ❌ | P1 |
| — | — | Repuestos por equipo | — | ❌ | P2 (M4) |

### Detalle 09 — toolbar equipo

| Acción | Estado |
|--------|--------|
| Agregar | ✅ |
| Modificar | 🟡 |
| Eliminar / baja | ❌ |
| Listar / imprimir | ❌ |
| Copiar / pegar | ❌ |
| Mover | 🟡 API |
| Fuera de servicio | ✅ |

---

## Órdenes de trabajo (16–32)

### Buscar OT (16–22)

| # | Captura | Función SGwing | Ruta / API | Estado | Prioridad |
|---|---------|----------------|------------|--------|-----------|
| 16 | `sgwing-16` | Buscar OT con **mapa**; lupa por planta/sector | `/ot` | ✅ | — |
| 17 | `sgwing-17` | Colores: verde realizada, rojo pendiente, amarillo ejecución | `/ot` | ✅ | — |
| 18–21 | `sgwing-18`–`21` | Toolbars OT (acciones múltiples) | `/ot` | 🟡 | P1 |
| 20 | `sgwing-20` | Columnas extendidas (motivo, recibe, GUT, HH real…) | `/ot` | 🟡 | P1 |
| 22 | `sgwing-22` | Filtros: fechas, sector, tipo equipo, motivo, recibe… | `/ot` | 🟡 | P1 |
| — | — | Listar OT (vista previa / imprimir) | — | ❌ | P1 |

### Programación avanzada (23–25)

| # | Captura | Función SGwing | Ruta / API | Estado | Prioridad |
|---|---------|----------------|------------|--------|-----------|
| 23 | `sgwing-23` | Diagrama de Gantt | — | ❌ | P2 |
| 24 | `sgwing-24` | OT derivada | — | ❌ | P2 |
| 25 | `sgwing-25` | OT no periódica: sector/equipo, fechas, recibe, responsable | `/ot/emitir-no-periodica` | 🟡 | P1 |

### Solicitudes y contadores (26–29)

| # | Captura | Función SGwing | Ruta / API | Estado | Prioridad |
|---|---------|----------------|------------|--------|-----------|
| 26 | `sgwing-26` | Listado solicitudes + acciones | `/solicitudes` | 🟡 | P2 |
| 27 | `sgwing-27` | Detalle solicitud | `/solicitudes` | ✅ | — |
| 28 | `sgwing-28` | Estado / conformidad | `/solicitudes` | ✅ | — |
| 29 | `sgwing-29` | Contadores: gráfico, reiniciar (clave admin) | `/contadores` | 🟡 | P1 |

### OT necesarias (30–32)

| # | Captura | Función SGwing | Ruta / API | Estado | Prioridad |
|---|---------|----------------|------------|--------|-----------|
| 30 | `sgwing-30` | Mapa para elegir ámbito de OT periódicas | `/ot/necesarias` | ✅ | — |
| 31 | `sgwing-31` | Lupa → próximas; emitir lote; técnico; push; PDF; select all | `/ot/necesarias` | 🟡 | push diferido |
| 32 | `sgwing-32` | Al seleccionar OT, mapa lateral sector/máquina | `/ot` | ✅ | — |

---

## Mejoras pedidas por Sika (documento SGwing)

| Mejora | Pantallas | Estado | Prioridad |
|--------|-----------|--------|-----------|
| Notificar técnico al asignar “recibe” | 25, 31 | 🟡 diferido | Código listo; FCM Android + service account |
| PDF para tercerizados / impresión selectiva | 12, 31 | ✅ HTML | Plantilla SGwing imprimible |
| Colores OT: verde / rojo / amarillo | 17 | ✅ | `ot_ui.dart` |
| Mapa contextual en búsqueda y detalle OT | 16, 32 | ✅ | `PlantaMapPanel` en `/ot` |
| Vista previa antes de emitir OT necesarias | 31 | ✅ | Diálogo previo a emisión |
| Gantt de OT posibles | 23, 31 | ❌ | P2 |

---

## Priorización recomendada (Ola 2 — SGwing UX)

Orden sugerido para máximo impacto operativo en Planta Virrey.

### Sprint A — Mapa y OT (2–3 semanas) **P0**

0. **Shell móvil** — conectar `AdaptiveScaffold`: bottom nav por rol en `<600px`, sidebar en `≥900px`.
1. **Mapa en Buscar OT** (16): panel lateral planta → filtrar listado con lupa.
2. **Mapa en detalle OT** (32): resaltar sector/equipo al seleccionar fila.
3. **Mapa en OT necesarias** (30): reemplazar dropdowns por picker visual.
4. **Colores de estado OT** (17): realizada verde, pendiente rojo, ejecución amarillo.
5. **OT necesarias — emisión mejorada** (31): vista previa, asignar técnico por fila, select all.

### Sprint B — Comunicación sin papel (2 semanas) **P0–P1**

6. **PDF de OT** (12, 31): plantilla con checklist / planilla lecturas.
7. **Push al asignar técnico** (25, 31): M7 FCM.
8. **Campo “recibe”** en OT no periódica y emisión desde necesarias.

### Sprint C — Paridad procedimientos / equipos (2 semanas) **P0–P1**

9. **Procedimientos asociados filtrados por nodo** (13, 14): planta vs sector vs equipo.
10. **Diálogo asociar procedimiento** (06): habilitado, fecha 1ª programación, opciones impresión.
11. **Campos dinámicos** al agregar equipo (11).
12. **Contadores**: gráfico + reinicio con clave admin (29).

### Sprint D — Profundidad OT (2–3 semanas) **P1**

13. Filtros avanzados OT (22) + rango de fechas.
14. Columnas OT prioritarias (20): motivo, recibe, HH real, fechas inicio/fin.
15. Listar / exportar OT (Excel o CSV).
16. OT no periódica: sector como destino, fechas inicio/fin.

### Sprint E — Fase 2 plataforma **P1–P2**

17. Reserva materiales (04) → M4 Pañol.
18. Documentos de equipo (15) → storage.
19. Gantt (23) + OT derivada (24).
20. Búsqueda avanzada procedimientos (02), versiones (07).

### Más adelante **P2–P3**

- Copiar/pegar equipo, baja con validaciones, repuestos.
- Cron emisión automática OT periódicas.
- App Android — todos los roles (flujos por permiso; técnico offline en Fase 3).
- M4/M5/M6 completos.

---

## Criterios de aceptación Ola 2 (SGwing)

- [x] Supervisor abre `/ot`, selecciona **PLANTA_VIRREY** en mapa, pulsa buscar → ve solo OT de esa planta.
- [x] Al clic en una OT, el mapa marca el sector/equipo correspondiente.
- [x] `/ot/necesarias` usa el mismo mapa que procedimientos; emite lote con técnico asignado.
- [x] Estados OT con colores acordados (verde/rojo/amarillo).
- [x] PDF descargable de una OT emitida (HTML imprimible).
- [ ] Técnico recibe notificación al ser asignado — **diferido** (FCM Android).
- [x] En `/planta`, al seleccionar planta, procedimientos asociados muestran solo alcance planta.

**Smoke test API:** `node tools/smoke-ola2.mjs` — 12/12 OK (2026-07-08).

---

## Referencias cruzadas

| Documento | Uso |
|-----------|-----|
| [`00-estado-proyecto.md`](../00-estado-proyecto.md) | **Hecho / falta / mejoras** — documento maestro |
| [`MATRIZ-PARIDAD.md`](../referencias/MATRIZ-PARIDAD.md) | Paridad manual SGMWin capítulo a capítulo |
| [`Sistema_SGwing.md`](../images/Sistema_SGwing.md) | Texto + enlaces a capturas |
| [`m3-mantenimiento.md`](m3-mantenimiento.md) | Estado técnico M3 |
| [`09-roadmap.md`](../09-roadmap.md) | Fases del proyecto |

---

## Mantenimiento

1. Al cerrar un ítem, actualizar la fila y la checklist de aceptación.
2. Vincular PRs con ID `sgwing-XX` (ej. `sgwing-16-mapa-buscar-ot`).
3. Si cambian las capturas, actualizar `docs/images/Sistema_SGwing.md` y este archivo.
