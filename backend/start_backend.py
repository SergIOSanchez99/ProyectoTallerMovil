#!/usr/bin/env python3
"""
Script para iniciar el backend de detección de cáncer de colon
"""

import os
import sys
import subprocess

def check_requirements():
    """Verificar que las dependencias estén instaladas"""
    try:
        import flask
        import tensorflow
        import numpy
        print("✅ Todas las dependencias están instaladas")
        return True
    except ImportError as e:
        print(f"❌ Dependencia faltante: {e}")
        print("📦 Instalando dependencias...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
            print("✅ Dependencias instaladas correctamente")
            return True
        except subprocess.CalledProcessError:
            print("❌ Error instalando dependencias")
            return False

def check_model():
    """Verificar que el modelo existe"""
    if os.path.exists("colon_cancer_binary_cnn.h5"):
        print("✅ Modelo encontrado: colon_cancer_binary_cnn.h5")
        return True
    else:
        print("❌ Modelo no encontrado: colon_cancer_binary_cnn.h5")
        print("🎯 Para entrenar el modelo, ejecuta: python train_model.py")
        return False

def check_data():
    """Verificar que los datos de entrenamiento existen"""
    required_dirs = [
        "data/train/colon_aca",
        "data/train/colon_n", 
        "data/val/colon_aca",
        "data/val/colon_n"
    ]
    
    missing_dirs = []
    for dir_path in required_dirs:
        if not os.path.exists(dir_path):
            missing_dirs.append(dir_path)
    
    if missing_dirs:
        print("❌ Directorios de datos faltantes:")
        for dir_path in missing_dirs:
            print(f"   - {dir_path}")
        return False
    else:
        print("✅ Estructura de datos correcta")
        return True

def main():
    print("🚀 Iniciando Backend de Detección de Cáncer de Colon")
    print("=" * 50)
    
    # Verificaciones
    if not check_requirements():
        sys.exit(1)
    
    if not check_data():
        print("\n💡 Para agregar datos de entrenamiento:")
        print("   1. Crea las carpetas necesarias")
        print("   2. Agrega imágenes de colon con cáncer en 'data/train/colon_aca/'")
        print("   3. Agrega imágenes normales en 'data/train/colon_n/'")
        print("   4. Agrega imágenes de validación en 'data/val/'")
        sys.exit(1)
    
    if not check_model():
        print("\n🎯 Para entrenar el modelo:")
        print("   python train_model.py")
        print("\n⚠️  Continuando sin modelo (solo análisis simulado)")
    
    print("\n🌐 Iniciando servidor Flask...")
    print("📍 URL: http://localhost:5000")
    print("🔗 Health check: http://localhost:5000/health")
    print("📊 API docs: http://localhost:5000/predict")
    print("\n" + "=" * 50)
    
    # Iniciar la aplicación
    try:
        from app import app
        app.run(debug=True, host='0.0.0.0', port=5000)
    except KeyboardInterrupt:
        print("\n👋 Servidor detenido por el usuario")
    except Exception as e:
        print(f"\n❌ Error iniciando servidor: {e}")

if __name__ == "__main__":
    main()
