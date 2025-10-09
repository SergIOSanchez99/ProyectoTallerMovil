from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
import os
import base64
from io import BytesIO
from PIL import Image
import uuid

app = Flask(__name__)
CORS(app)  # Permitir peticiones desde Flutter

# Cargar modelo al iniciar la aplicación
model = None

def load_ml_model():
    """Cargar el modelo de machine learning"""
    global model
    try:
        model = load_model("colon_cancer_binary_cnn.h5")
        print("✅ Modelo cargado exitosamente")
        return True
    except Exception as e:
        print(f"❌ Error cargando modelo: {e}")
        return False

def preprocess_image(image_data):
    """Preprocesar imagen para el modelo"""
    try:
        # Convertir base64 a imagen
        img_data = base64.b64decode(image_data)
        img = Image.open(BytesIO(img_data))
        
        # Convertir a RGB si es necesario
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Redimensionar a 128x128 (tamaño esperado por el modelo)
        img = img.resize((128, 128))
        
        # Convertir a array y normalizar
        img_array = np.array(img) / 255.0
        img_array = np.expand_dims(img_array, axis=0)  # (1, 128, 128, 3)
        
        return img_array
    except Exception as e:
        print(f"❌ Error preprocesando imagen: {e}")
        return None

@app.route('/health', methods=['GET'])
def health_check():
    """Endpoint para verificar que la API está funcionando"""
    return jsonify({
        "status": "OK",
        "message": "API de detección de cáncer de colon funcionando",
        "model_loaded": model is not None
    })

@app.route('/predict', methods=['POST'])
def predict():
    """Endpoint para predecir si una imagen muestra cáncer de colon"""
    try:
        # Verificar que el modelo esté cargado
        if model is None:
            return jsonify({
                "success": False,
                "error": "Modelo no cargado"
            }), 500
        
        # Obtener datos de la imagen
        data = request.get_json()
        
        if 'image' not in data:
            return jsonify({
                "success": False,
                "error": "No se proporcionó imagen"
            }), 400
        
        # Preprocesar imagen
        image_array = preprocess_image(data['image'])
        
        if image_array is None:
            return jsonify({
                "success": False,
                "error": "Error procesando imagen"
            }), 400
        
        # Hacer predicción
        prediction = model.predict(image_array)
        confidence = float(prediction[0][0])
        
        # Determinar resultado
        if confidence > 0.5:
            result = "Cáncer de Colon Detectado"
            stage = "Requiere atención médica inmediata"
            risk_level = "Alto"
        else:
            result = "Tejido Benigno"
            stage = "Sin signos de cáncer"
            risk_level = "Bajo"
        
        # Generar ID único para el análisis
        analysis_id = str(uuid.uuid4())
        
        return jsonify({
            "success": True,
            "analysis_id": analysis_id,
            "result": result,
            "confidence": confidence,
            "stage": stage,
            "risk_level": risk_level,
            "recommendation": "Consulte con un especialista para confirmación" if confidence > 0.5 else "Mantenga revisiones regulares"
        })
        
    except Exception as e:
        print(f"❌ Error en predicción: {e}")
        return jsonify({
            "success": False,
            "error": f"Error interno del servidor: {str(e)}"
        }), 500

@app.route('/train', methods=['POST'])
def retrain_model():
    """Endpoint para reentrenar el modelo (opcional)"""
    try:
        # Aquí podrías implementar la lógica para reentrenar el modelo
        # Por ahora solo retornamos un mensaje
        return jsonify({
            "success": True,
            "message": "Función de reentrenamiento no implementada aún"
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"Error reentrenando modelo: {str(e)}"
        }), 500

if __name__ == '__main__':
    print("🚀 Iniciando API de detección de cáncer de colon...")
    
    # Cargar modelo al iniciar
    if load_ml_model():
        print("🎯 Servidor listo para predicciones")
        app.run(debug=True, host='0.0.0.0', port=5000)
    else:
        print("❌ No se pudo cargar el modelo. Verifique que colon_cancer_binary_cnn.h5 existe")
