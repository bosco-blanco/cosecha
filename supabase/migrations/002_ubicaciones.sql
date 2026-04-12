-- ============================================================
-- 002_ubicaciones.sql
-- Ubicaciones / locales de ECDB.
-- Lista canónica — NO inventar ubicaciones fuera de esta lista.
-- ============================================================

CREATE TABLE ubicaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  direccion TEXT,
  latitud DOUBLE PRECISION NOT NULL,
  longitud DOUBLE PRECISION NOT NULL,
  radio_permitido INTEGER DEFAULT 100 NOT NULL,
  tipo TEXT NOT NULL
    CHECK (tipo IN ('tienda', 'restaurante', 'híbrido', 'gastronómico', 'noche', 'distribución')),
  qr_code TEXT UNIQUE,
  activo BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Índice para búsqueda por tipo
CREATE INDEX idx_ubicaciones_tipo ON ubicaciones(tipo);
CREATE INDEX idx_ubicaciones_activo ON ubicaciones(activo);

-- Añadir FK en empleados
ALTER TABLE empleados
  ADD CONSTRAINT fk_empleados_ubicacion
  FOREIGN KEY (ubicacion_base_id)
  REFERENCES ubicaciones(id);

-- RLS
ALTER TABLE ubicaciones ENABLE ROW LEVEL SECURITY;

-- Todos los empleados autenticados pueden ver ubicaciones
CREATE POLICY "authenticated_select_ubicaciones"
  ON ubicaciones FOR SELECT
  TO authenticated
  USING (true);

-- Solo admin puede modificar ubicaciones
CREATE POLICY "admin_all_ubicaciones"
  ON ubicaciones FOR ALL
  USING (
    EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin')
  );
