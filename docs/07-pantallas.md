# 07 — Inventario de pantallas

Inventario de **vistas** necesarias, separadas por plataforma.
No copia las ventanas de SGMWin — define la experiencia moderna.

---

## Principio

**Un solo código Flutter** compila a Web y Android. **Todos los roles** usan ambas plataformas según su contexto (oficina vs planta). El acceso a módulos lo define el **perfil de derechos**, no el dispositivo.

| Plataforma | Ancho típico | Paradigma | Navegación |
|------------|--------------|-----------|------------|
| **Web / desktop** | ≥ 900px | Dashboard + sidebar + panel detalle | Sidebar colapsable, tablas densas, mapa lateral |
| **Tablet** | 600–900px | Híbrido | Rail compacto o split según pantalla |
| **Android / móvil** | < 600px | Flujo lineal por proceso | Bottom nav (3–4 ítems del rol), una acción por pantalla |

> Mismo dato, misma API, distinta presentación — no achicar el desktop.

Estado de implementación del shell: [`00-estado-proyecto.md`](00-estado-proyecto.md).

---

## Desktop — Flutter Web

### Layout base

```
┌──────────────────────────────────────────────────────────┐
│  Header: logo · sucursal · buscador global · 🔔 · usuario│
├────────┬─────────────────────────────┬───────────────────┤
│        │                             │                   │
│ Side   │   Vista principal           │  Panel detalle    │
│ bar    │   (tabla / kanban / tree)   │  (entidad         │
│        │                             │   seleccionada)   │
│ 📊 Dash│                             │                   │
│ 📁 Arch│                             │                   │
│ 📅 Prog│                             │                   │
│ 📦 Stoc│                             │                   │
│ 🛒 Comp│                             │                   │
│ 📈 Anal│                             │                   │
│ ⚙ Conf │                             │                   │
│        │                             │                   │
└────────┴─────────────────────────────┴───────────────────┘
```

### Pantallas por módulo

#### M1 — Seguridad / Configuración

| # | Vista | Tipo | Descripción |
|---|-------|------|-------------|
| D-01 | Login | Página completa | Usuario + clave, recordar sesión |
| D-02 | Usuarios | Tabla + panel | Lista con filtros, detalle lateral, CRUD |
| D-03 | Perfiles | Tabla + panel | Lista de perfiles, asignación de usuarios |
| D-04 | Editor de Derechos | Árbol checklist | Total/Parcial por nodo (sección 12 spec) |
| D-05 | Sucursales | Tabla + panel | CRUD sucursales, asignar usuarios |

#### M2 — Planta

| # | Vista | Tipo | Descripción |
|---|-------|------|-------------|
| D-10 | Árbol de Ubicaciones | Tree view | Drag & drop, agregar/modificar/mover nodos |
| D-11 | Equipos | Tabla + panel | Filtros por ubicación/tipo/estado, detalle con JSON dinámico |
| D-12 | Tipos de Equipo | Tabla + form | Editor de campos dinámicos (detalle + lecturas) |
| D-13 | Contadores | Gráfico + tabla | Evolución de lecturas por equipo |

#### M3 — Mantenimiento

| # | Vista | Tipo | Descripción |
|---|-------|------|-------------|
| D-20 | Dashboard OT | Dashboard | Cards: pendientes, en ejecución, vencidas, realizadas hoy |
| D-21 | Búsqueda de OT | Tabla avanzada | Filtros múltiples, columnas configurables, panel detalle |
| D-22 | Detalle OT | Panel / página | Info completa, timeline de estados, materiales, MO, fotos |
| D-23 | Emitir OT | Formulario | Wizard: equipo → procedimiento → programación → asignar |
| D-24 | OT necesarias de emitir | Tabla | Lista de procedimientos vencidos, emitir en lote |
| D-25 | Solicitudes de Trabajo | Tabla + panel | Conformidad, emitir OT desde solicitud |
| D-26 | Programación Gantt | Gantt chart | Programado vs realizado (Fase 3) |
| D-27 | Backlog | Gráfico línea | Evolución temporal (Fase 3) |

#### M4 — Pañol

| # | Vista | Tipo | Descripción |
|---|-------|------|-------------|
| D-30 | Stock por pañol | Tabla | Material, cantidad, mínimo, reservado, alertas |
| D-31 | Solicitudes materiales | Tabla + acciones | Pendientes con aprobar/rechazar inline |
| D-32 | Movimientos | Tabla filtrable | Historial de entradas/salidas/reservas |
| D-33 | Herramientas | Tabla | Estado prestada/disponible, historial |

#### M5 — Compras

| # | Vista | Tipo | Descripción |
|---|-------|------|-------------|
| D-40 | Órdenes de Compra | Tabla + panel | Estados, autorización, detalle |
| D-41 | Proveedores | Tabla + panel | Catálogo, calificación |
| D-42 | Vale de Consumo | Form + preview | Emitir e imprimir |

#### M6 — Indicadores

