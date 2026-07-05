# 05 — Permisos y árbol de Derechos

Réplica 1:1 del modelo de SGMWin: Usuario + Perfil + árbol de Derechos.

SGMWin no usa roles fijos en código. Se replica igual.

---

## Modelo de permisos

```
Usuario
├─ perfil_id → Perfil
├─ es_administrador (derechos reservados, no del árbol)
├─ supervisa_sucursales
├─ supervisa_solicitudes_ot (ninguna | de_su_sector | todas)
├─ supervisa_solicitudes_oc
└─ monto_maximo_oc

Perfil
└─ PerfilDerecho[] → Derecho (árbol)

Derecho (árbol fijo, seed en DB)
├─ parent_id
├─ codigo (único, dot-notation)
└─ nombre
```

### Reglas del árbol

1. Marcar un nodo **padre** habilita/deshabilita todos sus hijos (modo **Total**).
2. Cada hijo se puede tildar individualmente (modo **Parcial**).
3. Los derechos del administrador (`es_administrador = true`) **no** están en el árbol — van atados al flag.
4. El árbol es **fijo** (seed data) — no se crean/eliminan nodos en runtime.

### Derechos reservados del administrador

Equivalente al usuario "SGM" del original:

| Derecho | Flag |
|---------|------|
| Reabrir O.T. | `es_administrador` |
| Generar perfiles | `es_administrador` |
| Generar usuarios | `es_administrador` |
| Generar sucursales | `es_administrador` |
| Modificar parámetros del sistema | `es_administrador` |
| Copia de seguridad / restaurar | `es_administrador` |

---

## Árbol completo de Derechos

Refleja la estructura de menú del manual SGMWin (capítulos 3 a 8).

Regla general: cada entidad de Archivos Maestros tiene 4 nodos hijos — `agregar`, `modificar`, `borrar`, `listar` — salvo indicación contraria.

```
sistema
├── archivos
│   ├── procedimientos
│   │   ├── agregar
│   │   ├── modificar
│   │   ├── borrar
│   │   ├── listar
│   │   ├── asociar_a_equipo
│   │   └── ver_historico_version
│   ├── ubicaciones
│   │   ├── agregar_nodo
│   │   ├── modificar_nodo
│   │   ├── borrar_nodo
│   │   └── mover_nodo
│   ├── equipos
│   │   ├── agregar
│   │   ├── modificar
│   │   ├── borrar
│   │   ├── listar
│   │   ├── copiar
│   │   ├── mover
│   │   └── marcar_fuera_de_servicio
│   ├── tipos_equipo
│   │   ├── agregar
│   │   ├── modificar
│   │   ├── borrar
│   │   ├── listar
│   │   ├── definir_campos_detalle
│   │   └── definir_campos_lectura
│   ├── mano_de_obra
│   │   ├── agregar, modificar, borrar, listar
│   ├── proveedores
│   │   ├── agregar, modificar, borrar, listar, calificar
│   ├── materiales
│   │   ├── agregar, modificar, borrar, listar
│   │   ├── modificar_precio
│   │   └── ver_historial_precio
│   ├── recursos
│   │   ├── agregar, modificar, borrar, listar
│   ├── herramientas
│   │   ├── agregar, modificar, borrar, listar
│   ├── responsables
│   │   ├── agregar, modificar, borrar, listar
│   ├── tipos_procedimiento
│   │   ├── agregar, modificar, borrar, listar
│   ├── catalogos_generales
│   │   ├── eventos          (agregar, modificar, borrar, listar)
│   │   ├── tareas           (agregar, modificar, borrar, listar)
│   │   ├── motivos_ot_pendiente
│   │   ├── unidades
│   │   ├── destinos
│   │   ├── condiciones
│   │   ├── iva
│   │   ├── provincias
│   │   ├── paises
│   │   ├── causas
│   │   ├── objetos
│   │   ├── sintomas
│   │   ├── acciones
│   │   └── rubros
│   └── documentos
│       ├── agregar, modificar, borrar, abrir
│
├── programacion
│   ├── ordenes_trabajo
│   │   ├── emitir_periodica
│   │   ├── emitir_no_periodica
│   │   ├── buscar_y_actualizar
│   │   ├── reabrir              ← reservado administrador
│   │   ├── anular
│   │   ├── reimprimir
│   │   ├── marcar_reemplazo_de_otra
│   │   ├── agregar_motivo_pendiente
│   │   ├── ver_reportes_estado
│   │   └── ver_historico
│   ├── solicitudes_trabajo
│   │   ├── agregar, modificar, listar
│   │   ├── enviar_aviso_urgente
│   │   ├── dar_conformidad
│   │   └── emitir_ot_desde_solicitud
│   ├── contadores
│   │   ├── buscar_equipo
│   │   ├── reiniciar
│   │   ├── agregar_lectura
│   │   ├── modificar_lectura
│   │   ├── borrar_lectura
│   │   └── graficar
│   └── gestion
│       ├── presupuesto_trabajos
│       ├── programado_vs_realizado
│       ├── backlog
│       └── resumen_situacion
│
├── stock
│   ├── ordenes_compra
│   │   ├── emitir, buscar_y_actualizar, no_autorizar, anular, reimprimir
│   ├── movimientos
│   │   ├── alta_por_compra, alta_por_transferencia, alta_por_oc
│   │   ├── baja, eliminar
│   ├── reserva_materiales
│   │   ├── reservar, listar
│   ├── vale_consumo
│   │   ├── emitir, reimprimir
│   ├── materiales_en_stock
│   │   ├── ver, modificar_valores_gestion, borrar_de_sucursal
│   ├── prestamo_herramientas
│   │   ├── retirar, devolver, ver_historico, listar
│   └── pañol                          ← NUEVO
│       ├── solicitudes_materiales
│       │   ├── ver_pendientes
│       │   ├── aprobar
│       │   ├── rechazar
│       │   └── ver_historico
│       └── alertas_stock_minimo
│           ├── ver
│           └── configurar_minimo
│
├── analisis
│   ├── trabajos
│   │   ├── costos
│   │   ├── materiales_utilizados
│   │   ├── mano_obra_utilizada
│   │   ├── recursos_utilizados
│   │   ├── fallas
│   │   ├── detalles
│   │   ├── lecturas
│   │   ├── graficas
│   │   ├── pareto_fallas
│   │   └── indices_gestion
│   └── stock
│       ├── comprobantes_movimientos
│       ├── movimiento_fisico
│       ├── reserva
│       ├── reposicion
│       ├── formula_reposicion
│       ├── stock_valorizado
│       ├── consumos_realizados
│       └── materiales_repuesto
│
└── configuracion
    ├── usuarios              ← reservado administrador
    │   ├── agregar, modificar, borrar
    ├── perfiles              ← reservado administrador
    │   ├── agregar, modificar, borrar
    │   ├── definir_derechos
    │   └── asignar_usuarios
    ├── parametros
    │   ├── variables_sistema
    │   ├── reportes
    │   ├── indices
    │   ├── orden_trabajo
    │   └── seteo
    ├── sucursales            ← reservado administrador
    │   ├── agregar, buscar, borrar, asignar_usuarios
    └── copia_seguridad       ← reservado administrador
        ├── realizar
        └── restaurar
```

