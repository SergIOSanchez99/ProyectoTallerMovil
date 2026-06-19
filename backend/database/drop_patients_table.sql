-- =====================================================
-- Script para Borrar Tabla de Pacientes
-- Proyecto Taller Móvil
-- =====================================================

USE taller_movil_db;

-- Borrar la tabla pacientes si existe
DROP TABLE IF EXISTS pacientes;

SELECT 'Tabla pacientes eliminada exitosamente' AS mensaje;