| # | Vista | Tipo | Descripción |
|---|-------|------|-------------|
| D-50 | Dashboard gerencial | Dashboard | KPIs principales, cards, gráficos resumen |
| D-51 | Índices de gestión | Tabla + gráficos | TMEF, TMPR, ICO, etc. por equipo |
| D-52 | Pareto de fallas | Gráfico barras | Por causa/síntoma |
| D-53 | Costos | Tabla + gráfico | Por equipo, sector, período |
| D-54 | Horas hombre | Gráfico barras | Por mes y tipo de trabajo |

---

## Android — Flutter

### Layout base

```
┌─────────────────────┐
│  AppBar + 🔔        │
├─────────────────────┤
│                     │
│   Contenido         │
│   (una acción       │
│    por pantalla)    │
│                     │
├─────────────────────┤
│  Bottom Nav (3-4)   │
│  🏠  📋  📦  👤    │
└─────────────────────┘
```

### Pantallas por rol

#### Técnico

| # | Vista | Flujo |
|---|-------|-------|
| A-01 | Inicio | Cards: OT pendientes (badge), OT en ejecución, notificaciones |
| A-02 | Mis OT | Lista vertical con estado, prioridad, fecha, equipo |
| A-03 | Detalle OT | Info del equipo, procedimiento, ubicación, estado |
| A-04 | Checklist | Planilla de lecturas paso a paso, campos dinámicos |
| A-05 | Lecturas | Registrar contadores del equipo |
| A-06 | Solicitar materiales | Buscar material, cantidad, enviar solicitud |
| A-07 | Fotos | Cámara + galería de fotos adjuntas |
| A-08 | Firma | Canvas táctil para firma digital |
| A-09 | Cerrar OT | Resumen final + confirmar |
| A-10 | Mano de obra | Horas normales/extra/100%/200% |
| A-11 | Notificaciones | Lista de notificaciones con deep link a OT |

**Flujo principal:**
```
A-01 Inicio → A-02 Mis OT → A-03 Detalle → A-04 Checklist → A-07 Fotos → A-08 Firma → A-09 Cerrar
```

#### Pañolero

| # | Vista | Flujo |
|---|-------|-------|
| A-20 | Inicio pañol | Cards: solicitudes pendientes (badge), alertas stock |
| A-21 | Solicitudes materiales | Lista con aprobar/rechazar |
| A-22 | Detalle solicitud | OT vinculada, material, stock disponible |
| A-23 | Stock | Consulta rápida de stock por material |
| A-24 | Alertas stock mínimo | Lista de materiales bajo mínimo |
| A-25 | Movimientos | Registrar entrada/salida rápida |
| A-26 | Herramientas | Retiro/devolución con escaneo |

**Flujo principal:**
```
A-20 Inicio → A-21 Solicitudes → A-22 Detalle → Aprobar/Rechazar
```

#### Supervisor

| # | Vista | Web | Móvil |
|---|-------|-----|-------|
| A-30 | OT de mi sector | Tabla + mapa lateral | Lista → detalle |
| A-31 | Solicitudes trabajo | Master-detail | Conformidad rápida |
| A-32 | OT necesarias | Tabla + mapa | Lista + emitir lote |
| A-33 | Notificaciones | Panel header | Lista con deep link |

**Flujo móvil supervisor:**
```
A-30 Inicio → OT sector → Detalle → Asignar / PDF
           → Solicitudes → Conformar → Emitir OT
```

#### Administrador / gerencia

| # | Vista | Web | Móvil |
|---|-------|-----|-------|
| A-40 | Dashboard gerencial | D-50 completo | Cards KPI + alertas |
| A-41 | Usuarios / perfiles | D-02, D-03, D-04 | Consulta + acciones puntuales |
| A-42 | Config sucursal | D-05 | Solo lectura / alertas |
| A-43 | Todas las OT (multi-sucursal) | D-21 avanzado | Lista filtrada + notificaciones |

**Nota:** editor de derechos (D-04), Gantt y export masivo son **desktop-first**; en móvil se prioriza consulta y aprobaciones.

---

## Pantallas compartidas (ambas plataformas)

| # | Vista | Plataforma |
|---|-------|------------|
| S-01 | Login | Desktop + Android |
| S-02 | Perfil de usuario | Desktop + Android |
| S-03 | Configuración de notificaciones | Desktop + Android |
| S-04 | Selector de sucursal | Admin multi-sucursal (ambas plataformas) |

---

## Resumen por fase

Las mismas rutas API alimentan Web y Android. La columna **Android** indica vistas con layout móvil dedicado.

| Fase | Web (todos los roles con permiso) | Android (layouts móviles) |
|------|-----------------------------------|---------------------------|
| **1 — MVP** | D-01, D-02, D-05, D-10, D-11, D-20, D-21, D-22, D-23 | S-01, A-01–A-03, A-08, A-09, A-11, A-30–A-31 |
| **2** | D-24, D-25, D-30, D-31, D-40, D-42 | A-04–A-06, A-10, A-20–A-22, A-32–A-33, shell adaptativo |
| **3** | D-04, D-13, D-26, D-27, D-50–D-54 | A-07, A-23–A-26, A-40–A-43, offline |

**Total estimado:** ~35 vistas con layout desktop + ~28 con layout móvil (muchas comparten lógica y rutas).

Ver estado actual: [`00-estado-proyecto.md`](00-estado-proyecto.md).
