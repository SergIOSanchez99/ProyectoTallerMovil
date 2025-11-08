#!/usr/bin/env python3
"""
Colon Cancer Detection API
Aplicación principal con arquitectura por capas
"""

import sys
import os
from pathlib import Path

# Detectar y usar el entorno virtual automáticamente
def setup_virtual_environment():
    """Configura el entorno virtual automáticamente si no está activo"""
    # Obtener el directorio del script actual
    script_dir = Path(__file__).parent.absolute()
    venv_path = script_dir / 'venv'
    
    # Verificar si ya estamos en un entorno virtual
    if hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix):
        # Ya estamos en un entorno virtual
        return True
    
    # Verificar si existe el entorno virtual
    if not venv_path.exists():
        print("❌ Error: No se encontró el entorno virtual en:", venv_path)
        print("   Por favor, crea el entorno virtual con: python -m venv venv")
        return False
    
    # Determinar el ejecutable de Python del entorno virtual
    if sys.platform == 'win32':
        python_exe = venv_path / 'Scripts' / 'python.exe'
    else:
        python_exe = venv_path / 'bin' / 'python'
    
    if not python_exe.exists():
        print("❌ Error: No se encontró Python en el entorno virtual:", python_exe)
        return False
    
    # Re-ejecutar con el Python del entorno virtual (silenciosamente)
    # Esto reemplazará el proceso actual con el Python del venv
    os.execv(str(python_exe), [str(python_exe)] + sys.argv)

# Intentar configurar el entorno virtual
try:
    # Verificar si tensorflow está disponible (indica que estamos en el venv)
    import tensorflow
    # Si llegamos aquí, tensorflow está disponible, continuar normalmente
except ImportError:
    # TensorFlow no está disponible, intentar usar el entorno virtual
    if not setup_virtual_environment():
        print("")
        print("=" * 60)
        print("  INSTRUCCIONES PARA EJECUTAR EL BACKEND")
        print("=" * 60)
        print("")
        print("Opción 1: Activar el entorno virtual primero")
        print("  Windows (PowerShell): .\\venv\\Scripts\\Activate.ps1")
        print("  Windows (CMD): venv\\Scripts\\activate.bat")
        print("  Linux/Mac: source venv/bin/activate")
        print("  Luego ejecuta: python app.py")
        print("")
        print("Opción 2: Usar el script de ejecución")
        print("  Windows: ejecutar_backend.bat o ejecutar_backend.ps1")
        print("  Linux/Mac: ./ejecutar_backend.sh")
        print("")
        print("Opción 3: Ejecutar directamente con el Python del venv")
        if sys.platform == 'win32':
            print(f"  {Path(__file__).parent / 'venv' / 'Scripts' / 'python.exe'} app.py")
        else:
            print(f"  {Path(__file__).parent / 'venv' / 'bin' / 'python'} app.py")
        print("")
        sys.exit(1)

import logging
from config.settings import Settings
from layers.presentation.api_controller import APIController

def setup_logging():
    """Configurar logging"""
    logging.basicConfig(
        level=getattr(logging, Settings.LOG_LEVEL),
        format=Settings.LOG_FORMAT
    )

def main():
    """Función principal"""
    setup_logging()
    logger = logging.getLogger(__name__)
    
    logger.info("🚀 Iniciando API de Detección de Cáncer de Colon")
    logger.info("=" * 50)
    
    try:
        # Crear controlador de API
        api_controller = APIController()
        
        # Ejecutar aplicación
        api_controller.run(
            host=Settings.API_HOST,
            port=Settings.API_PORT,
            debug=Settings.API_DEBUG
        )
        
    except Exception as e:
        logger.error(f"❌ Error iniciando aplicación: {e}")
        raise

if __name__ == '__main__':
    main()