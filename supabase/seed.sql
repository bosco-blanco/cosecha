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
