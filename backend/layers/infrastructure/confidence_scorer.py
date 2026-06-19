"""
Infrastructure Layer - Confidence Scorer
Cálculo de puntuaciones de confianza
"""

import numpy as np
import logging

class ConfidenceScorer:
    """Calculador de puntuaciones de confianza"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    def calculate_confidence(self, prediction: np.ndarray) -> float:
        """
        Calcula la puntuación de confianza basada en la predicción
        
        Args:
            prediction: Predicción del modelo
            
        Returns:
            Puntuación de confianza entre 0 y 1
        """
        try:
            # Usar la distancia desde 0.5 como medida de confianza
            prob = float(prediction[0][0])
            confidence = abs(prob - 0.5) * 2
            
            self.logger.info(f"Confianza calculada: {confidence:.4f}")
            return confidence
            
        except Exception as e:
            self.logger.error(f"Error calculando confianza: {e}")
            return 0.0
    
    def get_confidence_level(self, confidence_score: float) -> str:
        """
        Obtiene el nivel de confianza basado en la puntuación
        
        Args:
            confidence_score: Puntuación de confianza
            
        Returns:
            Nivel de confianza (Alto, Medio, Bajo)
        """
        if confidence_score >= 0.7:
            return "Alto"
        elif confidence_score >= 0.4:
            return "Medio"
        else:
            return "Bajo"


