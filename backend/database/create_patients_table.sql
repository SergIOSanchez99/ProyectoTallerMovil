-- =====================================================
-- Script de Creación - Tabla de Pacientes
-- Proyecto Taller Móvil - Detectives
-- 
-- Este script crea la tabla de pacientes para que los usuarios
-- puedan registrar pacientes al generar reportes
-- =====================================================

-- Usar la base de datos
USE taller_movil_db;

-- =====================================================
-- Eliminar tabla si existe (solo para desarrollo)
-- Descomenta la siguiente línea si quieres recrear la tabla desde cero
-- =====================================================
-- DROP TABLE IF EXISTS pacientes;

-- =====================================================
-- Crear tabla de Pacientes
-- =====================================================
CREATE TABLE IF NOT EXISTS pacientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL COMMENT 'Nombre completo del paciente',
    identification VARCHAR(50) NOT NULL UNIQUE COMMENT 'Número de identificación único del paciente',
    age INT NULL COMMENT 'Edad del paciente',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creación del registro',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Fecha de última actualización',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'Indica si el paciente está activo',
    
    -- Índices para optimizar búsquedas
    INDEX idx_identification (identification),
    INDEX idx_full_name (full_name),
    INDEX idx_is_active (is_active),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Tabla para almacenar información de pacientes registrados en el sistema';

-- =====================================================
-- Verificar la creación de la tabla
-- =====================================================
SELECT 'Tabla de pacientes creada exitosamente' AS mensaje;
SELECT COUNT(*) AS total_pacientes FROM pacientes;

-- =====================================================
-- Mostrar estructura de la tabla
-- =====================================================
DESCRIBE pacientes;

-- =====================================================
-- Consultas útiles para verificar
-- =====================================================
-- Ver todos los pacientes activos
-- SELECT * FROM pacientes WHERE is_active = TRUE ORDER BY full_name ASC;

-- Buscar paciente por identificación
-- SELECT * FROM pacientes WHERE identification = '1234567890' AND is_active = TRUE;

-- Buscar paciente por nombre
-- SELECT * FROM pacientes WHERE full_name LIKE '%nombre%' AND is_active = TRUE ORDER BY full_name ASC;

-- Contar pacientes activos
-- SELECT COUNT(*) AS total_pacientes_activos FROM pacientes WHERE is_active = TRUE;

