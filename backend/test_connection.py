#!/usr/bin/env python3
"""
Script para probar la conexión del backend
"""

import requests
import base64
import numpy as np
from PIL import Image
import io

def create_test_image():
    """Crear una imagen de prueba"""
    # Crear imagen de prueba simple
    img_array = np.random.randint(50, 200, (128, 128, 3), dtype=np.uint8)
    img = Image.fromarray(img_array)
    
    # Convertir a base64
    buffer = io.BytesIO()
    img.save(buffer, format='JPEG')
    img_base64 = base64.b64encode(buffer.getvalue()).decode()
    
    return img_base64

def test_backend():
    """Probar el backend"""
    base_url = "http://127.0.0.1:5000"
    
    print("🧪 Probando Backend con Nueva Arquitectura")
    print("=" * 50)
    
    # 1. Probar health endpoint
    try:
        print("1. Probando /health...")
        response = requests.get(f"{base_url}/health", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print("   ✅ Health OK")
            print(f"   Status: {data.get('status')}")
            print(f"   Modelo cargado: {data.get('model_loaded')}")
        else:
            print(f"   ❌ Error: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False
    
    # 2. Probar predict endpoint
    try:
        print("2. Probando /predict...")
        
        # Crear imagen de prueba
        test_image = create_test_image()
        
        payload = {"image": test_image}
        response = requests.post(
            f"{base_url}/predict",
            json=payload,
            headers={'Content-Type': 'application/json'},
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            print("   ✅ Predicción exitosa")
            print(f"   Resultado: {data.get('result')}")
            print(f"   Confianza: {data.get('confidence', 0):.3f}")
            print(f"   Nivel de riesgo: {data.get('risk_level')}")
            print(f"   Recomendación: {data.get('recommendation')}")
            return True
        else:
            print(f"   ❌ Error: {response.status_code}")
            print(f"   Respuesta: {response.text}")
            return False
            
    except Exception as e:
        print(f"   ❌ Error en predicción: {e}")
        return False

if __name__ == "__main__":
    success = test_backend()
    
    if success:
        print("\n✅ Backend funcionando correctamente!")
        print("💡 Ahora puedes probar la aplicación Flutter")
    else:
        print("\n❌ Hay problemas con el backend")
        print("💡 Verifica que esté ejecutándose en http://127.0.0.1:5000")


