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
-- ============================================================
-- 004_tareas_y_proyectos.sql
-- CRM Interno — tareas, proyectos, comentarios, anuncios, archivos.
-- ============================================================

-- Proyectos
CREATE TABLE proyectos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  descripcion TEXT,
  lider_id UUID REFERENCES empleados(id),
  estado TEXT DEFAULT 'activo'
    CHECK (estado IN ('activo', 'en-pausa', 'completado')),
  fecha_inicio DATE,
  fecha_fin DATE,
  miembros UUID[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TRIGGER proyectos_updated_at
  BEFORE UPDATE ON proyectos
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Tareas
CREATE TABLE tareas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo TEXT NOT NULL,
  descripcion TEXT,
  columna TEXT DEFAULT 'backlog'
    CHECK (columna IN ('backlog', 'enProgreso', 'revision', 'completado')),
  prioridad TEXT DEFAULT 'normal'
    CHECK (prioridad IN ('baja', 'normal', 'alta', 'critica')),
  etiquetas TEXT[] DEFAULT '{}',
  fecha_limite TIMESTAMPTZ,
  asignados UUID[] DEFAULT '{}',
  proyecto_id UUID REFERENCES proyectos(id),
  creado_por UUID REFERENCES empleados(id) NOT NULL,
  completado_en TIMESTAMPTZ,
  completado_por UUID REFERENCES empleados(id),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_tareas_columna ON tareas(columna);
CREATE INDEX idx_tareas_creado_por ON tareas(creado_por);
CREATE INDEX idx_tareas_proyecto ON tareas(proyecto_id);

CREATE TRIGGER tareas_updated_at
  BEFORE UPDATE ON tareas
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comentarios (polimórficos)
CREATE TABLE comentarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entidad_tipo TEXT NOT NULL
    CHECK (entidad_tipo IN ('tarea', 'contacto', 'deal', 'reunion')),
  entidad_id UUID NOT NULL,
  autor_id UUID REFERENCES empleados(id) NOT NULL,
  autor_nombre TEXT NOT NULL,
  texto TEXT NOT NULL,
  menciones UUID[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  borrado_en TIMESTAMPTZ -- soft delete
);

CREATE INDEX idx_comentarios_entidad ON comentarios(entidad_tipo, entidad_id);
CREATE INDEX idx_comentarios_autor ON comentarios(autor_id);

CREATE TRIGGER comentarios_updated_at
  BEFORE UPDATE ON comentarios
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Anuncios
CREATE TABLE anuncios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo TEXT NOT NULL,
  cuerpo TEXT NOT NULL,
  autor_id UUID REFERENCES empleados(id) NOT NULL,
  prioridad TEXT DEFAULT 'normal'
    CHECK (prioridad IN ('baja', 'normal', 'urgente')),
  destinatarios TEXT DEFAULT 'todos'
    CHECK (destinatarios IN ('todos', 'ubicacion', 'equipo', 'rol')),
  ubicacion_id UUID REFERENCES ubicaciones(id),
  leido_por UUID[] DEFAULT '{}',
  destacado BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  expira TIMESTAMPTZ
);

CREATE INDEX idx_anuncios_prioridad ON anuncios(prioridad);
CREATE INDEX idx_anuncios_destacado ON anuncios(destacado);

-- Archivos (adjuntos polimórficos)
CREATE TABLE archivos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entidad_tipo TEXT NOT NULL
    CHECK (entidad_tipo IN ('tarea', 'contacto', 'deal', 'reunion')),
  entidad_id UUID NOT NULL,
  nombre TEXT NOT NULL,
  url TEXT NOT NULL,
  tipo TEXT DEFAULT 'otro'
    CHECK (tipo IN ('imagen', 'pdf', 'documento', 'hoja-calculo', 'otro')),
  tamano INTEGER, -- bytes
  subido_por UUID REFERENCES empleados(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  borrado_en TIMESTAMPTZ
);

CREATE INDEX idx_archivos_entidad ON archivos(entidad_tipo, entidad_id);

-- RLS
ALTER TABLE proyectos ENABLE ROW LEVEL SECURITY;
ALTER TABLE tareas ENABLE ROW LEVEL SECURITY;
ALTER TABLE comentarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE anuncios ENABLE ROW LEVEL SECURITY;
ALTER TABLE archivos ENABLE ROW LEVEL SECURITY;

