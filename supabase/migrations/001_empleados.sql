-- ============================================================
-- 001_empleados.sql
-- Tabla de empleados — entidad central de Cosecha.
-- Todos los módulos referencian esta tabla.
-- ============================================================

CREATE TABLE empleados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  telefono TEXT,
  pin TEXT NOT NULL CHECK (length(pin) >= 4 AND length(pin) <= 6),
  rol TEXT NOT NULL DEFAULT 'empleado'
    CHECK (rol IN ('admin', 'manager', 'empleado', 'comercial')),
  ubicacion_base_id UUID, -- FK se añade después de crear ubicaciones
  departamento TEXT
    CHECK (departamento IN ('operaciones', 'comercial', 'cocina', 'servicio', 'admin', 'rrhh')),
  foto_perfil TEXT,
  activo BOOLEAN DEFAULT true NOT NULL,
  ultima_actividad_en TIMESTAMPTZ,
  notificaciones_activadas BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Índices
CREATE INDEX idx_empleados_pin ON empleados(pin);
CREATE INDEX idx_empleados_email ON empleados(email);
CREATE INDEX idx_empleados_rol ON empleados(rol);
CREATE INDEX idx_empleados_activo ON empleados(activo);
CREATE INDEX idx_empleados_ubicacion ON empleados(ubicacion_base_id);

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER empleados_updated_at
  BEFORE UPDATE ON empleados
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE empleados ENABLE ROW LEVEL SECURITY;

-- Empleados ven su propio perfil
CREATE POLICY "empleados_select_self"
  ON empleados FOR SELECT
  USING (id = auth.uid());

-- Managers ven empleados de su ubicación
CREATE POLICY "managers_select_ubicacion"
  ON empleados FOR SELECT
  USING (
    ubicacion_base_id IN (
      SELECT ubicacion_base_id FROM empleados WHERE id = auth.uid() AND rol = 'manager'
    )
  );

-- Admin ve todos los empleados
CREATE POLICY "admin_all_empleados"
  ON empleados FOR ALL
  USING (
    EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin')
  );

-- Empleados pueden actualizar campos limitados de su perfil
CREATE POLICY "empleados_update_self"
  ON empleados FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());
