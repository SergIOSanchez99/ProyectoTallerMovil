"""
Tests para la API
"""

import unittest
import requests
import base64
import numpy as np
from PIL import Image
import io

class TestAPI(unittest.TestCase):
    """Tests para la API"""
    
    def setUp(self):
        self.base_url = "http://localhost:5000"
    
    def test_health_endpoint(self):
        """Test del endpoint de salud"""
        response = requests.get(f"{self.base_url}/health")
        self.assertEqual(response.status_code, 200)
        
        data = response.json()
        self.assertEqual(data["status"], "OK")
        self.assertIn("model_loaded", data)
    
    def test_predict_endpoint_with_mock_image(self):
        """Test del endpoint de predicción con imagen mock"""
        # Crear imagen de prueba
        img_array = np.random.randint(0, 255, (128, 128, 3), dtype=np.uint8)
        img = Image.fromarray(img_array)
        
        # Convertir a base64
        buffer = io.BytesIO()
        img.save(buffer, format='JPEG')
        img_base64 = base64.b64encode(buffer.getvalue()).decode()
        
        # Enviar petición
        response = requests.post(
            f"{self.base_url}/predict",
            json={"image": img_base64},
            headers={"Content-Type": "application/json"}
        )
        
        self.assertEqual(response.status_code, 200)
        
        data = response.json()
        self.assertTrue(data["success"])
        self.assertIn("result", data)
        self.assertIn("confidence", data)

if __name__ == '__main__':
    unittest.main()


