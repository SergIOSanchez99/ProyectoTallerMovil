import os
import numpy as np
import tensorflow as tf
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
import time

# Importar nuestros módulos mejorados
from advanced_model import AdvancedColonCancerModel
from advanced_augmentation import create_advanced_generators
from medical_preprocessing import MedicalImagePreprocessor

class AdvancedModelTrainer:
    """Entrenador avanzado para modelos de detección de cáncer de colon"""
    
    def __init__(self, data_dir='data', target_size=(224, 224)):
        self.data_dir = data_dir
        self.target_size = target_size
        self.models = {}
        self.histories = {}
        
    def prepare_data(self):
        """Preparar datos para entrenamiento"""
        print("📊 Preparando datos para entrenamiento...")
        
        # Verificar estructura de datos
        train_dir = os.path.join(self.data_dir, 'train')
        val_dir = os.path.join(self.data_dir, 'val')
        
        if not os.path.exists(train_dir) or not os.path.exists(val_dir):
            raise ValueError("❌ Directorios de datos no encontrados")
        
        # Crear generadores avanzados
        train_gen, val_gen = create_advanced_generators(
            train_dir, val_dir, 
            target_size=self.target_size,
            batch_size=16  # Reducido para modelos más grandes
        )
        
        print(f"✅ Datos de entrenamiento: {train_gen.samples} imágenes")
        print(f"✅ Datos de validación: {val_gen.samples} imágenes")
        print(f"✅ Clases: {train_gen.class_indices}")
        
        return train_gen, val_gen
    
    def create_models(self):
        """Crear todos los modelos avanzados"""
        print("🧠 Creando modelos avanzados...")
        
        model_creator = AdvancedColonCancerModel(input_shape=(*self.target_size, 3))
        
        # Crear modelos
        self.models = {
            'custom_cnn': model_creator.create_custom_cnn(),
            'efficientnet': model_creator.create_efficientnet_model(),
            'resnet': model_creator.create_resnet_model(),
        }
        
        # Compilar modelos
        for name, model in self.models.items():
            model_creator.compile_model(model, learning_rate=0.0001)
            print(f"✅ Modelo {name} creado: {model.count_params():,} parámetros")
        
        return self.models
    
    def train_model(self, model_name, train_gen, val_gen, epochs=50):
        """Entrenar un modelo específico"""
        if model_name not in self.models:
            print(f"❌ Modelo {model_name} no encontrado")
            return None
        
        print(f"\n🎯 Entrenando modelo {model_name}...")
        print("=" * 50)
        
        model = self.models[model_name]
        
        # Callbacks
        callbacks = [
            EarlyStopping(
                monitor='val_auc',
                patience=15,
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
                patience=8,
                min_lr=1e-7,
                verbose=1
            )
        ]
        
        # Entrenar
        start_time = time.time()
        history = model.fit(
            train_gen,
            epochs=epochs,
            validation_data=val_gen,
            callbacks=callbacks,
            verbose=1
        )
        training_time = time.time() - start_time
        
        print(f"✅ Entrenamiento completado en {training_time/60:.1f} minutos")
        
        # Guardar historial
        self.histories[model_name] = history
        
        # Evaluar modelo
        self.evaluate_model(model_name, val_gen)
        
        return history
    
    def evaluate_model(self, model_name, val_gen):
        """Evaluar modelo con métricas avanzadas"""
        print(f"\n📈 Evaluando modelo {model_name}...")
        
        model = self.models[model_name]
        
        # Evaluar en datos de validación
        val_gen.reset()
        predictions = model.predict(val_gen, verbose=1)
        true_labels = val_gen.classes
        
        # Calcular métricas
        predicted_labels = (predictions > 0.5).astype(int).flatten()
        
        # Métricas básicas
        accuracy = np.mean(predicted_labels == true_labels)
        auc_score = roc_auc_score(true_labels, predictions)
        
        print(f"   Accuracy: {accuracy:.4f}")
        print(f"   AUC Score: {auc_score:.4f}")
        
        # Reporte de clasificación
        print("\n📊 Reporte de Clasificación:")
        print(classification_report(true_labels, predicted_labels, 
                                  target_names=['Normal', 'Cáncer']))
        
        # Matriz de confusión
        cm = confusion_matrix(true_labels, predicted_labels)
        print("\n🔍 Matriz de Confusión:")
        print(cm)
        
        # Guardar métricas
        metrics = {
            'accuracy': accuracy,
            'auc_score': auc_score,
            'confusion_matrix': cm.tolist()
        }
        
        return metrics
    
    def train_all_models(self, epochs=50):
        """Entrenar todos los modelos"""
        print("🚀 Iniciando entrenamiento de todos los modelos...")
        print("=" * 60)
        
        # Preparar datos
        train_gen, val_gen = self.prepare_data()
        
        # Crear modelos
        self.create_models()
        
        # Entrenar cada modelo
        for model_name in self.models.keys():
            try:
                self.train_model(model_name, train_gen, val_gen, epochs)
            except Exception as e:
                print(f"❌ Error entrenando {model_name}: {e}")
                continue
        
        # Crear ensemble
        self.create_ensemble_model()
        
        # Visualizar resultados
        self.plot_training_results()
        
        print("\n🎉 Entrenamiento completado!")
        print("📁 Modelos guardados:")
        for model_name in self.models.keys():
            print(f"   - {model_name}_best.h5")
    
    def create_ensemble_model(self):
        """Crear modelo ensemble"""
        print("\n🤝 Creando modelo ensemble...")
        
        model_creator = AdvancedColonCancerModel(input_shape=(*self.target_size, 3))
        ensemble_model = model_creator.create_ensemble_model()
        model_creator.compile_model(ensemble_model)
        
        self.models['ensemble'] = ensemble_model
        print(f"✅ Modelo ensemble creado: {ensemble_model.count_params():,} parámetros")
        
        # Guardar modelo ensemble
        ensemble_model.save('ensemble_colon_cancer.h5')
        print("💾 Modelo ensemble guardado")
    
    def plot_training_results(self):
        """Visualizar resultados del entrenamiento"""
        if not self.histories:
            print("⚠️ No hay historiales para visualizar")
            return
        
        print("\n📊 Generando gráficos de entrenamiento...")
        
        # Configurar estilo
        plt.style.use('seaborn-v0_8')
        fig, axes = plt.subplots(2, 2, figsize=(15, 10))
        fig.suptitle('Resultados de Entrenamiento - Modelos Avanzados', fontsize=16)
        
        colors = ['blue', 'red', 'green', 'orange']
        
        for i, (model_name, history) in enumerate(self.histories.items()):
            color = colors[i % len(colors)]
            
            # Accuracy
            axes[0, 0].plot(history.history['accuracy'], 
                           label=f'{model_name} (Train)', 
                           color=color, linestyle='-')
            axes[0, 0].plot(history.history['val_accuracy'], 
                           label=f'{model_name} (Val)', 
                           color=color, linestyle='--')
            
            # Loss
            axes[0, 1].plot(history.history['loss'], 
                           label=f'{model_name} (Train)', 
                           color=color, linestyle='-')
            axes[0, 1].plot(history.history['val_loss'], 
                           label=f'{model_name} (Val)', 
                           color=color, linestyle='--')
            
            # AUC (si está disponible)
            if 'auc' in history.history:
                axes[1, 0].plot(history.history['auc'], 
                               label=f'{model_name} (Train)', 
                               color=color, linestyle='-')
                axes[1, 0].plot(history.history['val_auc'], 
                               label=f'{model_name} (Val)', 
                               color=color, linestyle='--')
        
        # Configurar gráficos
        axes[0, 0].set_title('Accuracy')
        axes[0, 0].set_xlabel('Época')
        axes[0, 0].set_ylabel('Accuracy')
        axes[0, 0].legend()
        axes[0, 0].grid(True)
        
        axes[0, 1].set_title('Loss')
        axes[0, 1].set_xlabel('Época')
        axes[0, 1].set_ylabel('Loss')
        axes[0, 1].legend()
        axes[0, 1].grid(True)
        
        axes[1, 0].set_title('AUC Score')
        axes[1, 0].set_xlabel('Época')
        axes[1, 0].set_ylabel('AUC')
        axes[1, 0].legend()
        axes[1, 0].grid(True)
        
        # Métricas finales
        final_metrics = []
        for model_name, history in self.histories.items():
            final_val_acc = max(history.history['val_accuracy'])
            final_val_loss = min(history.history['val_loss'])
            final_metrics.append([model_name, final_val_acc, final_val_loss])
        
        # Tabla de métricas
        axes[1, 1].axis('off')
        table_data = [['Modelo', 'Val Accuracy', 'Val Loss']] + final_metrics
        table = axes[1, 1].table(cellText=table_data, 
                                cellLoc='center', 
                                loc='center')
        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1.2, 1.5)
        axes[1, 1].set_title('Métricas Finales')
        
        plt.tight_layout()
        plt.savefig('advanced_training_results.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        print("📊 Gráficos guardados como 'advanced_training_results.png'")

def main():
    """Función principal para entrenar modelos"""
    print("🎯 Sistema de Entrenamiento Avanzado para Detección de Cáncer de Colon")
    print("=" * 70)
    
    # Configurar GPU si está disponible
    gpus = tf.config.experimental.list_physical_devices('GPU')
    if gpus:
        try:
            for gpu in gpus:
                tf.config.experimental.set_memory_growth(gpu, True)
            print(f"✅ GPU detectada: {len(gpus)} dispositivo(s)")
        except RuntimeError as e:
            print(f"⚠️ Error configurando GPU: {e}")
    else:
        print("⚠️ No se detectó GPU, usando CPU")
    
    # Crear entrenador
    trainer = AdvancedModelTrainer()
    
    try:
        # Entrenar todos los modelos
        trainer.train_all_models(epochs=30)  # Reducido para demo
        
        print("\n🎉 ¡Entrenamiento completado exitosamente!")
        print("📁 Archivos generados:")
        print("   - *_best.h5: Modelos entrenados")
        print("   - advanced_training_results.png: Gráficos de resultados")
        print("\n🚀 Ahora puede usar 'python improved_app.py' para iniciar la API mejorada")
        
    except Exception as e:
        print(f"❌ Error durante el entrenamiento: {e}")
        print("💡 Verifique que los datos estén en la estructura correcta:")
        print("   data/")
        print("   ├── train/")
        print("   │   ├── colon_aca/")
        print("   │   └── colon_n/")
        print("   └── val/")
        print("       ├── colon_aca/")
        print("       └── colon_n/")

if __name__ == "__main__":
    main()


