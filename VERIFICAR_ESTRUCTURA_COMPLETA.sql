-- ============================================================
-- VERIFICACIÓN COMPLETA DE ESTRUCTURA DE TABLAS
-- ============================================================

-- Ver estructura de perfiles
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'perfiles'
ORDER BY ordinal_position;

-- Ver estructura de negocios
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'negocios'
ORDER BY ordinal_position;

-- Ver estructura de productos
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'productos'
ORDER BY ordinal_position;

-- Ver estructura de categorias
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'categorias'
ORDER BY ordinal_position;

-- Ver estructura de ordenes
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'ordenes'
ORDER BY ordinal_position;

-- Ver algunos datos de ejemplo
SELECT * FROM perfiles LIMIT 1;
SELECT * FROM negocios LIMIT 1;
SELECT * FROM productos LIMIT 1;
SELECT * FROM categorias LIMIT 1;
