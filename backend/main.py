import sys
import numpy as np
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image

# 1. Cargar modelo
model = load_model("colon_cancer_binary_cnn.h5")

# 2. Cargar imagen
img_path = "test/image.jpeg"

img = image.load_img(img_path, target_size=(128, 128))
img_array = image.img_to_array(img) / 255.0
img_array = np.expand_dims(img_array, axis=0)  # (1,128,128,3)

# 3. Predicción
prediction = model.predict(img_array)

if prediction[0][0] > 0.5:
    result = "Colon Adenocarcinoma"
else:
    result = "Colon Benign Tissue"

print(f"Imagen: {img_path}")
print(f"Predicción: {result} (score: {prediction[0][0]:.4f})")