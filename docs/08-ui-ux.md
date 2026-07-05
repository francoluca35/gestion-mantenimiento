# 08 — Diseño UI/UX

Principios de diseño para la experiencia moderna. SGMWin es referencia funcional, no visual.

---

## Principios

1. **Procesos, no formularios** — Cada pantalla responde a una acción del flujo de negocio.
2. **Mobile-first por flujo** — Android es lineal (una acción); desktop es denso (tablas + panel).
3. **No responsive de desktop** — Dos layouts adaptativos, no la misma pantalla achicada.
4. **Mínimo y moderno** — Bordes redondeados, espaciado consistente, dark mode compatible.
5. **Accesible en planta** — Botones grandes, alto contraste, funciona con una mano y guantes.

---

## Design system

### Colores

| Token | Light | Dark | Uso |
|-------|-------|------|-----|
| `primary` | `#1E40AF` | `#3B82F6` | Acciones principales, links |
| `secondary` | `#64748B` | `#94A3B8` | Texto secundario, bordes |
| `success` | `#16A34A` | `#22C55E` | OT realizada, aprobado |
| `warning` | `#D97706` | `#F59E0B` | OT pendiente, stock bajo |
| `danger` | `#DC2626` | `#EF4444` | OT anulada, rechazado, urgente |
| `surface` | `#FFFFFF` | `#1E293B` | Fondo de cards |
| `background` | `#F8FAFC` | `#0F172A` | Fondo general |

### Tipografía

| Nivel | Desktop | Android | Peso |
|-------|---------|---------|------|
| H1 | 28px | 24px | 700 |
| H2 | 22px | 20px | 600 |
| Body | 14px | 16px | 400 |
| Caption | 12px | 14px | 400 |
| Botón mobile | — | 16px | 600 |

### Espaciado

Base: 4px. Escala: 4, 8, 12, 16, 24, 32, 48.

### Bordes

| Elemento | Radius |
|----------|--------|
| Cards | 12px |
| Botones | 8px |
| Inputs | 8px |
| Modales | 16px |
| Bottom nav (Android) | 0px top |

---

## Desktop — Patrones

### Dashboard (pantalla de inicio)

