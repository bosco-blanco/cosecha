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