---

## Perfiles predefinidos (sugeridos)

| Perfil | Derechos habilitados |
|--------|---------------------|
| **Técnico** | `programacion.ordenes_trabajo.buscar_y_actualizar` (solo asignadas), `programacion.contadores.agregar_lectura`, `stock.pañol.solicitudes_materiales` (crear) |
| **Pañolero** | `stock.*` completo, `stock.pañol.*` completo |
| **Derivador OT** | `archivos.ubicaciones.*`, `archivos.equipos.*`, `programacion.ordenes_trabajo.emitir_*` |
| **Supervisor** | `programacion.ordenes_trabajo.*` (excepto reabrir), `programacion.solicitudes_trabajo.*`, `programacion.gestion.*` |
| **Gerente** | `archivos.proveedores.*`, `analisis.*`, `stock.ordenes_compra.*` |
| **Admin Sucursal** | `configuracion.*` (de su sucursal) |

---

## Validación en backend

```typescript
// Guard de NestJS
@Injectable()
export class DerechoGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const requiredDerecho = this.reflector.get<string>('derecho', context.getHandler());
    const user = context.switchToHttp().getRequest().user;

    if (user.es_administrador) return true;

    return this.permisosService.tieneDerecho(user.perfil_id, requiredDerecho);
  }
}

// Uso en controller
@Post('emitir')
@RequiereDerecho('programacion.ordenes_trabajo.emitir_no_periodica')
emitirOT(@Body() dto: EmitirOTDto) { ... }
```

### Resolución del árbol

```typescript
tieneDerecho(perfilId: string, codigo: string): boolean {
  // 1. Buscar derecho exacto en PerfilDerecho
  const directo = await this.findPerfilDerecho(perfilId, codigo);
  if (directo) return directo.habilitado;

  // 2. Buscar ancestros (si padre habilitado en modo Total → true)
  const ancestros = await this.getAncestros(codigo);
  for (const ancestro of ancestros) {
    const pd = await this.findPerfilDerecho(perfilId, ancestro.codigo);
    if (pd?.habilitado && pd.modo === 'total') return true;
  }

  return false;
}
```

---

## UI de edición de derechos (pendiente — sección 12 del spec)

Vista tipo checklist con modo Total/Parcial por nodo:

```
☑ Archivos                    [Total ▾]
  ☑ Procedimientos            [Total ▾]
    ☑ agregar
    ☑ modificar
    ☐ borrar                  ← Parcial: padre habilitado pero este no
    ☑ listar
  ☐ Equipos                   [—]
    ☐ agregar
    ...
```

Esta pantalla es exclusiva de desktop (administrador).
