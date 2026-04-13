-- ============================================================
-- 009_dev_mode_policies.sql
-- Políticas permisivas para desarrollo con PIN auth.
-- En producción, reemplazar con Supabase Auth + RLS estricto.
-- ============================================================

-- Permitir lectura/escritura desde anon para desarrollo
CREATE POLICY "dev_anon_select_fichajes" ON fichajes FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_insert_fichajes" ON fichajes FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "dev_anon_select_descansos" ON descansos FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_insert_descansos" ON descansos FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "dev_anon_select_empleados" ON empleados FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_select_ubicaciones" ON ubicaciones FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_select_tareas" ON tareas FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_insert_tareas" ON tareas FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "dev_anon_select_anuncios" ON anuncios FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_select_comentarios" ON comentarios FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_select_contactos" ON contactos FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_select_deals" ON deals FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_select_solicitudes" ON solicitudes FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_select_ofertas" ON ofertas_empleo FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_select_referidos" ON referidos FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_select_documentos" ON documentos FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_select_proyectos" ON proyectos FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_select_archivos" ON archivos FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_select_pedidos" ON pedidos FOR SELECT TO anon USING (true);
CREATE POLICY "dev_anon_select_visitas" ON visitas_comerciales FOR SELECT TO anon USING (true);
