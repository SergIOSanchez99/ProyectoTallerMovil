#!/usr/bin/env python3
"""
Colon Cancer Detection API
Aplicación principal con arquitectura por capas
"""

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