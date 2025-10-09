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


