"""
Business Layer - Analysis Service
Lógica de negocio para análisis de imágenes médicas
"""

import logging
from typing import Dict, Any
from datetime import datetime

from ...data.repositories.model_repository import ModelRepository
from ...infrastructure.exceptions.api_exceptions import ModelNotAvailableError
from ...infrastructure.image_processor import ImageProcessor
from ...infrastructure.confidence_scorer import ConfidenceScorer

class AnalysisService:
    """Servicio de análisis de imágenes médicas"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.model_repository = ModelRepository()
        self.image_processor = ImageProcessor()
        self.confidence_scorer = ConfidenceScorer()
    
    def analyze_image(self, image_data: str) -> Dict[str, Any]:
        """
        Analiza una imagen para detectar cáncer de colon
        
        Args:
            image_data: Imagen en formato base64
            
        Returns:
            Dict con resultado del análisis
        """
        try:
            # Verificar disponibilidad del modelo
            if not self.model_repository.is_model_available():
                raise ModelNotAvailableError("Modelo no disponible")
            
            # Procesar imagen
            processed_image = self.image_processor.process_image(image_data)
            
            # Realizar predicción
            prediction = self.model_repository.predict(processed_image)
            
            # Calcular confianza
            confidence_score = self.confidence_scorer.calculate_confidence(prediction)
            
            # Determinar resultado basado en la predicción
            result = self._determine_diagnosis(prediction, confidence_score)
            
            # Generar recomendaciones
            recommendations = self._generate_recommendations(result)
            
            return {
                "analysis_id": f"ana_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
                "result": result["diagnosis"],
                "stage": result["stage"],
                "confidence": float(prediction[0][0]),
                "confidence_score": confidence_score,
                "risk_level": result["risk_level"],
                "recommendation": recommendations,
                "processing_time": datetime.now().isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"Error en análisis: {e}")
            raise
    
    def _determine_diagnosis(self, prediction: float, confidence_score: float) -> Dict[str, str]:
        """
        Determina el diagnóstico basado en la predicción
        
        Args:
            prediction: Predicción del modelo
            confidence_score: Puntuación de confianza
            
        Returns:
            Dict con diagnóstico, etapa y nivel de riesgo
        """
        cancer_probability = float(prediction[0][0])
        
        # Clasificación basada en probabilidad y confianza
        if cancer_probability > 0.7 and confidence_score > 0.7:
            return {
                "diagnosis": "Cáncer de Colon Detectado",
                "stage": "Requiere atención médica inmediata",
                "risk_level": "Alto"
            }
        elif cancer_probability > 0.5:
            return {
                "diagnosis": "Posible Cáncer de Colon",
                "stage": "Requiere evaluación médica urgente",
                "risk_level": "Medio-Alto"
            }
        elif cancer_probability > 0.3:
            return {
                "diagnosis": "Anomalía Detectada",
                "stage": "Revisión médica recomendada",
                "risk_level": "Medio"
            }
        else:
            return {
                "diagnosis": "Tejido Benigno",
                "stage": "Sin signos de cáncer",
                "risk_level": "Bajo"
            }
    
    def _generate_recommendations(self, result: Dict[str, str]) -> str:
        """
        Genera recomendaciones basadas en el resultado
        
        Args:
            result: Resultado del diagnóstico
            
        Returns:
            Recomendación médica
        """
        risk_level = result["risk_level"]
        
        if risk_level == "Alto":
            return "Consulte con un especialista para confirmación y tratamiento inmediato"
        elif risk_level == "Medio-Alto":
            return "Programe una consulta médica lo antes posible"
        elif risk_level == "Medio":
            return "Consulte con su médico para seguimiento"
        else:
            return "Mantenga revisiones regulares según indicación médica"

    def segment_image(self, image_data: str, alpha: float = 0.5) -> Dict[str, Any]:
        """
        Segmenta una imagen para detectar áreas sanas, cancerosas y fondo
        
        Args:
            image_data: Imagen en formato base64
            alpha: Opacidad del overlay
            
        Returns:
            Dict con imagen segmentada en base64 y estadísticas
        """
        import base64
        from io import BytesIO
        from PIL import Image
        import numpy as np

        try:
            # 1. Decodificar base64
            if ',' in image_data:
                image_data = image_data.split(',')[-1]
            img_bytes = base64.b64decode(image_data)
            original_img = Image.open(BytesIO(img_bytes))

            # Asegurarse de que esté en modo RGB
            if original_img.mode != 'RGB':
                original_img = original_img.convert('RGB')

            # Convertir a numpy array para manipulación rápida
            img_np = np.array(original_img)
            height, width, _ = img_np.shape

            # Calcular luminosidad para cada píxel (Luma)
            luma = 0.299 * img_np[:, :, 0] + 0.587 * img_np[:, :, 1] + 0.114 * img_np[:, :, 2]

            # Crear máscaras según la luminosidad
            bg_mask = luma < 40
            cancer_mask = luma > 160
            healthy_mask = (luma >= 40) & (luma <= 160)

            # Inicializar imagen de salida con las mismas dimensiones
            segmented_np = np.copy(img_np)

            # Aplicar overlay
            # Background -> oscurecer
            segmented_np[bg_mask] = (img_np[bg_mask] * (1 - alpha)).astype(np.uint8)

            # Tejido canceroso -> blend con rojo (220, 30, 30)
            red_target = np.array([220, 30, 30], dtype=np.float32)
            segmented_np[cancer_mask] = ((img_np[cancer_mask] * (1 - alpha)) + (red_target * alpha)).astype(np.uint8)

            # Tejido sano -> blend con verde (30, 200, 30)
            green_target = np.array([30, 200, 30], dtype=np.float32)
            segmented_np[healthy_mask] = ((img_np[healthy_mask] * (1 - alpha)) + (green_target * alpha)).astype(np.uint8)

            # Convertir de nuevo a PIL Image
            segmented_img = Image.fromarray(segmented_np)

            # Guardar como PNG en BytesIO
            output_buffer = BytesIO()
            segmented_img.save(output_buffer, format="PNG")
            segmented_base64 = base64.b64encode(output_buffer.getvalue()).decode('utf-8')

            # Calcular estadísticas
            total_pixels = height * width
            bg_count = int(np.sum(bg_mask))
            cancer_count = int(np.sum(cancer_mask))
            healthy_count = int(np.sum(healthy_mask))

            stats = {
                "healthy_percentage": (healthy_count / total_pixels) * 100,
                "cancerous_percentage": (cancer_count / total_pixels) * 100,
                "background_percentage": (bg_count / total_pixels) * 100
            }

            return {
                "segmented_image": segmented_base64,
                "statistics": stats
            }

        except Exception as e:
            self.logger.error(f"Error realizando segmentación en backend: {e}")
            raise


