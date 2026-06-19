-- =====================================================
-- Script de Migración - Tabla de Pacientes
-- Proyecto Taller Móvil
-- Ejecuta este script para actualizar la tabla de pacientes
-- 
-- INSTRUCCIONES:
-- 1. Si la tabla NO existe: Ejecuta todo el script
-- 2. Si la tabla existe con campos en español: Ejecuta primero las migraciones,
--    luego el CREATE TABLE IF NOT EXISTS
-- =====================================================

USE taller_movil_db;

-- =====================================================
-- OPCIÓN 1: Si la tabla existe con campos en español,
-- ejecuta estas líneas para migrar (descomenta si es necesario)
-- =====================================================

-- Descomenta estas líneas si tu tabla tiene campos en español:
/*
ALTER TABLE pacientes CHANGE COLUMN nombre_completo full_name VARCHAR(255) NOT NULL;
ALTER TABLE pacientes CHANGE COLUMN identificacion identification VARCHAR(50) NOT NULL;
ALTER TABLE pacientes CHANGE COLUMN fecha_nacimiento birth_date DATE NULL;
ALTER TABLE pacientes CHANGE COLUMN genero gender VARCHAR(20) NULL;
ALTER TABLE pacientes CHANGE COLUMN telefono phone VARCHAR(20) NULL;
ALTER TABLE pacientes CHANGE COLUMN direccion address TEXT NULL;
ALTER TABLE pacientes CHANGE COLUMN notas notes TEXT NULL;

-- Eliminar índices antiguos
DROP INDEX IF EXISTS idx_identificacion ON pacientes;
DROP INDEX IF EXISTS idx_nombre ON pacientes;
*/

-- =====================================================
-- OPCIÓN 2: Crear/Actualizar la tabla con campos en inglés
-- (Ejecuta esto siempre)
-- =====================================================

-- Eliminar índices antiguos si existen (no causa error si no existen)
DROP INDEX IF EXISTS idx_identificacion ON pacientes;
DROP INDEX IF EXISTS idx_nombre ON pacientes;

-- Crear la tabla si no existe (o actualizar si ya existe)
CREATE TABLE IF NOT EXISTS pacientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    identification VARCHAR(50) NOT NULL UNIQUE,
    birth_date DATE NULL,
    gender VARCHAR(20) NULL,
    phone VARCHAR(20) NULL,
    email VARCHAR(255) NULL,
    address TEXT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Índices para optimizar búsquedas
    INDEX idx_identification (identification),
    INDEX idx_full_name (full_name),
    INDEX idx_is_active (is_active),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Verificar resultado
-- =====================================================
SELECT 'Tabla de pacientes lista' AS mensaje;
SELECT COUNT(*) AS total_pacientes FROM pacientes;

-- Mostrar estructura de la tabla
DESCRIBE pacientes;
