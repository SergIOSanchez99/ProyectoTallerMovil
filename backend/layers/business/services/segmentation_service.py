"""
Business Layer - Segmentation Service
Lógica de negocio para segmentación de imágenes médicas
"""

import logging
from typing import Dict, Any
from datetime import datetime

from ...infrastructure.segmentation_processor import SegmentationProcessor
from ...infrastructure.exceptions.api_exceptions import ImageProcessingError

class SegmentationService:
    """Servicio de segmentación de imágenes médicas"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.segmentation_processor = SegmentationProcessor()
    
    def segment_image(self, image_data: str, alpha: float = 0.5) -> Dict[str, Any]:
        """
        Segmenta una imagen médica en tejidos sanos, cancerosos y background
        
        Args:
            image_data: Imagen en formato base64
            alpha: Transparencia del overlay (0-1)
            
        Returns:
            Dict con imagen segmentada y estadísticas
        """
        try:
            # Decodificar imagen
            original_image = self.segmentation_processor.decode_image(image_data)
            
            # Crear máscara de segmentación
            mask = self.segmentation_processor.create_segmentation_mask(original_image)
            
            # Colorear la segmentación
            segmented_image = self.segmentation_processor.colorize_segmentation(
                original_image, mask, alpha=alpha
            )
            
            # Convertir imagen segmentada a base64
            segmented_base64 = self.segmentation_processor.mask_to_base64(segmented_image)
            
            # Calcular estadísticas
            stats = self.segmentation_processor.get_segmentation_stats(mask)
            
            # Convertir imagen original a base64 también (por si se necesita)
            original_base64 = self.segmentation_processor.mask_to_base64(original_image)
            
            return {
                "segmentation_id": f"seg_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
                "original_image": original_base64,
                "segmented_image": segmented_base64,
                "width": original_image.width,
                "height": original_image.height,
                "statistics": stats,
                "processing_time": datetime.now().isoformat(),
                "legend": {
                    "background": {"color": [0, 0, 0], "description": "Fondo de la imagen"},
                    "healthy_tissue": {"color": [0, 255, 0], "description": "Tejido sano"},
                    "cancerous_tissue": {"color": [255, 0, 0], "description": "Tejido canceroso"}
                }
            }
            
        except ImageProcessingError as e:
            self.logger.error(f"Error de procesamiento en segmentación: {e}")
            raise
        except Exception as e:
            self.logger.error(f"Error en segmentación: {e}")
            raise Exception(f"Error en segmentación: {str(e)}")

