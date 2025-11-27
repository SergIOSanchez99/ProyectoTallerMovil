"""
Infrastructure Layer - Segmentation Processor
Procesador de imágenes para segmentación semántica
"""

import numpy as np
import base64
from io import BytesIO
from PIL import Image
import logging
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../../'))
from config.settings import Settings

from .exceptions.api_exceptions import ImageProcessingError

class SegmentationProcessor:
    """Procesador de imágenes para segmentación semántica"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    def decode_image(self, image_data: str) -> Image.Image:
        """
        Decodifica una imagen desde base64
        
        Args:
            image_data: Imagen en formato base64
            
        Returns:
            Imagen PIL
        """
        try:
            img_data = base64.b64decode(image_data)
            img = Image.open(BytesIO(img_data))
            
            # Convertir a RGB si es necesario
            if img.mode != 'RGB':
                img = img.convert('RGB')
            
            return img
            
        except Exception as e:
            self.logger.error(f"Error decodificando imagen: {e}")
            raise ImageProcessingError(f"Error decodificando imagen: {str(e)}")
    
    def create_segmentation_mask(self, image: Image.Image) -> np.ndarray:
        """
        Crea una máscara de segmentación simulada
        En producción, esto sería reemplazado por un modelo de segmentación real
        
        Args:
            image: Imagen PIL
            
        Returns:
            Máscara de segmentación como array numpy (H, W) con valores:
            0 = background
            1 = tejido sano
            2 = tejido canceroso
        """
        try:
            img_array = np.array(image)
            h, w = img_array.shape[:2]
            
            # Crear máscara simulada basada en características de la imagen
            mask = np.zeros((h, w), dtype=np.uint8)
            
            # Convertir a escala de grises para análisis
            gray = np.mean(img_array, axis=2) if len(img_array.shape) == 3 else img_array
            
            # Normalizar
            gray_norm = (gray - gray.min()) / (gray.max() - gray.min() + 1e-10)
            
            # Detectar regiones más oscuras (posible tejido)
            tissue_mask = gray_norm < 0.8
            
            # Simular detección de cáncer basado en textura/intensidad
            # En una implementación real, esto vendría de un modelo entrenado
            cancer_indicators = (
                (gray_norm > 0.3) & (gray_norm < 0.6) & 
                (np.std(img_array, axis=2) > 30 if len(img_array.shape) == 3 else np.zeros_like(gray_norm) > 30)
            )
            
            # Asignar clases
            mask[tissue_mask & cancer_indicators] = 2  # Tejido canceroso
            mask[tissue_mask & ~cancer_indicators] = 1  # Tejido sano
            mask[~tissue_mask] = 0  # Background
            
            # Aplicar suavizado para hacer más realista (opcional)
            try:
                from scipy import ndimage
                mask = ndimage.gaussian_filter(mask.astype(float), sigma=2)
                mask = np.round(mask).astype(np.uint8)
            except ImportError:
                # Si scipy no está disponible, continuar sin suavizado
                self.logger.debug("scipy no disponible, omitiendo suavizado")
                pass
            
            return mask
            
        except Exception as e:
            self.logger.error(f"Error creando máscara de segmentación: {e}")
            raise ImageProcessingError(f"Error creando máscara: {str(e)}")
    
    def colorize_segmentation(self, image: Image.Image, mask: np.ndarray, alpha: float = 0.5) -> Image.Image:
        """
        Colorea la segmentación sobre la imagen original
        
        Args:
            image: Imagen original PIL
            mask: Máscara de segmentación (H, W) con valores 0, 1, 2
            alpha: Transparencia del overlay (0-1)
            
        Returns:
            Imagen coloreada PIL
        """
        try:
            # Convertir imagen a array
            img_array = np.array(image)
            
            # Crear imagen de colores para la máscara
            colored_mask = np.zeros_like(img_array)
            
            # Colores para cada clase
            colors = {
                0: [0, 0, 0],          # Background - negro/transparente
                1: [0, 255, 0],        # Tejido sano - verde
                2: [255, 0, 0],        # Tejido canceroso - rojo
            }
            
            for class_id, color in colors.items():
                mask_class = (mask == class_id)
                colored_mask[mask_class] = color
            
            # Combinar imagen original con máscara coloreada
            overlay = (alpha * colored_mask + (1 - alpha) * img_array).astype(np.uint8)
            
            # Convertir de vuelta a PIL
            result_image = Image.fromarray(overlay)
            
            return result_image
            
        except Exception as e:
            self.logger.error(f"Error coloreando segmentación: {e}")
            raise ImageProcessingError(f"Error coloreando segmentación: {str(e)}")
    
    def mask_to_base64(self, image: Image.Image) -> str:
        """
        Convierte una imagen PIL a base64
        
        Args:
            image: Imagen PIL
            
        Returns:
            String base64 de la imagen
        """
        try:
            buffer = BytesIO()
            image.save(buffer, format='PNG')
            img_bytes = buffer.getvalue()
            img_base64 = base64.b64encode(img_bytes).decode('utf-8')
            return img_base64
            
        except Exception as e:
            self.logger.error(f"Error convirtiendo imagen a base64: {e}")
            raise ImageProcessingError(f"Error convirtiendo imagen: {str(e)}")
    
    def get_segmentation_stats(self, mask: np.ndarray) -> dict:
        """
        Calcula estadísticas de la segmentación
        
        Args:
            mask: Máscara de segmentación
            
        Returns:
            Diccionario con estadísticas
        """
        try:
            total_pixels = mask.size
            background_pixels = np.sum(mask == 0)
            healthy_pixels = np.sum(mask == 1)
            cancerous_pixels = np.sum(mask == 2)
            
            return {
                "total_pixels": int(total_pixels),
                "background_pixels": int(background_pixels),
                "healthy_pixels": int(healthy_pixels),
                "cancerous_pixels": int(cancerous_pixels),
                "background_percentage": float(background_pixels / total_pixels * 100),
                "healthy_percentage": float(healthy_pixels / total_pixels * 100),
                "cancerous_percentage": float(cancerous_pixels / total_pixels * 100),
            }
            
        except Exception as e:
            self.logger.error(f"Error calculando estadísticas: {e}")
            return {}

