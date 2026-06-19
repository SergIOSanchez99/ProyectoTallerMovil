"""
Infrastructure Layer - Image Processor
Procesamiento de imágenes médicas
"""

import numpy as np
import base64
from io import BytesIO
from PIL import Image
import logging

from .exceptions.api_exceptions import ImageProcessingError

class ImageProcessor:
    """Procesador de imágenes médicas"""
    
    def __init__(self, target_size: tuple = (128, 128)):
        self.target_size = target_size
        self.logger = logging.getLogger(__name__)
    
    def process_image(self, image_data: str) -> np.ndarray:
        """
        Procesa una imagen para análisis
        
        Args:
            image_data: Imagen en formato base64
            
        Returns:
            Imagen procesada como array numpy
            
        Raises:
            ImageProcessingError: Si hay error procesando la imagen
        """
        try:
            # Decodificar base64
            img_data = base64.b64decode(image_data)
            img = Image.open(BytesIO(img_data))
            
            # Convertir a RGB si es necesario
            if img.mode != 'RGB':
                img = img.convert('RGB')
            
            # Redimensionar
            img = img.resize(self.target_size)
            
            # Convertir a array y normalizar
            img_array = np.array(img) / 255.0
            
            # Agregar dimensión de batch
            img_array = np.expand_dims(img_array, axis=0)
            
            self.logger.info(f"Imagen procesada: shape {img_array.shape}")
            return img_array
            
        except Exception as e:
            self.logger.error(f"Error procesando imagen: {e}")
            raise ImageProcessingError(f"Error procesando imagen: {str(e)}")
    
    def validate_image(self, image_data: str) -> bool:
        """
        Valida que la imagen sea procesable
        
        Args:
            image_data: Imagen en formato base64
            
        Returns:
            True si la imagen es válida
        """
        try:
            img_data = base64.b64decode(image_data)
            img = Image.open(BytesIO(img_data))
            return True
        except Exception:
            return False


