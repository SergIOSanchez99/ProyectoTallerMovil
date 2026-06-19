import tensorflow as tf
from tensorflow.keras.models import Sequential, Model
from tensorflow.keras.layers import (
    Conv2D, MaxPooling2D, Flatten, Dense, Dropout, 
    BatchNormalization, GlobalAveragePooling2D,
    Input, concatenate, Add
)
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.regularizers import l2
from tensorflow.keras.applications import EfficientNetB3, ResNet50V2
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
import numpy as np

class AdvancedColonCancerModel:
    """Modelo avanzado para detección de cáncer de colon con múltiples arquitecturas"""
    
    def __init__(self, input_shape=(224, 224, 3)):
        self.input_shape = input_shape
        self.models = {}
        
    def create_custom_cnn(self):
        """CNN personalizado con arquitectura mejorada"""
        model = Sequential([
            # Bloque 1
            Conv2D(32, (3, 3), activation='relu', input_shape=self.input_shape, 
                   kernel_regularizer=l2(0.001)),
            BatchNormalization(),
            Conv2D(32, (3, 3), activation='relu'),
            MaxPooling2D(2, 2),
            Dropout(0.25),
            
            # Bloque 2
            Conv2D(64, (3, 3), activation='relu', kernel_regularizer=l2(0.001)),
            BatchNormalization(),
            Conv2D(64, (3, 3), activation='relu'),
            MaxPooling2D(2, 2),
            Dropout(0.25),
            
            # Bloque 3
            Conv2D(128, (3, 3), activation='relu', kernel_regularizer=l2(0.001)),
            BatchNormalization(),
            Conv2D(128, (3, 3), activation='relu'),
            MaxPooling2D(2, 2),
            Dropout(0.25),
            
            # Bloque 4
            Conv2D(256, (3, 3), activation='relu', kernel_regularizer=l2(0.001)),
            BatchNormalization(),
            Conv2D(256, (3, 3), activation='relu'),
            GlobalAveragePooling2D(),
            Dropout(0.5),
            
            # Capas densas
            Dense(512, activation='relu', kernel_regularizer=l2(0.001)),
            BatchNormalization(),
            Dropout(0.5),
            Dense(256, activation='relu', kernel_regularizer=l2(0.001)),
            Dropout(0.3),
            Dense(1, activation='sigmoid')
        ])
        
        return model
    
    def create_efficientnet_model(self):
        """Modelo basado en EfficientNet (transfer learning)"""
        base_model = EfficientNetB3(
            weights='imagenet',
            include_top=False,
            input_shape=self.input_shape
        )
        
        # Congelar las primeras capas
        for layer in base_model.layers[:-20]:
            layer.trainable = False
            
        # Descongelar las últimas capas
        for layer in base_model.layers[-20:]:
            layer.trainable = True
        
        model = Sequential([
            base_model,
            GlobalAveragePooling2D(),
            Dense(512, activation='relu', kernel_regularizer=l2(0.001)),
            BatchNormalization(),
            Dropout(0.5),
            Dense(256, activation='relu', kernel_regularizer=l2(0.001)),
            Dropout(0.3),
            Dense(1, activation='sigmoid')
        ])
        
        return model
    
    def create_resnet_model(self):
        """Modelo basado en ResNet (transfer learning)"""
        base_model = ResNet50V2(
            weights='imagenet',
            include_top=False,
            input_shape=self.input_shape
        )
        
        # Congelar las primeras capas
        for layer in base_model.layers[:-20]:
            layer.trainable = False
            
        # Descongelar las últimas capas
        for layer in base_model.layers[-20:]:
            layer.trainable = True
        
        model = Sequential([
            base_model,
            GlobalAveragePooling2D(),
            Dense(512, activation='relu', kernel_regularizer=l2(0.001)),
            BatchNormalization(),
            Dropout(0.5),
            Dense(256, activation='relu', kernel_regularizer=l2(0.001)),
            Dropout(0.3),
            Dense(1, activation='sigmoid')
        ])
        
        return model
    
    def create_ensemble_model(self):
        """Modelo ensemble que combina múltiples arquitecturas"""
        input_layer = Input(shape=self.input_shape)
        
        # CNN personalizado
        custom_cnn = self.create_custom_cnn()
        custom_output = custom_cnn(input_layer)
        
        # EfficientNet
        efficientnet = self.create_efficientnet_model()
        eff_output = efficientnet(input_layer)
        
        # ResNet
        resnet = self.create_resnet_model()
        res_output = resnet(input_layer)
        
        # Combinar outputs
        combined = concatenate([custom_output, eff_output, res_output])
        
        # Capa final
        ensemble_output = Dense(1, activation='sigmoid', 
                               kernel_regularizer=l2(0.001))(combined)
        
        model = Model(inputs=input_layer, outputs=ensemble_output)
        return model
    
    def compile_model(self, model, learning_rate=0.0001):
        """Compilar modelo con optimizador avanzado"""
        optimizer = Adam(
            learning_rate=learning_rate,
            beta_1=0.9,
            beta_2=0.999,
            epsilon=1e-07
        )
        
        model.compile(
            optimizer=optimizer,
            loss='binary_crossentropy',
            metrics=['accuracy', 'precision', 'recall', 'auc']
        )
        
        return model
    
    def get_callbacks(self, model_name):
        """Callbacks avanzados para entrenamiento"""
        callbacks = [
            EarlyStopping(
                monitor='val_auc',
                patience=10,
                restore_best_weights=True,
                verbose=1
            ),
            ModelCheckpoint(
                f'{model_name}_best.h5',
                monitor='val_auc',
                save_best_only=True,
                verbose=1
            ),
            ReduceLROnPlateau(
                monitor='val_loss',
                factor=0.5,
                patience=5,
                min_lr=1e-7,
                verbose=1
            )
        ]
        
        return callbacks

def create_advanced_models():
    """Crear todos los modelos avanzados"""
    model_creator = AdvancedColonCancerModel(input_shape=(224, 224, 3))
    
    models = {
        'custom_cnn': model_creator.create_custom_cnn(),
        'efficientnet': model_creator.create_efficientnet_model(),
        'resnet': model_creator.create_resnet_model(),
        'ensemble': model_creator.create_ensemble_model()
    }
    
    # Compilar todos los modelos
    for name, model in models.items():
        model_creator.compile_model(model)
        models[name] = model
    
    return models

if __name__ == "__main__":
    print("🧠 Creando modelos avanzados para detección de cáncer de colon...")
    
    models = create_advanced_models()
    
    for name, model in models.items():
        print(f"\n📊 Modelo {name}:")
        print(f"   Parámetros totales: {model.count_params():,}")
        print(f"   Parámetros entrenables: {sum([tf.keras.backend.count_params(w) for w in model.trainable_weights]):,}")
        model.summary()
