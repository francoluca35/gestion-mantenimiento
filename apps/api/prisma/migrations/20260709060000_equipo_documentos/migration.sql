-- Documentos adjuntos de equipo (M2)

CREATE TABLE equipo_documentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipo_id UUID NOT NULL REFERENCES equipos(id) ON DELETE CASCADE,
  sucursal_id UUID NOT NULL REFERENCES sucursales(id),
  nombre VARCHAR(200) NOT NULL,
  tipo VARCHAR(30) NOT NULL DEFAULT 'otro',
  storage_key VARCHAR(500) NOT NULL,
  content_type VARCHAR(100),
  tamano INTEGER,
  activo BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  creador_id UUID REFERENCES usuarios(id)
);

CREATE INDEX equipo_documentos_equipo_id_idx ON equipo_documentos(equipo_id);

ALTER TABLE equipo_documentos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS equipo_documentos_sucursal ON equipo_documentos;
CREATE POLICY equipo_documentos_sucursal ON equipo_documentos
  USING (app.puede_ver_sucursal(sucursal_id))
  WITH CHECK (app.puede_ver_sucursal(sucursal_id));
