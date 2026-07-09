# Faltantes — Módulo 2 (Planta)

Estado actual: **módulo cerrado para desarrollo** (~95%).

**Estado global:** [`../00-estado-proyecto.md`](../00-estado-proyecto.md)

---

## Qué ya está

### Backend

- Tablas: `ubicaciones`, `tipos_equipo`, `equipos`, `componentes`, `lecturas`, `historial_equipo`, `equipo_documentos`
- CRUD ubicaciones (crear, editar, borrar, mover) + equipos (crear, editar, mover, fuera de servicio)
- **Componentes:** `GET/POST/PATCH/DELETE equipos/:id/componentes`
- **Copiar equipo:** `POST equipos/:id/duplicar`, `POST equipos/:id/pegar-componentes`
- Lecturas por equipo (`POST` con `archivos.equipos.modificar`)
- Documentos adjuntos: `GET/POST/DELETE equipos/:id/documentos` + storage presign
- Procedimientos por alcance planta/sector/equipo
- RLS PostgreSQL por sucursal (desde M1)
- Tests e2e: `apps/api/test/planta.e2e-spec.ts`

### Flutter

- `/planta` — explorador + stats + detalle
- Menú contextual: editar / mover / eliminar ubicaciones y equipos
- **Toolbar SGwing:** copiar, cortar, pegar, buscar máquina, imprimir (vista previa HTML), export CSV, acciones sector/equipo
- **Reportes:** `PlantaPrint` — listado imprimible con paleta Sika (sgwing-12)
- **Documentos:** adjuntar, abrir en navegador, iconos por tipo (sgwing-15)
- **Drag & drop** visual para mover equipos y ubicaciones en el explorador
- Ficha máquina: General, **Componentes**, Lecturas, Historial, Procedimientos, Documentos
- Campos dinámicos `TipoEquipo.camposDetalle` en alta/edición
- Selector de planta para admin / supervisa sucursales
- Procedimientos filtrados por nodo (`_AlcanceProcedimientosSection`)
- `planta_map_panel` + picker para OT/solicitudes

---

## Qué falta (no bloquea M3)

| Ítem | Prioridad |
|------|-----------|
| Árbol derechos 1:1 completo | Media (M1) |
| Explorador colapsable (paridad UI reciente) | Baja |

---

## Referencias

- [`sgwing-paridad.md`](sgwing-paridad.md) — pantallas 08–15
- [`../01-modulos.md`](../01-modulos.md)