```
┌──────────────────────────────────────────────────────────┐
│  Buenos días, Juan · Planta Virrey · 4 jul 2026         │
├────────────┬────────────┬────────────┬────────────────────┤
│  🔴 12     │  🟡 8      │  🟢 45     │  📊 TMEF: 720h    │
│  Pendientes│  En ejec.  │  Realizadas│  ICO: 94.2%       │
│  hoy       │            │  este mes  │                   │
├────────────┴────────────┴────────────┴────────────────────┤
│                                                          │
│  ┌─ OT recientes ─────────────────────────────────────┐ │
│  │ #1234 · Preventivo · Silo 103 · Pendiente · 4 jul │ │
│  │ #1235 · Correctivo · Bomba B2 · En ejec. · 3 jul  │ │
│  │ #1236 · Preventivo · Filtro A1 · Realizada · 2 jul│ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─ Alertas ──────────┐  ┌─ Stock bajo mínimo ────────┐ │
│  │ 3 OT vencidas      │  │ Rodamiento 6205: 2 u.     │ │
│  │ 1 solicitud urgente│  │ Filtro HEPA: 0 u. ⚠️      │ │
│  └────────────────────┘  └───────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### Tabla con panel detalle (patrón principal)

Usado en: OT, equipos, stock, OC, usuarios.

```
┌─ Filtros ────────────────────────────────────────────────┐
│ Estado: [Pendiente ▾]  Tipo: [Todos ▾]  🔍 Buscar...   │
├──────────────────────────────────┬───────────────────────┤
│ # │ Equipo      │ Estado │ Fecha│  OT #1234            │
│───┼─────────────┼────────┼──────│  ─────────────────   │
│1234│ Silo 103   │ 🟡 Pen │ 4jul │  Tipo: Preventivo    │
│1235│ Bomba B2   │ 🔵 Ejec│ 3jul │  Equipo: Silo 103    │
│1236│ Filtro A1  │ 🟢 Rea │ 2jul │  Técnico: JPérez     │
│   │             │        │      │  Programada: 4 jul   │
│   │             │        │      │  ─────────────────   │
│   │             │        │      │  [Asignar] [PDF]     │
│   │             │        │      │  [Anular]            │
└──────────────────────────────────┴───────────────────────┘
```

### Árbol de ubicaciones

```
┌─ Ubicaciones ──────────────────────────────────────────┐
│  [+ Agregar nodo]                                      │
│                                                        │
│  📁 Planta Virrey                                      │
│  ├── 📁 Silos Externos                                  │
│  │   ├── 📁 Sector Losa                                │
│  │   │   ├── ⚙ Silo 103 Arena Fina L-24               │
│  │   │   └── ⚙ Silo 104 Arena Gruesa L-25             │
│  │   └── 📁 Sector Norte                               │
│  └── 📁 Planta Interna                                 │
│      └── 📁 Molienda                                   │
│          └── ⚙ Molino Principal M-01                   │
└────────────────────────────────────────────────────────┘
```

---

## Android — Patrones

### Inicio del técnico

```
┌─────────────────────┐
│  ☰  Mantenimiento 🔔│
├─────────────────────┤
│                     │
│  Hola, Juan 👋      │
│  Planta Virrey      │
│                     │
│  ┌─────────────────┐│
│  │  📋 Mis OT      ││
│  │  3 pendientes   ││
│  │            →    ││
│  └─────────────────┘│
│                     │
│  ┌─────────────────┐│
│  │  🔵 En ejecución││
│  │  1 activa       ││
│  │            →    ││
│  └─────────────────┘│
│                     │
│  ┌─────────────────┐│
│  │  ✅ Realizadas  ││
│  │  12 este mes    ││
│  │            →    ││
│  └─────────────────┘│
│                     │
├─────────────────────┤
│  🏠    📋    🔔  👤│
└─────────────────────┘
```

### Lista de OT

```
┌─────────────────────┐
│  ← Mis OT           │
├─────────────────────┤
│                     │
│  ┌─────────────────┐│
│  │ 🔴 URGENTE      ││
│  │ #1234 Preventivo││
│  │ Silo 103        ││
│  │ 📍 Silos Externos││
│  │ 📅 4 jul 2026   ││
│  └─────────────────┘│
│                     │
│  ┌─────────────────┐│
│  │ 🟡 Pendiente    ││
│  │ #1237 Correctivo││
│  │ Bomba B2        ││
│  │ 📍 Planta Int.  ││
│  │ 📅 5 jul 2026   ││
│  └─────────────────┘│
│                     │
├─────────────────────┤
│  🏠    📋    🔔  👤│
└─────────────────────┘
```

### Checklist (paso a paso)

```
┌─────────────────────┐
│  ← Checklist  2/5   │
│  ████████░░░░░ 40%  │
├─────────────────────┤
│                     │
│  Inspección visual  │
│  del silo           │
│                     │
│  Estado:            │
│  ○ Conforme         │
│  ○ No conforme      │
│  ○ N/A              │
│                     │
│  Observaciones:     │
│  ┌─────────────────┐│
│  │                 ││
│  └─────────────────┘│
│                     │
│  ┌─────────────────┐│
│  │    Siguiente →  ││
│  └─────────────────┘│
│                     │
└─────────────────────┘
```

### Firma digital

```
┌─────────────────────┐
│  ← Firma digital    │
├─────────────────────┤
│                     │
│  Firme en el recuadro│
│  ┌─────────────────┐│
│  │                 ││
│  │   (canvas)      ││
│  │                 ││
│  │                 ││
│  └─────────────────┘│
│  [Limpiar]          │
│                     │
│  ┌─────────────────┐│
│  │  Confirmar OT → ││
│  └─────────────────┘│
│                     │
└─────────────────────┘
```

---

## Estados visuales de OT

| Estado | Color | Icono | Badge |
|--------|-------|-------|-------|
| `necesaria_de_emitir` | Gris | ⬜ | — |
| `pendiente` | Amarillo | 🟡 | Pendiente |
| `pendiente_pañol` | Naranja | 🟠 | Pañol |
| `en_ejecucion` | Azul | 🔵 | En ejecución |
| `realizada` | Verde | 🟢 | Realizada |
| `anulada` | Rojo | 🔴 | Anulada |

---

## Notificaciones

### Push (Android)

```
┌─────────────────────────────────┐
│ 📋 Mantenimiento                │
│ Nueva OT asignada               │
│ #1234 · Silo 103 · Preventivo  │
│ Programada: 4 jul 2026          │
└─────────────────────────────────┘
```

### In-app (ambas plataformas)

```
┌─ Notificaciones ────────────────┐
│ 🟡 Hace 5 min                   │
│ Nueva OT #1234 asignada         │
│ Silo 103 · Preventivo           │
├─────────────────────────────────┤
│ 🟠 Hace 1 hora                  │
│ Material aprobado para OT #1230 │
│ Rodamiento 6205 x 2             │
├─────────────────────────────────┤
│ 🔴 Hace 3 horas                 │
│ Material rechazado OT #1228     │
│ Motivo: Sin stock               │
└─────────────────────────────────┘
```

---

## Accesibilidad

| Requisito | Implementación |
|-----------|----------------|
| Contraste mínimo | WCAG AA (4.5:1 texto, 3:1 UI) |
| Tamaño táctil | Mínimo 48x48dp en Android |
| Dark mode | Tokens de color con variante dark |
| Lectores de pantalla | Semantics en Flutter |
| Uso con guantes | Botones grandes, sin gestos complejos |
| Una mano | Acciones principales en tercio inferior |

---

## Animaciones

Sutiles, funcionales:

| Transición | Duración | Tipo |
|------------|----------|------|
| Cambio de pantalla (Android) | 300ms | Slide horizontal |
| Panel detalle (desktop) | 200ms | Fade + slide desde derecha |
| Cambio de estado OT | 150ms | Color fade |
| Toast / snackbar | 3000ms visible | Slide desde abajo |
| Pull to refresh | Nativo | Flutter built-in |

---

## Referencia visual (inspiración, no copia)

| App / Sistema | Qué tomar |
|---------------|-----------|
| Linear | Sidebar + panel detalle, minimalismo |
| Notion | Tablas con filtros, jerarquía |
| MaintainX | Flujo mobile de OT, checklist |
| SGMWin (LyM) | **Solo** cobertura funcional y procesos |
