-- ============================================================
-- 003_fichajes.sql
-- Registro de fichajes (entrada/salida) + descansos.
-- Cumplimiento legal: RD-ley 8/2019.
-- Fichajes son INMUTABLES — solo admin puede hacer correcciones manuales.
-- Retención mínima: 4 años.
-- ============================================================

CREATE TABLE fichajes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empleado_id UUID REFERENCES empleados(id) NOT NULL,
  empleado_nombre TEXT NOT NULL, -- denormalizado para informes
  tipo TEXT CHECK (tipo IN ('entrada', 'salida')) NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  latitud DOUBLE PRECISION,
  longitud DOUBLE PRECISION,
  ubicacion_id UUID REFERENCES ubicaciones(id),
  distancia_al_centro DOUBLE PRECISION,
  valido BOOLEAN DEFAULT true,
  metodo TEXT CHECK (metodo IN ('app', 'qr', 'manual')) DEFAULT 'app',
  dispositivo TEXT,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Índices para consultas frecuentes
CREATE INDEX idx_fichajes_empleado ON fichajes(empleado_id);
CREATE INDEX idx_fichajes_timestamp ON fichajes(timestamp);
CREATE INDEX idx_fichajes_ubicacion ON fichajes(ubicacion_id);
CREATE INDEX idx_fichajes_empleado_fecha ON fichajes(empleado_id, timestamp);

-- Tabla de descansos
CREATE TABLE descansos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fichaje_padre_id UUID REFERENCES fichajes(id) NOT NULL,
  empleado_id UUID REFERENCES empleados(id) NOT NULL,
  tiempo_descanso INTEGER NOT NULL, -- minutos
  tipo TEXT CHECK (tipo IN ('comida', 'descanso')) DEFAULT 'descanso',
  timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_descansos_fichaje ON descansos(fichaje_padre_id);
CREATE INDEX idx_descansos_empleado ON descansos(empleado_id);

-- RLS para fichajes
ALTER TABLE fichajes ENABLE ROW LEVEL SECURITY;

-- Empleados ven sus fichajes
CREATE POLICY "empleados_select_fichajes"
  ON fichajes FOR SELECT
  USING (empleado_id = auth.uid());

-- Managers ven fichajes de su ubicación
CREATE POLICY "managers_select_fichajes"
  ON fichajes FOR SELECT
  USING (
    ubicacion_id IN (
      SELECT ubicacion_base_id FROM empleados WHERE id = auth.uid() AND rol = 'manager'
    )
  );

-- Admin ve todos los fichajes
CREATE POLICY "admin_all_fichajes"
  ON fichajes FOR ALL
  USING (
    EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin')
  );

-- Empleados pueden crear sus propios fichajes (NO modificar ni borrar)
CREATE POLICY "empleados_insert_fichajes"
  ON fichajes FOR INSERT
  WITH CHECK (empleado_id = auth.uid());

-- RLS para descansos
ALTER TABLE descansos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "empleados_select_descansos"
  ON descansos FOR SELECT
  USING (empleado_id = auth.uid());

CREATE POLICY "empleados_insert_descansos"
  ON descansos FOR INSERT
  WITH CHECK (empleado_id = auth.uid());

CREATE POLICY "admin_all_descansos"
  ON descansos FOR ALL
  USING (
    EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin')
  );
