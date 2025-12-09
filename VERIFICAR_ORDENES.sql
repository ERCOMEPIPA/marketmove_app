-- ============================================================
-- VERIFICAR: Estructura actual de la tabla ordenes
-- ============================================================
-- Ejecuta esta query para ver las columnas que tiene la tabla ordenes

-- Ver estructura de la tabla ordenes
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'ordenes'
ORDER BY ordinal_position;
