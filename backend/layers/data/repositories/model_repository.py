"""
Data Layer - Model Repository
Acceso a datos del modelo de machine learning
"""

import logging
import numpy as np
from tensorflow.keras.models import load_model
import os
from typing import Optional

class ModelRepository:
    """Repositorio para el modelo de machine learning"""
    
    def __init__(self, model_path: str = "colon_cancer_binary_cnn.h5"):
        self.logger = logging.getLogger(__name__)
        self.model_path = model_path
        self.model = None
        self._load_model()
    
    def _load_model(self) -> None:
        """Cargar el modelo de machine learning"""
        try:
            if os.path.exists(self.model_path):
                self.model = load_model(self.model_path)
                self.logger.info("✅ Modelo cargado exitosamente")
            else:
                self.logger.error(f"❌ Archivo de modelo no encontrado: {self.model_path}")
                self.model = None
        except Exception as e:
            self.logger.error(f"❌ Error cargando modelo: {e}")
            self.model = None
    
    def is_model_available(self) -> bool:
        """
        Verifica si el modelo está disponible
        
        Returns:
            True si el modelo está cargado y listo
        """
        return self.model is not None
    
    def predict(self, image_data: np.ndarray) -> np.ndarray:
        """
        Realiza predicción con el modelo
        
        Args:
            image_data: Datos de imagen preprocesados
            
        Returns:
            Predicción del modelo
            
        Raises:
            ModelNotAvailableError: Si el modelo no está disponible
        """
        if not self.is_model_available():
            raise Exception("Modelo no disponible")
        
        try:
            prediction = self.model.predict(image_data, verbose=0)
            self.logger.info(f"Predicción realizada: {prediction[0][0]:.4f}")
            return prediction
        except Exception as e:
            self.logger.error(f"Error en predicción: {e}")
            raise
    
    def get_model_info(self) -> dict:
        """
        Obtiene información del modelo
        
        Returns:
            Dict con información del modelo
        """
        if not self.is_model_available():
            return {"status": "not_available"}
        
        return {
            "status": "available",
            "input_shape": self.model.input_shape,
            "output_shape": self.model.output_shape,
            "model_path": self.model_path
        }


