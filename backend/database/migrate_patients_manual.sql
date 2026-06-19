-- =====================================================
-- Script de Migración Manual - Tabla de Pacientes
-- Proyecto Taller Móvil
-- 
-- Si tu tabla pacientes tiene campos en español, ejecuta este script
-- paso a paso para migrarlos a inglés
-- =====================================================

USE taller_movil_db;

-- =====================================================
-- PASO 1: Migrar columnas de español a inglés
-- Ejecuta estos comandos UNO POR UNO si tu tabla tiene campos en español
-- =====================================================

-- Migrar nombre_completo -> full_name
ALTER TABLE pacientes CHANGE COLUMN nombre_completo full_name VARCHAR(255) NOT NULL;

-- Migrar identificacion -> identification
ALTER TABLE pacientes CHANGE COLUMN identificacion identification VARCHAR(50) NOT NULL;

-- Migrar fecha_nacimiento -> birth_date
ALTER TABLE pacientes CHANGE COLUMN fecha_nacimiento birth_date DATE NULL;

-- Migrar genero -> gender
ALTER TABLE pacientes CHANGE COLUMN genero gender VARCHAR(20) NULL;

-- Migrar telefono -> phone
ALTER TABLE pacientes CHANGE COLUMN telefono phone VARCHAR(20) NULL;

-- Migrar direccion -> address
ALTER TABLE pacientes CHANGE COLUMN direccion address TEXT NULL;

-- Migrar notas -> notes
ALTER TABLE pacientes CHANGE COLUMN notas notes TEXT NULL;

-- =====================================================
-- PASO 2: Eliminar índices antiguos
-- =====================================================
DROP INDEX IF EXISTS idx_identificacion ON pacientes;
DROP INDEX IF EXISTS idx_nombre ON pacientes;

-- =====================================================
-- PASO 3: Crear nuevos índices
-- =====================================================
CREATE INDEX idx_identification ON pacientes(identification);
CREATE INDEX idx_full_name ON pacientes(full_name);

-- =====================================================
-- PASO 4: Verificar resultado
-- =====================================================
SELECT 'Migración completada exitosamente' AS mensaje;
SELECT COUNT(*) AS total_pacientes FROM pacientes;
DESCRIBE pacientes;

