# ================================================================
# CLASIFICACIÓN BINARIA CON YOLOv8 (colon_aca vs colon_n)
# Estructura esperada:
# ../data/
# ├── train/
# │   ├── colon_aca/
# │   └── colon_n/
# ├── val/
# │   ├── colon_aca/
# │   └── colon_n/
# ================================================================

# pip install ultralytics matplotlib

from ultralytics import YOLO
import matplotlib.pyplot as plt

# 1️⃣ Cargar el modelo base (clasificación)
model = YOLO("yolov8n-cls.pt")  # versión ligera y rápida

# 2️⃣ Entrenar el modelo
results = model.train(
    data="../data",
    epochs=1,               # Número de épocas (ajusta según necesidad)
    imgsz=128,              # Tamaño de imagen
    batch=32,               # Tamaño del lote
    name="colon_cancer_cls",
    project="runs/classify"
)

# 3️⃣ Evaluar el modelo entrenado
metrics = model.val()  # Usa automáticamente los datos de validación definidos en data.yaml

# 4️⃣ Mostrar métricas en consola
print("\n📊 MÉTRICAS DEL MODELO:")
print(metrics)

# 6️⃣ (Opcional) Exportar el modelo entrenado
model.export(format="onnx")  # también puedes usar 'pt', 'torchscript', etc.
print("\n✅ Modelo exportado correctamente.")