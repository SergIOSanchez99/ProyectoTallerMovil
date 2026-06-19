-- =====================================================
-- Script de Creación - Tabla de Estudios/Reportes
-- Proyecto Taller Móvil - Detectives
-- 
-- Este script crea la tabla de estudios para almacenar
-- los análisis de imágenes de colonoscopia de forma persistente
-- =====================================================

-- Usar la base de datos
USE taller_movil_db;

-- =====================================================
-- Eliminar tabla si existe (solo para desarrollo)
-- Descomenta la siguiente línea si quieres recrear la tabla desde cero
-- =====================================================
-- DROP TABLE IF EXISTS estudios;

-- =====================================================
-- Crear tabla de Estudios
-- =====================================================
CREATE TABLE IF NOT EXISTS estudios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NULL COMMENT 'ID del paciente asociado (opcional)',
    user_id INT NULL COMMENT 'ID del usuario que creó el estudio',
    result VARCHAR(255) NOT NULL COMMENT 'Resultado del análisis (Normal, Anomalía, etc.)',
    stage VARCHAR(255) NULL COMMENT 'Etapa del análisis',
    confidence DECIMAL(5, 4) NULL COMMENT 'Nivel de confianza del análisis (0.0000 a 1.0000)',
    risk_level VARCHAR(50) NULL COMMENT 'Nivel de riesgo (Bajo, Medio, Alto)',
    image_path VARCHAR(500) NULL COMMENT 'Ruta de la imagen analizada (opcional)',
    study_date DATE NULL COMMENT 'Fecha del estudio',
    doctor_name VARCHAR(255) NULL COMMENT 'Nombre del médico responsable',
    observations TEXT NULL COMMENT 'Observaciones adicionales',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creación del registro',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Fecha de última actualización',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'Indica si el estudio está activo',
    
    -- Claves foráneas (opcionales)
    FOREIGN KEY (patient_id) REFERENCES pacientes(id) ON DELETE SET NULL,
    
    -- Índices para optimizar búsquedas
    INDEX idx_patient_id (patient_id),
    INDEX idx_user_id (user_id),
    INDEX idx_study_date (study_date),
    INDEX idx_result (result),
    INDEX idx_risk_level (risk_level),
    INDEX idx_is_active (is_active),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Tabla para almacenar estudios y análisis de colonoscopia';

-- =====================================================
-- Verificar la creación de la tabla
-- =====================================================
SELECT 'Tabla de estudios creada exitosamente' AS mensaje;
SELECT COUNT(*) AS total_estudios FROM estudios;

