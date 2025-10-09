"""
Configuration Settings
Configuración de la aplicación
"""

import os

class Settings:
    """Configuración de la aplicación"""
    
    # API Settings
    API_HOST = os.getenv('API_HOST', '0.0.0.0')
    API_PORT = int(os.getenv('API_PORT', 5000))
    API_DEBUG = os.getenv('API_DEBUG', 'False').lower() == 'true'
    
    # Model Settings
    MODEL_PATH = os.getenv('MODEL_PATH', 'colon_cancer_binary_cnn.h5')
    TARGET_IMAGE_SIZE = (128, 128)
    
    # Logging Settings
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    
    # CORS Settings
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', '*').split(',')
    
    # Analysis Settings
    HIGH_CONFIDENCE_THRESHOLD = 0.7
    MEDIUM_CONFIDENCE_THRESHOLD = 0.4
    CANCER_THRESHOLD = 0.5


