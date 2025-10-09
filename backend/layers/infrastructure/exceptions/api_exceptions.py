"""
Infrastructure Layer - Custom Exceptions
Excepciones personalizadas para la API
"""

class APIException(Exception):
    """Excepción base para errores de API"""
    
    def __init__(self, message: str, status_code: int = 500):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)

class ValidationError(APIException):
    """Error de validación de datos"""
    
    def __init__(self, message: str):
        super().__init__(message, 400)

class ModelNotAvailableError(APIException):
    """Error cuando el modelo no está disponible"""
    
    def __init__(self, message: str):
        super().__init__(message, 503)

class ImageProcessingError(APIException):
    """Error en procesamiento de imagen"""
    
    def __init__(self, message: str):
        super().__init__(message, 400)

class DatabaseError(APIException):
    """Error de base de datos"""
    
    def __init__(self, message: str):
        super().__init__(message, 500)


