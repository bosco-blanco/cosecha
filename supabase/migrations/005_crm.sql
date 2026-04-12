-- ============================================================
-- 005_crm.sql
-- CRM Comercial — contactos, deals, visitas, pedidos, eventos.
-- Dos pipelines: CODEBA y Eventos.
-- ============================================================

-- Contactos
CREATE TABLE contactos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  email TEXT,
  telefono TEXT,
  empresa TEXT,
  tipo TEXT DEFAULT 'prospecto'
    CHECK (tipo IN ('cliente', 'prospecto', 'partner', 'distribuidor', 'eventos')),
  etiquetas TEXT[] DEFAULT '{}',
  notas TEXT,
  ultimo_contacto TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_contactos_tipo ON contactos(tipo);
CREATE INDEX idx_contactos_empresa ON contactos(empresa);

CREATE TRIGGER contactos_updated_at
  BEFORE UPDATE ON contactos
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Deals (oportunidades)
CREATE TABLE deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo TEXT NOT NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('codeba', 'evento')),
  contacto_id UUID REFERENCES contactos(id),
  contacto_nombre TEXT,
  valor DOUBLE PRECISION DEFAULT 0,
  etapa TEXT NOT NULL,
  probabilidad INTEGER DEFAULT 0 CHECK (probabilidad >= 0 AND probabilidad <= 100),
  cierre_esperado DATE,
  asignado_id UUID REFERENCES empleados(id),
  notas TEXT,
  creado_por UUID REFERENCES empleados(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_deals_tipo ON deals(tipo);
CREATE INDEX idx_deals_etapa ON deals(etapa);
CREATE INDEX idx_deals_asignado ON deals(asignado_id);
CREATE INDEX idx_deals_contacto ON deals(contacto_id);

CREATE TRIGGER deals_updated_at
  BEFORE UPDATE ON deals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Visitas comerciales
CREATE TABLE visitas_comerciales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comercial_id UUID REFERENCES empleados(id) NOT NULL,
  contacto_id UUID REFERENCES contactos(id) NOT NULL,
  tipo TEXT NOT NULL
    CHECK (tipo IN ('presencial', 'llamada', 'email', 'videollamada')),
  fecha TIMESTAMPTZ NOT NULL,
  duracion INTEGER, -- minutos
  ubicacion TEXT,
  latitud DOUBLE PRECISION,
  longitud DOUBLE PRECISION,
  distancia DOUBLE PRECISION,
  notas TEXT,
  siguiente_paso TEXT,
  deal_id UUID REFERENCES deals(id),
  resultado TEXT CHECK (resultado IN ('exitosa', 'sinInteres', 'pospuesto')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_visitas_comercial ON visitas_comerciales(comercial_id);
CREATE INDEX idx_visitas_contacto ON visitas_comerciales(contacto_id);
CREATE INDEX idx_visitas_fecha ON visitas_comerciales(fecha);

-- Pedidos
CREATE TABLE pedidos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deal_id UUID REFERENCES deals(id),
  contacto_id UUID REFERENCES contactos(id),
  productos JSONB DEFAULT '[]', -- [{producto, cantidad, precioUnitario}]
  valor_total DOUBLE PRECISION DEFAULT 0,
  estado TEXT DEFAULT 'pendiente'
    CHECK (estado IN ('pendiente', 'confirmado', 'enviado', 'entregado', 'facturado')),
  fecha_pedido DATE,
  fecha_entrega DATE,
  notas TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_pedidos_deal ON pedidos(deal_id);
CREATE INDEX idx_pedidos_estado ON pedidos(estado);

CREATE TRIGGER pedidos_updated_at
  BEFORE UPDATE ON pedidos
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE contactos ENABLE ROW LEVEL SECURITY;
ALTER TABLE deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitas_comerciales ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;

-- Todos los autenticados ven contactos y deals
CREATE POLICY "authenticated_select_contactos" ON contactos FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_select_deals" ON deals FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_select_visitas" ON visitas_comerciales FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_select_pedidos" ON pedidos FOR SELECT TO authenticated USING (true);

-- Comerciales y managers pueden crear
CREATE POLICY "comercial_insert_contactos" ON contactos FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "comercial_insert_deals" ON deals FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "comercial_insert_visitas" ON visitas_comerciales FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "comercial_insert_pedidos" ON pedidos FOR INSERT TO authenticated WITH CHECK (true);

-- Admin puede todo
CREATE POLICY "admin_all_contactos" ON contactos FOR ALL USING (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin'));
CREATE POLICY "admin_all_deals" ON deals FOR ALL USING (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin'));
CREATE POLICY "admin_all_visitas" ON visitas_comerciales FOR ALL USING (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin'));
CREATE POLICY "admin_all_pedidos" ON pedidos FOR ALL USING (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin'));

-- Asignados pueden actualizar sus deals
CREATE POLICY "asignado_update_deals" ON deals FOR UPDATE
  USING (asignado_id = auth.uid())
  WITH CHECK (asignado_id = auth.uid());
