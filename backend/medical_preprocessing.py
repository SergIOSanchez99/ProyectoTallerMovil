import numpy as np
import cv2
from PIL import Image
import base64
from io import BytesIO
from scipy import ndimage
from skimage import filters, exposure, morphology, measure
from skimage.segmentation import watershed
from skimage.feature import peak_local_maxima
from skimage.morphology import disk
import tensorflow as tf

class MedicalImagePreprocessor:
    """Preprocesador avanzado para imágenes médicas de colonoscopia"""
    
    def __init__(self):
        self.target_size = (224, 224)
        
    def preprocess_image(self, image_data, apply_medical_enhancement=True):
        """
        Preprocesar imagen para análisis médico
        
        Args:
            image_data: Imagen en formato base64 o array numpy
            apply_medical_enhancement: Si aplicar mejoras médicas específicas
        
        Returns:
            imagen preprocesada lista para el modelo
        """
        try:
            # Convertir base64 a imagen si es necesario
            if isinstance(image_data, str):
                img = self._base64_to_image(image_data)
            else:
                img = image_data
            
            # Validar imagen
            if not self._validate_image(img):
                return None
            
            # Aplicar mejoras médicas si se solicita
            if apply_medical_enhancement:
                img = self._apply_medical_enhancements(img)
            
            # Redimensionar
            img = self._resize_image(img)
            
            # Normalizar
            img = self._normalize_image(img)
            
            # Expandir dimensión para el modelo
            img = np.expand_dims(img, axis=0)
            
            return img
            
        except Exception as e:
            print(f"❌ Error en preprocesamiento: {e}")
            return None
    
    def _base64_to_image(self, image_data):
        """Convertir base64 a imagen PIL"""
        img_data = base64.b64decode(image_data)
        img = Image.open(BytesIO(img_data))
        
        if img.mode != 'RGB':
            img = img.convert('RGB')
            
        return np.array(img)
    
    def _validate_image(self, img):
        """Validar que la imagen sea adecuada para análisis"""
        if img is None or img.size == 0:
            return False
        
        # Verificar dimensiones mínimas
        if img.shape[0] < 64 or img.shape[1] < 64:
            return False
        
        # Verificar que no esté completamente oscura o clara
        gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
        mean_intensity = np.mean(gray)
        
        if mean_intensity < 10 or mean_intensity > 245:
            return False
        
        return True
    
    def _apply_medical_enhancements(self, img):
        """Aplicar mejoras específicas para imágenes médicas"""
        # 1. Reducir ruido preservando bordes
        img = cv2.bilateralFilter(img, 9, 75, 75)
        
        # 2. Mejorar contraste adaptativo
        img = self._enhance_tissue_contrast(img)
        
        # 3. Corregir iluminación desigual
        img = self._correct_illumination(img)
        
        # 4. Realzar texturas importantes
        img = self._enhance_textures(img)
        
        # 5. Remover artefactos de compresión
        img = self._remove_compression_artifacts(img)
        
        return img
    
    def _enhance_tissue_contrast(self, img):
        """Mejorar contraste de tejidos usando CLAHE"""
        # Convertir a LAB
        lab = cv2.cvtColor(img, cv2.COLOR_RGB2LAB)
        
        # Aplicar CLAHE al canal L
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
        lab[:, :, 0] = clahe.apply(lab[:, :, 0])
        
        # Convertir de vuelta a RGB
        enhanced = cv2.cvtColor(lab, cv2.COLOR_LAB2RGB)
        
        return enhanced
    
    def _correct_illumination(self, img):
        """Corregir iluminación desigual"""
        # Convertir a escala de grises
        gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
        
        # Crear kernel para estimar iluminación
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (50, 50))
        
        # Estimar fondo
        background = cv2.morphologyEx(gray, cv2.MORPH_CLOSE, kernel)
        
        # Normalizar por el fondo
        normalized = cv2.divide(gray, background, scale=255)
        
        # Aplicar la corrección a cada canal
        corrected = img.copy().astype(np.float32)
        for i in range(3):
            corrected[:, :, i] = corrected[:, :, i] * (normalized / 255.0)
        
        return np.clip(corrected, 0, 255).astype(np.uint8)
    
    def _enhance_textures(self, img):
        """Realzar texturas importantes para diagnóstico"""
        # Convertir a escala de grises
        gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
        
        # Aplicar filtro de realce unsharp mask
        blurred = cv2.GaussianBlur(gray, (0, 0), 2.0)
        enhanced = cv2.addWeighted(gray, 1.5, blurred, -0.5, 0)
        
        # Aplicar filtro de bordes para realzar estructuras
        edges = cv2.Laplacian(enhanced, cv2.CV_64F)
        edges = np.uint8(np.absolute(edges))
        
        # Combinar con la imagen original
        result = img.copy().astype(np.float32)
        for i in range(3):
            result[:, :, i] = result[:, :, i] + edges * 0.1
        
        return np.clip(result, 0, 255).astype(np.uint8)
    
    def _remove_compression_artifacts(self, img):
        """Remover artefactos de compresión"""
        # Convertir a escala de grises
        gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
        
        # Detectar bloques de compresión
        kernel = np.ones((8, 8), np.uint8)
        
        # Aplicar filtro de mediana para suavizar artefactos
        filtered = cv2.medianBlur(gray, 3)
        
        # Aplicar la mejora a cada canal
        result = img.copy().astype(np.float32)
        for i in range(3):
            channel = result[:, :, i]
            # Combinar canal original con filtrado
            result[:, :, i] = 0.7 * channel + 0.3 * filtered
        
        return np.clip(result, 0, 255).astype(np.uint8)
    
    def _resize_image(self, img):
        """Redimensionar imagen manteniendo aspecto"""
        return cv2.resize(img, self.target_size, interpolation=cv2.INTER_LANCZOS4)
    
    def _normalize_image(self, img):
        """Normalizar imagen para el modelo"""
        # Convertir a float32
        img = img.astype(np.float32)
        
        # Normalizar a [0, 1]
        img = img / 255.0
        
        # Aplicar normalización específica para modelos pre-entrenados
        mean = np.array([0.485, 0.456, 0.406])
        std = np.array([0.229, 0.224, 0.225])
        
        img = (img - mean) / std
        
        return img
    
    def extract_medical_features(self, img):
        """Extraer características médicas relevantes"""
        features = {}
        
        # Convertir a escala de grises
        gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
        
        # 1. Análisis de textura
        features['texture_energy'] = self._calculate_texture_energy(gray)
        features['texture_contrast'] = self._calculate_texture_contrast(gray)
        
        # 2. Análisis de color
        features['color_variance'] = self._calculate_color_variance(img)
        features['dominant_color'] = self._get_dominant_color(img)
        
        # 3. Análisis de forma
        features['edge_density'] = self._calculate_edge_density(gray)
        features['circularity'] = self._calculate_circularity(gray)
        
        # 4. Análisis de iluminación
        features['brightness'] = np.mean(gray)
        features['contrast'] = np.std(gray)
        
        return features
    
    def _calculate_texture_energy(self, gray):
        """Calcular energía de textura usando filtros Gabor"""
        # Aplicar filtro de Gabor
        gabor = filters.gabor(gray, frequency=0.1)[0]
        return np.mean(gabor ** 2)
    
    def _calculate_texture_contrast(self, gray):
        """Calcular contraste de textura"""
        # Aplicar filtro de Laplaciano
        laplacian = cv2.Laplacian(gray, cv2.CV_64F)
        return np.var(laplacian)
    
    def _calculate_color_variance(self, img):
        """Calcular varianza de color"""
        return np.var(img, axis=(0, 1)).tolist()
    
    def _get_dominant_color(self, img):
        """Obtener color dominante"""
        # Reducir colores
        data = img.reshape((-1, 3))
        data = np.float32(data)
        
        # Aplicar k-means
        criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 20, 1.0)
        _, labels, centers = cv2.kmeans(data, 1, None, criteria, 10, cv2.KMEANS_RANDOM_CENTERS)
        
        return centers[0].tolist()
    
    def _calculate_edge_density(self, gray):
        """Calcular densidad de bordes"""
        edges = cv2.Canny(gray, 50, 150)
        return np.sum(edges > 0) / edges.size
    
    def _calculate_circularity(self, gray):
        """Calcular circularidad de estructuras"""
        # Binarizar imagen
        _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        
        # Encontrar contornos
        contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if len(contours) == 0:
            return 0
        
        # Calcular circularidad del contorno más grande
        largest_contour = max(contours, key=cv2.contourArea)
        area = cv2.contourArea(largest_contour)
        perimeter = cv2.arcLength(largest_contour, True)
        
        if perimeter == 0:
            return 0
        
        circularity = 4 * np.pi * area / (perimeter ** 2)
        return circularity
    
    def create_attention_map(self, img, model):
        """Crear mapa de atención para visualizar áreas importantes"""
        # Esta función sería implementada con Grad-CAM o similar
        # Por ahora, retornamos un mapa básico
        gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
        
        # Detectar bordes como proxy de atención
        edges = cv2.Canny(gray, 50, 150)
        
        # Dilatar para crear áreas de atención
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        attention_map = cv2.dilate(edges, kernel, iterations=2)
        
        return attention_map

def preprocess_for_inference(image_data, target_size=(224, 224)):
    """Función de conveniencia para preprocesamiento rápido"""
    preprocessor = MedicalImagePreprocessor()
    preprocessor.target_size = target_size
    
    return preprocessor.preprocess_image(image_data, apply_medical_enhancement=True)

if __name__ == "__main__":
    print("🏥 Sistema de Preprocesamiento Médico Avanzado")
    print("=" * 50)
    
    preprocessor = MedicalImagePreprocessor()
    
    print("✅ Funciones disponibles:")
    print("   - preprocess_image(): Preprocesamiento completo")
    print("   - extract_medical_features(): Extracción de características")
    print("   - create_attention_map(): Mapa de atención")
    print("   - Mejoras médicas específicas para colonoscopia")


