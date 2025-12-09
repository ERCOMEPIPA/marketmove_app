-- Verifica la estructura de la tabla perfiles
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'perfiles'
ORDER BY ordinal_position;
