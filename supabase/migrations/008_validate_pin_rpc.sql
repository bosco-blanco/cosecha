-- ============================================================
-- Función RPC para validar PIN sin necesitar Supabase Auth.
-- Se ejecuta con SECURITY DEFINER (bypasa RLS).
-- ============================================================

CREATE OR REPLACE FUNCTION validate_pin(pin_code TEXT)
RETURNS JSON AS $$
DECLARE
  emp RECORD;
BEGIN
  SELECT id, nombre, email, pin, rol, ubicacion_base_id, departamento,
         foto_perfil, activo, notificaciones_activadas, created_at, updated_at
  INTO emp
  FROM empleados
  WHERE pin = pin_code AND activo = true
  LIMIT 1;

  IF emp IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN json_build_object(
    'id', emp.id,
    'nombre', emp.nombre,
    'email', emp.email,
    'pin', emp.pin,
    'rol', emp.rol,
    'ubicacion_base_id', emp.ubicacion_base_id,
    'departamento', emp.departamento,
    'foto_perfil', emp.foto_perfil,
    'activo', emp.activo,
    'notificaciones_activadas', emp.notificaciones_activadas,
    'created_at', emp.created_at,
    'updated_at', emp.updated_at
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
