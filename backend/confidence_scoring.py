import numpy as np
import tensorflow as tf
from scipy import stats
from sklearn.calibration import CalibratedClassifierCV
from sklearn.isotonic import IsotonicRegression
import warnings
warnings.filterwarnings('ignore')

class AdvancedConfidenceScorer:
    """Sistema avanzado de puntuación de confianza para diagnósticos médicos"""
    
    def __init__(self):
        self.calibration_model = None
        self.confidence_thresholds = {
            'very_low': 0.3,
            'low': 0.5,
            'medium': 0.7,
            'high': 0.85,
            'very_high': 0.95
        }
    
    def calculate_ensemble_confidence(self, predictions, weights=None):
        """
        Calcular confianza basada en predicciones de múltiples modelos
        
        Args:
            predictions: Lista de predicciones de diferentes modelos
            weights: Pesos para cada modelo (opcional)
        
        Returns:
            confianza promedio y desviación estándar
        """
        if weights is None:
            weights = [1.0 / len(predictions)] * len(predictions)
        
        # Calcular predicción ponderada
        weighted_prediction = np.average(predictions, weights=weights)
        
        # Calcular incertidumbre (desviación estándar)
        uncertainty = np.sqrt(np.average((predictions - weighted_prediction) ** 2, weights=weights))
        
        # Calcular confianza (inversa de la incertidumbre)
        confidence = 1.0 - uncertainty
        
        return weighted_prediction, confidence, uncertainty
    
    def calculate_prediction_confidence(self, model_output, method='entropy'):
        """
        Calcular confianza basada en la salida del modelo
        
        Args:
            model_output: Salida del modelo (probabilidades)
            method: Método para calcular confianza ('entropy', 'max_prob', 'variance')
        
        Returns:
            puntuación de confianza
        """
        if method == 'entropy':
            return self._entropy_based_confidence(model_output)
        elif method == 'max_prob':
            return self._max_probability_confidence(model_output)
        elif method == 'variance':
            return self._variance_based_confidence(model_output)
        else:
            raise ValueError(f"Método no soportado: {method}")
    
    def _entropy_based_confidence(self, probabilities):
        """Confianza basada en entropía"""
        # Para clasificación binaria, convertir a formato de 2 clases
        if len(probabilities.shape) == 1 or probabilities.shape[1] == 1:
            # Convertir probabilidad binaria a formato de 2 clases
            prob_0 = 1 - probabilities
            prob_1 = probabilities
            probs = np.column_stack([prob_0, prob_1])
        else:
            probs = probabilities
        
        # Calcular entropía
        entropy = -np.sum(probs * np.log(probs + 1e-10), axis=1)
        
        # Convertir entropía a confianza (menor entropía = mayor confianza)
        max_entropy = np.log(probs.shape[1])
        confidence = 1.0 - (entropy / max_entropy)
        
        return np.mean(confidence)
    
    def _max_probability_confidence(self, probabilities):
        """Confianza basada en la probabilidad máxima"""
        if len(probabilities.shape) == 1 or probabilities.shape[1] == 1:
            # Para clasificación binaria
            max_probs = np.maximum(probabilities, 1 - probabilities)
        else:
            max_probs = np.max(probabilities, axis=1)
        
        return np.mean(max_probs)
    
    def _variance_based_confidence(self, probabilities):
        """Confianza basada en la varianza de las predicciones"""
        if len(probabilities.shape) == 1 or probabilities.shape[1] == 1:
            # Para clasificación binaria, usar la varianza de la probabilidad
            variance = np.var(probabilities)
        else:
            # Para clasificación multiclase
            variance = np.mean(np.var(probabilities, axis=1))
        
        # Convertir varianza a confianza (menor varianza = mayor confianza)
        confidence = 1.0 / (1.0 + variance)
        return confidence
    
    def calibrate_confidence(self, predictions, true_labels):
        """
        Calibrar las puntuaciones de confianza usando calibración isotónica
        
        Args:
            predictions: Predicciones del modelo
            true_labels: Etiquetas verdaderas
        
        Returns:
            modelo de calibración entrenado
        """
        # Convertir a formato binario si es necesario
        if len(predictions.shape) == 1 or predictions.shape[1] == 1:
            # Para clasificación binaria
            if predictions.shape[1] == 1:
                predictions = predictions.flatten()
            
            # Crear matriz de probabilidades
            prob_matrix = np.column_stack([1 - predictions, predictions])
        else:
            prob_matrix = predictions
        
        # Entrenar modelo de calibración isotónica
        self.calibration_model = IsotonicRegression(out_of_bounds='clip')
        
        # Usar la probabilidad máxima como puntuación de confianza
        max_probs = np.max(prob_matrix, axis=1)
        
        # Entrenar con las probabilidades máximas
        self.calibration_model.fit(max_probs, true_labels)
        
        return self.calibration_model
    
    def get_calibrated_confidence(self, prediction):
        """Obtener confianza calibrada"""
        if self.calibration_model is None:
            return self._max_probability_confidence(prediction)
        
        # Obtener probabilidad máxima
        if len(prediction.shape) == 1 or prediction.shape[1] == 1:
            max_prob = np.maximum(prediction, 1 - prediction)
        else:
            max_prob = np.max(prediction, axis=1)
        
        # Aplicar calibración
        calibrated = self.calibration_model.transform(max_prob)
        
        return np.mean(calibrated)
    
    def calculate_medical_confidence(self, prediction, image_features=None):
        """
        Calcular confianza específica para diagnóstico médico
        
        Args:
            prediction: Predicción del modelo
            image_features: Características extraídas de la imagen
        
        Returns:
            confianza médica y factores de riesgo
        """
        # Confianza base del modelo
        base_confidence = self._max_probability_confidence(prediction)
        
        # Factores de confianza médica
        confidence_factors = {
            'model_confidence': base_confidence,
            'image_quality': 1.0,
            'feature_consistency': 1.0,
            'clinical_plausibility': 1.0
        }
        
        # Ajustar por calidad de imagen si se proporcionan características
        if image_features is not None:
            confidence_factors['image_quality'] = self._assess_image_quality(image_features)
            confidence_factors['feature_consistency'] = self._assess_feature_consistency(image_features)
            confidence_factors['clinical_plausibility'] = self._assess_clinical_plausibility(
                prediction, image_features
            )
        
        # Calcular confianza final ponderada
        weights = [0.4, 0.2, 0.2, 0.2]  # Pesos para cada factor
        final_confidence = sum(factor * weight for factor, weight in 
                             zip(confidence_factors.values(), weights))
        
        return final_confidence, confidence_factors
    
    def _assess_image_quality(self, features):
        """Evaluar calidad de imagen basada en características"""
        quality_score = 1.0
        
        # Evaluar contraste
        if 'contrast' in features:
            contrast = features['contrast']
            if contrast < 20 or contrast > 100:
                quality_score *= 0.8
        
        # Evaluar iluminación
        if 'brightness' in features:
            brightness = features['brightness']
            if brightness < 50 or brightness > 200:
                quality_score *= 0.9
        
        # Evaluar densidad de bordes
        if 'edge_density' in features:
            edge_density = features['edge_density']
            if edge_density < 0.1 or edge_density > 0.8:
                quality_score *= 0.85
        
        return min(quality_score, 1.0)
    
    def _assess_feature_consistency(self, features):
        """Evaluar consistencia de características"""
        consistency_score = 1.0
        
        # Verificar que las características estén en rangos esperados
        expected_ranges = {
            'texture_energy': (0.01, 1.0),
            'texture_contrast': (100, 10000),
            'circularity': (0.0, 1.0),
            'edge_density': (0.05, 0.7)
        }
        
        for feature, (min_val, max_val) in expected_ranges.items():
            if feature in features:
                value = features[feature]
                if value < min_val or value > max_val:
                    consistency_score *= 0.9
        
        return consistency_score
    
    def _assess_clinical_plausibility(self, prediction, features):
        """Evaluar plausibilidad clínica del diagnóstico"""
        plausibility_score = 1.0
        
        # Obtener probabilidad de cáncer
        if len(prediction.shape) == 1 or prediction.shape[1] == 1:
            cancer_prob = prediction[0] if len(prediction.shape) == 1 else prediction[0][0]
        else:
            cancer_prob = prediction[0][1]  # Asumiendo que la clase 1 es cáncer
        
        # Evaluar consistencia con características
        if 'texture_energy' in features and 'edge_density' in features:
            texture_energy = features['texture_energy']
            edge_density = features['edge_density']
            
            # Los tejidos cancerosos suelen tener mayor textura y densidad de bordes
            if cancer_prob > 0.7:
                if texture_energy < 0.1 or edge_density < 0.2:
                    plausibility_score *= 0.8
            elif cancer_prob < 0.3:
                if texture_energy > 0.5 and edge_density > 0.5:
                    plausibility_score *= 0.85
        
        return plausibility_score
    
    def get_confidence_level(self, confidence_score):
        """Obtener nivel de confianza cualitativo"""
        if confidence_score >= self.confidence_thresholds['very_high']:
            return 'very_high', 'Muy Alta'
        elif confidence_score >= self.confidence_thresholds['high']:
            return 'high', 'Alta'
        elif confidence_score >= self.confidence_thresholds['medium']:
            return 'medium', 'Media'
        elif confidence_score >= self.confidence_thresholds['low']:
            return 'low', 'Baja'
        else:
            return 'very_low', 'Muy Baja'
    
    def generate_confidence_report(self, prediction, image_features=None):
        """Generar reporte completo de confianza"""
        # Calcular confianza médica
        confidence, factors = self.calculate_medical_confidence(prediction, image_features)
        
        # Obtener nivel cualitativo
        level, level_name = self.get_confidence_level(confidence)
        
        # Generar recomendaciones
        recommendations = self._generate_recommendations(confidence, factors)
        
        return {
            'confidence_score': float(confidence),
            'confidence_level': level,
            'confidence_level_name': level_name,
            'confidence_factors': factors,
            'recommendations': recommendations,
            'requires_human_review': confidence < self.confidence_thresholds['medium']
        }
    
    def _generate_recommendations(self, confidence, factors):
        """Generar recomendaciones basadas en la confianza"""
        recommendations = []
        
        if confidence < self.confidence_thresholds['medium']:
            recommendations.append("Revisión médica especializada recomendada")
        
        if factors['image_quality'] < 0.8:
            recommendations.append("Considerar nueva imagen con mejor calidad")
        
        if factors['feature_consistency'] < 0.9:
            recommendations.append("Características de imagen inusuales detectadas")
        
        if factors['clinical_plausibility'] < 0.9:
            recommendations.append("Diagnóstico requiere validación clínica adicional")
        
        if not recommendations:
            recommendations.append("Diagnóstico confiable con seguimiento estándar")
        
        return recommendations

def calculate_ensemble_uncertainty(predictions_list):
    """Calcular incertidumbre de ensemble"""
    scorer = AdvancedConfidenceScorer()
    
    # Convertir a numpy array
    predictions = np.array(predictions_list)
    
    # Calcular estadísticas
    mean_prediction = np.mean(predictions, axis=0)
    std_prediction = np.std(predictions, axis=0)
    
    # Calcular confianza
    confidence, uncertainty = scorer.calculate_ensemble_confidence(predictions)
    
    return {
        'mean_prediction': mean_prediction.tolist(),
        'std_prediction': std_prediction.tolist(),
        'confidence': confidence,
        'uncertainty': uncertainty,
        'requires_ensemble': uncertainty > 0.2
    }

if __name__ == "__main__":
    print("🎯 Sistema de Puntuación de Confianza Avanzado")
    print("=" * 50)
    
    scorer = AdvancedConfidenceScorer()
    
    print("✅ Funciones disponibles:")
    print("   - calculate_ensemble_confidence(): Confianza de ensemble")
    print("   - calculate_medical_confidence(): Confianza médica específica")
    print("   - generate_confidence_report(): Reporte completo")
    print("   - Calibración isotónica para mejor precisión")


