-- =====================================================
-- Script para Agregar Columna de Edad a la Tabla Pacientes
-- Proyecto Taller Móvil - Detectives
-- 
-- Este script agrega la columna 'age' a la tabla pacientes
-- si no existe ya
-- =====================================================

USE taller_movil_db;

-- =====================================================
-- Verificar si la columna age ya existe
-- =====================================================
SET @column_exists = (
    SELECT COUNT(*) 
    FROM information_schema.columns 
    WHERE table_schema = 'taller_movil_db' 
    AND table_name = 'pacientes' 
    AND column_name = 'age'
);

-- =====================================================
-- Agregar columna age si no existe
-- =====================================================
SET @sql = IF(@column_exists = 0,
    'ALTER TABLE pacientes ADD COLUMN age INT NULL COMMENT ''Edad del paciente'' AFTER identification;',
    'SELECT ''La columna age ya existe en la tabla pacientes'' AS mensaje;'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =====================================================
-- Verificar resultado
-- =====================================================
SELECT 'Columna age agregada exitosamente' AS mensaje;
DESCRIBE pacientes;

