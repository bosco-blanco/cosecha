-- Políticas adicionales de inserción para dev mode
CREATE POLICY IF NOT EXISTS "dev_anon_insert_comentarios" ON comentarios FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY IF NOT EXISTS "dev_anon_insert_anuncios" ON anuncios FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY IF NOT EXISTS "dev_anon_update_tareas" ON tareas FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY IF NOT EXISTS "dev_anon_delete_tareas" ON tareas FOR DELETE TO anon USING (true);
CREATE POLICY IF NOT EXISTS "dev_anon_insert_contactos" ON contactos FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY IF NOT EXISTS "dev_anon_insert_deals" ON deals FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY IF NOT EXISTS "dev_anon_update_deals" ON deals FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY IF NOT EXISTS "dev_anon_insert_visitas" ON visitas_comerciales FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY IF NOT EXISTS "dev_anon_insert_solicitudes" ON solicitudes FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY IF NOT EXISTS "dev_anon_insert_referidos" ON referidos FOR INSERT TO anon WITH CHECK (true);
