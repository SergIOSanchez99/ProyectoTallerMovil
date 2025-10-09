"""
Presentation Layer - API Controller
Maneja las peticiones HTTP y respuestas de la API
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
from datetime import datetime

from ..business.services.analysis_service import AnalysisService
from ..business.services.health_service import HealthService
from ..infrastructure.exceptions.api_exceptions import APIException, ValidationError

class APIController:
    """Controlador principal de la API"""
    
    def __init__(self):
        self.app = Flask(__name__)
        CORS(self.app)
        self.analysis_service = AnalysisService()
        self.health_service = HealthService()
        
        # Configurar logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
        self._setup_routes()
        self._setup_error_handlers()
    
    def _setup_routes(self):
        """Configurar rutas de la API"""
        
        @self.app.route('/health', methods=['GET'])
        def health_check():
            """Endpoint de salud del sistema"""
            try:
                result = self.health_service.check_system_health()
                return jsonify({
                    "status": "OK",
                    "message": "Sistema funcionando correctamente",
                    "timestamp": datetime.now().isoformat(),
                    **result
                }), 200
            except Exception as e:
                self.logger.error(f"Error en health check: {e}")
                return jsonify({
                    "status": "ERROR",
                    "message": "Error interno del servidor"
                }), 500
        
        @self.app.route('/predict', methods=['POST'])
        def predict():
            """Endpoint para análisis de imágenes"""
            try:
                # Validar entrada
                if not request.is_json:
                    raise ValidationError("Content-Type debe ser application/json")
                
                data = request.get_json()
                if 'image' not in data:
                    raise ValidationError("Campo 'image' es requerido")
                
                # Procesar análisis
                result = self.analysis_service.analyze_image(data['image'])
                
                return jsonify({
                    "success": True,
                    "timestamp": datetime.now().isoformat(),
                    **result
                }), 200
                
            except ValidationError as e:
                self.logger.warning(f"Error de validación: {e}")
                return jsonify({
                    "success": False,
                    "error": str(e)
                }), 400
                
            except APIException as e:
                self.logger.error(f"Error de API: {e}")
                return jsonify({
                    "success": False,
                    "error": str(e)
                }), e.status_code
                
            except Exception as e:
                self.logger.error(f"Error interno: {e}")
                return jsonify({
                    "success": False,
                    "error": "Error interno del servidor"
                }), 500
    
    def _setup_error_handlers(self):
        """Configurar manejadores de errores"""
        
        @self.app.errorhandler(404)
        def not_found(error):
            return jsonify({
                "success": False,
                "error": "Endpoint no encontrado"
            }), 404
        
        @self.app.errorhandler(405)
        def method_not_allowed(error):
            return jsonify({
                "success": False,
                "error": "Método no permitido"
            }), 405
    
    def run(self, host='0.0.0.0', port=5000, debug=False):
        """Ejecutar la aplicación"""
        self.logger.info(f"🚀 Iniciando API en http://{host}:{port}")
        self.app.run(host=host, port=port, debug=debug)


