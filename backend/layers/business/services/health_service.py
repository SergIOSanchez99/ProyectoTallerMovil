"""
Business Layer - Health Service
Lógica de negocio para verificación de salud del sistema
"""

import logging
from typing import Dict, Any

from ...data.repositories.model_repository import ModelRepository

class HealthService:
    """Servicio de salud del sistema"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.model_repository = ModelRepository()
    
    def check_system_health(self) -> Dict[str, Any]:
        """
        Verifica la salud del sistema
        
        Returns:
            Dict con estado de los componentes del sistema
        """
        health_status = {
            "model_loaded": False,
            "model_status": "unknown",
            "system_status": "healthy"
        }
        
        try:
            # Verificar modelo
            if self.model_repository.is_model_available():
                health_status["model_loaded"] = True
                health_status["model_status"] = "available"
            else:
                health_status["model_status"] = "not_available"
                health_status["system_status"] = "degraded"
                
        except Exception as e:
            self.logger.error(f"Error verificando salud del sistema: {e}")
            health_status["model_status"] = "error"
            health_status["system_status"] = "unhealthy"
        
        return health_status


