-- =====================================================
-- Script de creación de Base de Datos MySQL
-- Proyecto Taller Móvil - Sistema de Usuarios
-- =====================================================

-- Eliminar base de datos si existe (solo para desarrollo)
-- DROP DATABASE IF EXISTS taller_movil_db;

-- Crear la base de datos
CREATE DATABASE IF NOT EXISTS taller_movil_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- Usar la base de datos
USE taller_movil_db;

-- =====================================================
-- Tabla de Usuarios
-- =====================================================
CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    profile_image VARCHAR(500) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Índices para optimizar búsquedas
    INDEX idx_email (email),
    INDEX idx_is_active (is_active),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Datos iniciales (usuarios de ejemplo)
-- =====================================================
INSERT INTO usuarios (id, email, password, name, created_at, is_active) VALUES
(1, 'wilfredo_guia@gmail.com', 'admin123', 'Administrador', '2024-01-01 00:00:00', TRUE),
(2, 'sergiosanchez@gmail.com', 'prueba', 'Usuario Prueba', '2024-01-02 00:00:00', TRUE)
ON DUPLICATE KEY UPDATE email=email;

-- =====================================================
-- Verificar la creación de la tabla
-- =====================================================
SELECT 'Base de datos y tabla creadas exitosamente' AS mensaje;
SELECT COUNT(*) AS total_usuarios FROM usuarios;

-- =====================================================
-- Consultas útiles para verificar
-- =====================================================
-- Ver todos los usuarios
-- SELECT * FROM usuarios;

-- Ver usuarios activos
-- SELECT id, email, name, created_at FROM usuarios WHERE is_active = TRUE;

-- Buscar usuario por email
-- SELECT * FROM usuarios WHERE email = 'wilfredo_guia@gmail.com';

-- =====================================================
-- Tabla de Pacientes
-- =====================================================
CREATE TABLE IF NOT EXISTS pacientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    identification VARCHAR(50) NOT NULL UNIQUE,
    age INT NULL,
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
-- Verificar la creación de la tabla de pacientes
-- =====================================================
SELECT 'Tabla de pacientes creada exitosamente' AS mensaje;
SELECT COUNT(*) AS total_pacientes FROM pacientes;

-- =====================================================
-- Consultas útiles para pacientes
-- =====================================================
-- Ver todos los pacientes
-- SELECT * FROM pacientes WHERE is_active = TRUE;

-- Buscar paciente por identificación
-- SELECT * FROM pacientes WHERE identification = '1234567890';

-- Buscar paciente por nombre
-- SELECT * FROM pacientes WHERE full_name LIKE '%nombre%' AND is_active = TRUE;

-- =====================================================
-- Comando para borrar la tabla pacientes (si es necesario)
-- =====================================================
-- Ejecuta este comando si necesitas eliminar la tabla:
-- DROP TABLE IF EXISTS pacientes;

