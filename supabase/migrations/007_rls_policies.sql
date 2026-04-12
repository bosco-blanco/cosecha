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