-- Todos los autenticados ven proyectos, tareas, comentarios, anuncios, archivos
CREATE POLICY "authenticated_select_proyectos" ON proyectos FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_select_tareas" ON tareas FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_select_comentarios" ON comentarios FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_select_anuncios" ON anuncios FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_select_archivos" ON archivos FOR SELECT TO authenticated USING (true);

-- Todos pueden crear tareas, comentarios
CREATE POLICY "authenticated_insert_tareas" ON tareas FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "authenticated_insert_comentarios" ON comentarios FOR INSERT TO authenticated WITH CHECK (true);

-- Solo managers/admin crean proyectos y anuncios
CREATE POLICY "managers_insert_proyectos" ON proyectos FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol IN ('admin', 'manager')));
CREATE POLICY "managers_insert_anuncios" ON anuncios FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol IN ('admin', 'manager')));

-- Todos pueden subir archivos
CREATE POLICY "authenticated_insert_archivos" ON archivos FOR INSERT TO authenticated WITH CHECK (true);

-- Admin puede todo
CREATE POLICY "admin_all_proyectos" ON proyectos FOR ALL USING (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin'));
CREATE POLICY "admin_all_tareas" ON tareas FOR ALL USING (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin'));
CREATE POLICY "admin_all_comentarios" ON comentarios FOR ALL USING (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin'));
CREATE POLICY "admin_all_anuncios" ON anuncios FOR ALL USING (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin'));
CREATE POLICY "admin_all_archivos" ON archivos FOR ALL USING (EXISTS (SELECT 1 FROM empleados WHERE id = auth.uid() AND rol = 'admin'));

-- Creadores pueden actualizar sus propias tareas
CREATE POLICY "creator_update_tareas" ON tareas FOR UPDATE
  USING (creado_por = auth.uid())
  WITH CHECK (creado_por = auth.uid());
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
-- ============================================================
-- 007_rls_policies.sql
-- Políticas RLS adicionales y vistas útiles.
-- ============================================================

-- Vista: empleados activos con su ubicación
CREATE OR REPLACE VIEW v_empleados_con_ubicacion AS
SELECT
  e.id,
  e.nombre,
  e.email,
  e.rol,
  e.departamento,
  e.activo,
  e.ubicacion_base_id,
  u.nombre AS ubicacion_nombre,
  u.tipo AS ubicacion_tipo,
  e.ultima_actividad_en,
  e.created_at
FROM empleados e
LEFT JOIN ubicaciones u ON e.ubicacion_base_id = u.id
WHERE e.activo = true;

-- Vista: fichajes del día actual (para dashboard en tiempo real)
CREATE OR REPLACE VIEW v_fichajes_hoy AS
SELECT
  f.id,
  f.empleado_id,
  f.empleado_nombre,
  f.tipo,
  f.timestamp,
  f.ubicacion_id,
  u.nombre AS ubicacion_nombre,
  f.valido,
  f.metodo
FROM fichajes f
LEFT JOIN ubicaciones u ON f.ubicacion_id = u.id
WHERE f.timestamp::date = CURRENT_DATE
ORDER BY f.timestamp DESC;

-- Vista: resumen de horas por empleado por mes
CREATE OR REPLACE VIEW v_resumen_horas_mensual AS
WITH entradas AS (
  SELECT empleado_id, empleado_nombre, timestamp AS entrada,
    LEAD(timestamp) OVER (PARTITION BY empleado_id ORDER BY timestamp) AS salida,
    LEAD(tipo) OVER (PARTITION BY empleado_id ORDER BY timestamp) AS siguiente_tipo
  FROM fichajes
  WHERE tipo = 'entrada'
)
SELECT
  empleado_id,
  empleado_nombre,
  DATE_TRUNC('month', entrada) AS mes,
  COUNT(*) AS dias_trabajados,
  SUM(EXTRACT(EPOCH FROM (salida - entrada)) / 3600) AS horas_totales
FROM entradas
WHERE siguiente_tipo = 'salida'
  AND salida IS NOT NULL
GROUP BY empleado_id, empleado_nombre, DATE_TRUNC('month', entrada);

-- Función: comprobar si un referido es elegible para bonificación (6 meses)
CREATE OR REPLACE FUNCTION check_referido_bonificacion()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.estado = 'contratado' AND NEW.fecha_contratacion IS NOT NULL THEN
    -- Marcar para revisión de bonificación a los 6 meses
    NEW.notificacion_enviada = false;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER referido_contratacion_check
  BEFORE UPDATE ON referidos
  FOR EACH ROW
  WHEN (NEW.estado = 'contratado' AND OLD.estado != 'contratado')
  EXECUTE FUNCTION check_referido_bonificacion();

-- Habilitar Realtime para fichajes (ver quién está fichado ahora)
ALTER PUBLICATION supabase_realtime ADD TABLE fichajes;
-- ============================================================
-- seed.sql
-- Datos iniciales para desarrollo y testing.
-- Ubicaciones reales de ECDB + empleados de prueba.
-- ============================================================

-- ── Ubicaciones ECDB (lista canónica) ──
INSERT INTO ubicaciones (nombre, tipo, latitud, longitud, radio_permitido) VALUES
  ('Zoco de Pozuelo', 'tienda', 40.4357, -3.8123, 100),
  ('Centro Oeste Majadahonda', 'tienda', 40.4500, -3.8700, 100),
  ('CC Arturo Soria Plaza', 'tienda', 40.4520, -3.6380, 100),
  ('Calle Granada', 'tienda', 40.4168, -3.7038, 100),
  ('Calle Núñez de Balboa', 'tienda', 40.4280, -3.6830, 100),
  ('La Casita (Claudio Coello 121)', 'híbrido', 40.4295, -3.6795, 100),
  ('Restaurante Aravaca', 'restaurante', 40.4590, -3.7930, 100),
  ('Restaurante Moraleja', 'restaurante', 40.5200, -3.6350, 100),
  ('Restaurante Pozuelo', 'restaurante', 40.4370, -3.8100, 100),
  ('Ancestral', 'gastronómico', 40.4200, -3.7050, 100),
  ('Brassafina', 'gastronómico', 40.4250, -3.6900, 100),
  ('Las Margaritas', 'gastronómico', 40.4300, -3.7100, 100),
  ('Panthera', 'noche', 40.4230, -3.6920, 100),
  ('Rubicon', 'noche', 40.4220, -3.6950, 100),
  ('CODEBA — Nave Leganés', 'distribución', 40.3270, -3.7640, 200);

-- ── Empleados de prueba ──
-- NOTA: Los IDs de empleado deben coincidir con los users de Supabase Auth.
-- En desarrollo, crear estos usuarios en Supabase Dashboard → Authentication.
-- PINs de prueba: 0000 (admin), 1111 (manager), 2222 (empleado), 3333 (comercial), 4444 (empleado)

-- Los INSERT reales se harán después de crear los Auth users,
-- usando el UUID generado por Supabase Auth como ID.
-- Ejemplo:
--
-- INSERT INTO empleados (id, nombre, email, pin, rol, ubicacion_base_id, departamento) VALUES
--   ('<auth-uuid-bosco>', 'Bosco Blanco', 'bosco@encopadebalon.com', '0000', 'admin', NULL, 'admin'),
--   ('<auth-uuid-carlos>', 'Carlos Ruiz', 'carlos@encopadebalon.com', '1111', 'manager',
--     (SELECT id FROM ubicaciones WHERE nombre = 'Zoco de Pozuelo'), 'operaciones'),
--   ('<auth-uuid-maria>', 'María López', 'maria@encopadebalon.com', '2222', 'empleado',
--     (SELECT id FROM ubicaciones WHERE nombre = 'CC Arturo Soria Plaza'), 'servicio'),
--   ('<auth-uuid-pablo>', 'Pablo Fernández', 'pablo@encopadebalon.com', '3333', 'comercial',
--     (SELECT id FROM ubicaciones WHERE nombre = 'CODEBA — Nave Leganés'), 'comercial'),
--   ('<auth-uuid-laura>', 'Laura Martín', 'laura@encopadebalon.com', '4444', 'empleado',
--     (SELECT id FROM ubicaciones WHERE nombre = 'Ancestral'), 'cocina');

-- ── Anuncio de bienvenida ──
-- INSERT INTO anuncios (titulo, cuerpo, autor_id, prioridad, destinatarios, destacado) VALUES
--   ('Bienvenidos a Cosecha',
--    'La nueva app de gestión interna de En Copa de Balón está en marcha. Usa tu PIN para fichar y acceder a tus tareas.',
--    '<auth-uuid-bosco>', 'normal', 'todos', true);
