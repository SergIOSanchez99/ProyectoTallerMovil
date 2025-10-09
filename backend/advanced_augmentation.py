import numpy as np
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.utils import to_categorical
import cv2
from scipy import ndimage
from skimage import filters, exposure, morphology
import albumentations as A

class AdvancedDataAugmentation:
    """Clase para data augmentation avanzado específico para imágenes médicas"""
    
    def __init__(self):
        self.medical_transforms = self._create_medical_transforms()
        self.standard_transforms = self._create_standard_transforms()
    
    def _create_medical_transforms(self):
        """Transformaciones específicas para imágenes médicas"""
        return A.Compose([
            # Transformaciones de intensidad (simulan diferentes condiciones de iluminación)
            A.RandomBrightnessContrast(
                brightness_limit=0.2,
                contrast_limit=0.2,
                p=0.8
            ),
            
            # Simular diferentes calidades de imagen
            A.OneOf([
                A.GaussNoise(var_limit=(10.0, 50.0), p=0.3),
                A.GaussianBlur(blur_limit=(1, 3), p=0.3),
                A.MotionBlur(blur_limit=3, p=0.3),
            ], p=0.5),
            
            # Transformaciones geométricas conservadoras
            A.Rotate(limit=15, p=0.7),
            A.HorizontalFlip(p=0.5),
            A.VerticalFlip(p=0.3),
            
            # Transformaciones de escala y perspectiva
            A.ShiftScaleRotate(
                shift_limit=0.1,
                scale_limit=0.1,
                rotate_limit=10,
                p=0.7
            ),
            
            # Simular diferentes ángulos de captura
            A.Perspective(scale=(0.05, 0.1), p=0.3),
            
            # Mejoras de calidad de imagen
            A.OneOf([
                A.CLAHE(clip_limit=2, p=0.3),
                A.Equalize(p=0.3),
                A.RandomGamma(gamma_limit=(80, 120), p=0.3),
            ], p=0.6),
            
            # Simular artefactos de compresión
            A.ImageCompression(quality_lower=85, quality_upper=100, p=0.3),
            
            # Normalización
            A.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
    
    def _create_standard_transforms(self):
        """Transformaciones estándar para comparación"""
        return A.Compose([
            A.RandomBrightnessContrast(brightness_limit=0.2, contrast_limit=0.2, p=0.8),
            A.Rotate(limit=20, p=0.7),
            A.HorizontalFlip(p=0.5),
            A.GaussNoise(var_limit=(10.0, 50.0), p=0.3),
            A.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
    
    def apply_medical_preprocessing(self, image):
        """Preprocesamiento específico para imágenes médicas"""
        # Convertir a float32
        image = image.astype(np.float32)
        
        # Aplicar filtro para reducir ruido
        image = cv2.bilateralFilter(image, 9, 75, 75)
        
        # Mejora del contraste usando CLAHE
        lab = cv2.cvtColor(image.astype(np.uint8), cv2.COLOR_RGB2LAB)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
        lab[:,:,0] = clahe.apply(lab[:,:,0])
        image = cv2.cvtColor(lab, cv2.COLOR_LAB2RGB).astype(np.float32)
        
        # Normalización
        image = image / 255.0
        
        return image
    
    def create_advanced_datagen(self, target_size=(224, 224)):
        """Crear generador de datos avanzado"""
        return ImageDataGenerator(
            rescale=1./255,
            rotation_range=15,
            width_shift_range=0.1,
            height_shift_range=0.1,
            shear_range=0.1,
            zoom_range=0.1,
            horizontal_flip=True,
            vertical_flip=False,
            fill_mode='nearest',
            brightness_range=[0.8, 1.2],
            channel_shift_range=20.0
        )
    
    def apply_albumentations(self, image, mask=None, use_medical=True):
        """Aplicar transformaciones de Albumentations"""
        transforms = self.medical_transforms if use_medical else self.standard_transforms
        
        if mask is not None:
            transformed = transforms(image=image, mask=mask)
            return transformed['image'], transformed['mask']
        else:
            transformed = transforms(image=image)
            return transformed['image']
    
    def create_synthetic_variations(self, image, num_variations=5):
        """Crear variaciones sintéticas de una imagen"""
        variations = []
        
        for _ in range(num_variations):
            # Aplicar preprocesamiento médico
            processed = self.apply_medical_preprocessing(image.copy())
            
            # Aplicar transformaciones
            augmented = self.apply_albumentations(processed)
            
            variations.append(augmented)
        
        return variations
    
    def balance_dataset(self, images, labels):
        """Balancear dataset usando técnicas de augmentación"""
        from collections import Counter
        
        label_counts = Counter(labels)
        max_count = max(label_counts.values())
        
        balanced_images = []
        balanced_labels = []
        
        for class_label in label_counts.keys():
            class_indices = [i for i, label in enumerate(labels) if label == class_label]
            class_images = [images[i] for i in class_indices]
            
            # Agregar imágenes originales
            balanced_images.extend(class_images)
            balanced_labels.extend([class_label] * len(class_images))
            
            # Generar variaciones para balancear
            if len(class_images) < max_count:
                needed = max_count - len(class_images)
                
                for i in range(needed):
                    # Seleccionar imagen aleatoria de la clase
                    random_idx = np.random.randint(0, len(class_images))
                    base_image = class_images[random_idx]
                    
                    # Crear variaciones
                    variations = self.create_synthetic_variations(base_image, num_variations=1)
                    
                    balanced_images.append(variations[0])
                    balanced_labels.append(class_label)
        
        return np.array(balanced_images), np.array(balanced_labels)

class MedicalImageProcessor:
    """Procesador específico para imágenes médicas"""
    
    @staticmethod
    def enhance_tissue_contrast(image):
        """Mejorar contraste de tejidos"""
        # Convertir a escala de grises para análisis
        gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        
        # Aplicar filtro de realce
        enhanced = filters.unsharp_mask(gray, radius=1, amount=2)
        
        # Convertir de vuelta a RGB
        enhanced_rgb = cv2.cvtColor(enhanced.astype(np.uint8), cv2.COLOR_GRAY2RGB)
        
        return enhanced_rgb
    
    @staticmethod
    def remove_background_noise(image, threshold=0.1):
        """Remover ruido de fondo"""
        # Convertir a escala de grises
        gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        
        # Crear máscara para áreas con poca información
        mask = gray > threshold * 255
        
        # Aplicar operaciones morfológicas
        kernel = morphology.disk(5)
        mask = morphology.binary_opening(mask, kernel)
        
        # Aplicar máscara a la imagen original
        result = image.copy()
        result[~mask] = 0
        
        return result
    
    @staticmethod
    def normalize_intensity(image):
        """Normalizar intensidad de la imagen"""
        # Convertir a float32
        img_float = image.astype(np.float32)
        
        # Normalizar por canal
        for i in range(3):
            channel = img_float[:, :, i]
            channel = (channel - channel.mean()) / (channel.std() + 1e-8)
            img_float[:, :, i] = channel
        
        # Escalar a [0, 1]
        img_float = (img_float - img_float.min()) / (img_float.max() - img_float.min())
        
        return (img_float * 255).astype(np.uint8)

def create_advanced_generators(train_dir, val_dir, target_size=(224, 224), batch_size=32):
    """Crear generadores avanzados para entrenamiento"""
    augmentor = AdvancedDataAugmentation()
    
    # Generador de entrenamiento con augmentación avanzada
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=15,
        width_shift_range=0.1,
        height_shift_range=0.1,
        shear_range=0.1,
        zoom_range=0.1,
        horizontal_flip=True,
        brightness_range=[0.8, 1.2],
        channel_shift_range=20.0,
        fill_mode='nearest'
    )
    
    # Generador de validación (sin augmentación)
    val_datagen = ImageDataGenerator(rescale=1./255)
    
    # Crear generadores
    train_generator = train_datagen.flow_from_directory(
        train_dir,
        target_size=target_size,
        batch_size=batch_size,
        class_mode='binary',
        shuffle=True,
        seed=42
    )
    
    val_generator = val_datagen.flow_from_directory(
        val_dir,
        target_size=target_size,
        batch_size=batch_size,
        class_mode='binary',
        shuffle=False,
        seed=42
    )
    
    return train_generator, val_generator

if __name__ == "__main__":
    print("🔬 Sistema de Data Augmentation Avanzado para Imágenes Médicas")
    print("=" * 60)
    
    # Ejemplo de uso
    augmentor = AdvancedDataAugmentation()
    processor = MedicalImageProcessor()
    
    print("✅ Clases de augmentación creadas:")
    print("   - AdvancedDataAugmentation: Augmentación médica específica")
    print("   - MedicalImageProcessor: Procesamiento de imágenes médicas")
    print("   - Generadores avanzados listos para usar")
