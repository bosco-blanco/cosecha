-- ============================================================
-- 006_portal_empleado.sql
-- Portal del Empleado — solicitudes, ofertas, referidos, documentos.
-- ============================================================

-- Solicitudes (Help Desk)
CREATE TABLE solicitudes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empleado_id UUID REFERENCES empleados(id) NOT NULL,
  categoria TEXT NOT NULL
    CHECK (categoria IN ('it', 'rrhh', 'mantenimiento', 'admin', 'otro')),
  titulo TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  prioridad TEXT DEFAULT 'normal'
    CHECK (prioridad IN ('baja', 'normal', 'alta')),
  estado TEXT DEFAULT 'nueva'
    CHECK (estado IN ('nueva', 'enProceso', 'resuelta', 'cerrada')),
  asignado_a UUID REFERENCES empleados(id),
  respuesta TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  resuelto_en TIMESTAMPTZ,
  satisfaccion INTEGER CHECK (satisfaccion >= 1 AND satisfaccion <= 5)
);

CREATE INDEX idx_solicitudes_empleado ON solicitudes(empleado_id);
CREATE INDEX idx_solicitudes_estado ON solicitudes(estado);
CREATE INDEX idx_solicitudes_categoria ON solicitudes(categoria);

-- Ofertas de empleo
CREATE TABLE ofertas_empleo (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo TEXT NOT NULL,
  ubicacion_id UUID REFERENCES ubicaciones(id),
  departamento TEXT,
  descripcion TEXT NOT NULL,
  requisitos TEXT[] DEFAULT '{}',
  salario TEXT,
  tipo_contrato TEXT DEFAULT 'indefinido'
    CHECK (tipo_contrato IN ('indefinido', 'temporal', 'practicas')),
  estado TEXT DEFAULT 'abierta'
    CHECK (estado IN ('abierta', 'cerrada', 'completada')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  cierre TIMESTAMPTZ
);

CREATE INDEX idx_ofertas_estado ON ofertas_empleo(estado);

-- Referidos
CREATE TABLE referidos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referido_por_id UUID REFERENCES empleados(id) NOT NULL,
  referido_por_nombre TEXT NOT NULL,
  candidato_nombre TEXT NOT NULL,
  candidato_telefono TEXT,
  candidato_email TEXT,
  puesto_id UUID REFERENCES ofertas_empleo(id),
  puesto_titulo TEXT,
  estado TEXT DEFAULT 'enviado'
    CHECK (estado IN ('enviado', 'enProceso', 'contratado', 'descartado')),
  fecha_envio TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  fecha_contratacion TIMESTAMPTZ,
  fecha_bonificacion TIMESTAMPTZ,
  monto_bonificacion DOUBLE PRECISION DEFAULT 200.0,
  notificacion_enviada BOOLEAN DEFAULT false,
  notas TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_referidos_referidor ON referidos(referido_por_id);
CREATE INDEX idx_referidos_estado ON referidos(estado);

-- Documentos
CREATE TABLE documentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empleado_id UUID REFERENCES empleados(id) NOT NULL,
  tipo TEXT NOT NULL
    CHECK (tipo IN ('nomina', 'contrato', 'politica', 'certificado', 'otro')),
  titulo TEXT NOT NULL,
  url TEXT NOT NULL,
  periodo TEXT, -- e.g. '2026-03'
  descargado_en TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  expira TIMESTAMPTZ
);

CREATE INDEX idx_documentos_empleado ON documentos(empleado_id);
CREATE INDEX idx_documentos_tipo ON documentos(tipo);

-- RLS
ALTER TABLE solicitudes ENABLE ROW LEVEL SECURITY;
ALTER TABLE ofertas_empleo ENABLE ROW LEVEL SECURITY;
ALTER TABLE referidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE documentos ENABLE ROW LEVEL SECURITY;

-- Solicitudes: empleados ven las suyas
CREATE POLICY "empleados_select_solicitudes" ON solicitudes FOR SELECT
  USING (empleado_id = auth.uid());
CREATE POLICY "empleados_insert_solicitudes" ON solicitudes FOR INSERT
  WITH CHECK (empleado_id = auth.uid());

-- Admin y managers ven todas las solicitudes
CREATE POLICY "admin_all_solicitudes" ON solicitudes FOR ALL
  USING (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol IN ('admin', 'manager')));

-- Ofertas: todos ven
CREATE POLICY "authenticated_select_ofertas" ON ofertas_empleo FOR SELECT TO authenticated USING (true);
-- Solo admin crea ofertas
CREATE POLICY "admin_insert_ofertas" ON ofertas_empleo FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin'));
CREATE POLICY "admin_all_ofertas" ON ofertas_empleo FOR ALL
  USING (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin'));

-- Referidos: empleados ven los suyos
CREATE POLICY "empleados_select_referidos" ON referidos FOR SELECT
  USING (referido_por_id = auth.uid());
CREATE POLICY "empleados_insert_referidos" ON referidos FOR INSERT
  WITH CHECK (referido_por_id = auth.uid());
CREATE POLICY "admin_all_referidos" ON referidos FOR ALL
  USING (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin'));

-- Documentos: empleados ven los suyos
CREATE POLICY "empleados_select_documentos" ON documentos FOR SELECT
  USING (empleado_id = auth.uid());
-- Admin puede gestionar todos los documentos
CREATE POLICY "admin_all_documentos" ON documentos FOR ALL
  USING (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin'));
