-- Permitir a admin crear y actualizar empleados
CREATE POLICY "dev_anon_insert_empleados" ON empleados FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "dev_anon_update_empleados" ON empleados FOR UPDATE TO anon USING (true) WITH CHECK (true);
