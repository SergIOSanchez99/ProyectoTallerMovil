import tensorflow as tf
import matplotlib.pyplot as plt
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout
from tensorflow.keras.optimizers import Adam
from sklearn.metrics import confusion_matrix, classification_report
import numpy as np

# 1. Preprocesamiento
train_datagen = ImageDataGenerator(
    rescale=1./255,
    rotation_range=20,
    zoom_range=0.2,
    horizontal_flip=True
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
    shuffle=False  # ⚠️ Muy importante para mantener el orden
)

# 2. Construcción CNN
model = Sequential([
    Conv2D(32, (3,3), activation='relu', input_shape=(128,128,3)),
    MaxPooling2D(2,2),

    Conv2D(64, (3,3), activation='relu'),
    MaxPooling2D(2,2),

    Conv2D(128, (3,3), activation='relu'),
    MaxPooling2D(2,2),

    Flatten(),
    Dense(128, activation='relu'),
    Dropout(0.5),
    Dense(1, activation='sigmoid')  # salida binaria
])

# 3. Compilación
model.compile(optimizer=Adam(learning_rate=0.0001),
              loss='binary_crossentropy',
              metrics=['accuracy'])

# 4. Entrenamiento
history = model.fit(
    train_generator,
    epochs=5,
    validation_data=val_generator
)

# 5. Guardar modelo
model.save("colon_cancer_binary_cnn.h5")

# 6. Evaluación con la matriz de confusión
# -----------------------------------------
val_generator.reset()  # Reinicia el generador

# Calcular número exacto de pasos para predicción
steps = val_generator.samples // val_generator.batch_size
if val_generator.samples % val_generator.batch_size != 0:
    steps += 1

# Obtener predicciones con número exacto de pasos
predictions = model.predict(val_generator, steps=steps, verbose=1)
predicted_classes = (predictions > 0.5).astype(int).flatten()

# Recortar si sobran (por redondeo en los steps)
predicted_classes = predicted_classes[:len(val_generator.classes)]

# Etiquetas verdaderas y nombres
true_classes = val_generator.classes
class_labels = list(val_generator.class_indices.keys())

# Crear matriz de confusión
cm = confusion_matrix(true_classes, predicted_classes)

print("\nMatriz de confusión:")
print(cm)

# Reporte de clasificación
print("\nReporte de clasificación:")
print(classification_report(true_classes, predicted_classes, target_names=class_labels))
