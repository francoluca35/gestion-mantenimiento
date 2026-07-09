-- RLS por sucursal (M1)
-- Contexto: app.bypass_rls, app.current_sucursal_id, app.es_admin_global, app.supervisa_sucursales

CREATE SCHEMA IF NOT EXISTS app;

CREATE OR REPLACE FUNCTION app.puede_ver_sucursal(target_sucursal_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT
    current_setting('app.bypass_rls', true) = 'true'
    OR current_setting('app.es_admin_global', true) = 'true'
    OR current_setting('app.supervisa_sucursales', true) = 'true'
    OR (
      nullif(current_setting('app.current_sucursal_id', true), '') IS NOT NULL
      AND target_sucursal_id::text = current_setting('app.current_sucursal_id', true)
    );
$$;

CREATE OR REPLACE FUNCTION app.puede_ver_usuario(target_sucursal_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT
    current_setting('app.bypass_rls', true) = 'true'
    OR current_setting('app.es_admin_global', true) = 'true'
    OR current_setting('app.supervisa_sucursales', true) = 'true'
    OR (
      target_sucursal_id IS NOT NULL
      AND nullif(current_setting('app.current_sucursal_id', true), '') IS NOT NULL
      AND target_sucursal_id::text = current_setting('app.current_sucursal_id', true)
    )
    OR (
      target_sucursal_id IS NULL
      AND current_setting('app.es_admin_global', true) = 'true'
    );
$$;

-- usuarios
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS usuarios_sucursal ON usuarios;
CREATE POLICY usuarios_sucursal ON usuarios
  USING (app.puede_ver_usuario(sucursal_id))
  WITH CHECK (app.puede_ver_usuario(sucursal_id));

-- ubicaciones
ALTER TABLE ubicaciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ubicaciones_sucursal ON ubicaciones;
CREATE POLICY ubicaciones_sucursal ON ubicaciones
  USING (app.puede_ver_sucursal(sucursal_id))
  WITH CHECK (app.puede_ver_sucursal(sucursal_id));

-- equipos
ALTER TABLE equipos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS equipos_sucursal ON equipos;
CREATE POLICY equipos_sucursal ON equipos
  USING (app.puede_ver_sucursal(sucursal_id))
  WITH CHECK (app.puede_ver_sucursal(sucursal_id));

-- procedimientos
ALTER TABLE procedimientos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS procedimientos_sucursal ON procedimientos;
CREATE POLICY procedimientos_sucursal ON procedimientos
  USING (app.puede_ver_sucursal(sucursal_id))
  WITH CHECK (app.puede_ver_sucursal(sucursal_id));

-- ordenes_trabajo
ALTER TABLE ordenes_trabajo ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ordenes_trabajo_sucursal ON ordenes_trabajo;
CREATE POLICY ordenes_trabajo_sucursal ON ordenes_trabajo
  USING (app.puede_ver_sucursal(sucursal_id))
  WITH CHECK (app.puede_ver_sucursal(sucursal_id));

-- solicitudes_trabajo
ALTER TABLE solicitudes_trabajo ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS solicitudes_trabajo_sucursal ON solicitudes_trabajo;
CREATE POLICY solicitudes_trabajo_sucursal ON solicitudes_trabajo
  USING (app.puede_ver_sucursal(sucursal_id))
  WITH CHECK (app.puede_ver_sucursal(sucursal_id));
