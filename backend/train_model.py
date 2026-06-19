import tensorflow as tf
import matplotlib.pyplot as plt
import os
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint

def create_model():
    """Crear modelo CNN para detección de cáncer de colon"""
    model = Sequential([
        Conv2D(32, (3,3), activation='relu', input_shape=(128,128,3)),
        MaxPooling2D(2,2),
        
        Conv2D(64, (3,3), activation='relu'),
        MaxPooling2D(2,2),
        
        Conv2D(128, (3,3), activation='relu'),
        MaxPooling2D(2,2),
        
        Conv2D(256, (3,3), activation='relu'),
        MaxPooling2D(2,2),
        
        Flatten(),
        Dense(512, activation='relu'),
        Dropout(0.5),
        Dense(256, activation='relu'),
        Dropout(0.3),
        Dense(1, activation='sigmoid')  # salida binaria
    ])
    
    model.compile(
        optimizer=Adam(learning_rate=0.0001),
        loss='binary_crossentropy',
        metrics=['accuracy']
    )
    
    return model

def train_model():
    """Entrenar el modelo con los datos disponibles"""
    print("🚀 Iniciando entrenamiento del modelo...")
    
    # Verificar que existen los directorios de datos
    if not os.path.exists('data/train') or not os.path.exists('data/val'):
        print("❌ Error: Directorios de datos no encontrados")
        print("   Asegúrate de tener:")
        print("   - data/train/colon_aca/ (imágenes de cáncer)")
        print("   - data/train/colon_n/ (imágenes normales)")
        print("   - data/val/colon_aca/ (imágenes de validación - cáncer)")
        print("   - data/val/colon_n/ (imágenes de validación - normales)")
        return False
    
    # 1. Preprocesamiento de datos
    print("📊 Configurando generadores de datos...")
    
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=20,
        zoom_range=0.2,
        horizontal_flip=True,
        shear_range=0.2,
        width_shift_range=0.2,
        height_shift_range=0.2
    )
    
    val_datagen = ImageDataGenerator(rescale=1./255)
    
    train_generator = train_datagen.flow_from_directory(
        'data/train',
        target_size=(128,128),
        batch_size=32,
        class_mode='binary',
        shuffle=True
    )
    
    val_generator = val_datagen.flow_from_directory(
        'data/val',
        target_size=(128,128),
        batch_size=32,
        class_mode='binary',
        shuffle=False
    )
    
    print(f"✅ Datos de entrenamiento: {train_generator.samples} imágenes")
    print(f"✅ Datos de validación: {val_generator.samples} imágenes")
    
    # 2. Crear modelo
    print("🧠 Creando modelo CNN...")
    model = create_model()
    model.summary()
    
    # 3. Callbacks para mejorar el entrenamiento
    callbacks = [
        EarlyStopping(
            monitor='val_accuracy',
            patience=5,
            restore_best_weights=True
        ),
        ModelCheckpoint(
            'colon_cancer_binary_cnn.h5',
            monitor='val_accuracy',
            save_best_only=True,
            verbose=1
        )
    ]
    
    # 4. Entrenar modelo
    print("🎯 Iniciando entrenamiento...")
    history = model.fit(
        train_generator,
        epochs=50,  # Aumentado para mejor entrenamiento
        validation_data=val_generator,
        callbacks=callbacks,
        verbose=1
    )
    
    # 5. Guardar modelo final
    model.save("colon_cancer_binary_cnn.h5")
    print("💾 Modelo guardado como 'colon_cancer_binary_cnn.h5'")
    
    # 6. Visualizar resultados
    plot_training_history(history)
    
    # 7. Evaluar modelo
    evaluate_model(model, val_generator)
    
    return True

def plot_training_history(history):
    """Visualizar el historial de entrenamiento"""
    plt.figure(figsize=(12, 4))
    
    plt.subplot(1, 2, 1)
    plt.plot(history.history['accuracy'], label='Entrenamiento')
    plt.plot(history.history['val_accuracy'], label='Validación')
    plt.title('Precisión del Modelo')
    plt.xlabel('Época')
    plt.ylabel('Precisión')
    plt.legend()
    
    plt.subplot(1, 2, 2)
    plt.plot(history.history['loss'], label='Entrenamiento')
    plt.plot(history.history['val_loss'], label='Validación')
    plt.title('Pérdida del Modelo')
    plt.xlabel('Época')
    plt.ylabel('Pérdida')
    plt.legend()
    
    plt.tight_layout()
    plt.savefig('training_history.png')
    plt.show()

def evaluate_model(model, val_generator):
    """Evaluar el modelo con datos de validación"""
    print("📈 Evaluando modelo...")
    
    # Evaluar en datos de validación
    val_loss, val_accuracy = model.evaluate(val_generator, verbose=1)
    
    print(f"✅ Precisión en validación: {val_accuracy:.4f}")
    print(f"✅ Pérdida en validación: {val_loss:.4f}")
    
    # Mostrar algunas predicciones de ejemplo
    print("\n🔍 Predicciones de ejemplo:")
    for i in range(5):
        batch = next(val_generator)
        predictions = model.predict(batch[0])
        
        for j in range(len(batch[0])):
            true_label = "Cáncer" if batch[1][j] == 1 else "Normal"
            pred_label = "Cáncer" if predictions[j][0] > 0.5 else "Normal"
            confidence = predictions[j][0] if predictions[j][0] > 0.5 else 1 - predictions[j][0]
            
            print(f"   Imagen {i*len(batch[0])+j+1}: Real={true_label}, Pred={pred_label} (Confianza: {confidence:.3f})")

if __name__ == "__main__":
    print("🎯 Sistema de Entrenamiento para Detección de Cáncer de Colon")
    print("=" * 60)
    
    success = train_model()
    
    if success:
        print("\n🎉 ¡Entrenamiento completado exitosamente!")
        print("📁 El modelo se guardó como 'colon_cancer_binary_cnn.h5'")
        print("🚀 Ahora puedes usar 'python app.py' para iniciar la API")
    else:
        print("\n❌ El entrenamiento falló. Verifica los datos y reintenta.")
