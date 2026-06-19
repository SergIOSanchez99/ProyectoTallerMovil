# Arquitectura por Capas - Backend

## 📁 Estructura del Proyecto

```
backend/
├── layers/
│   ├── presentation/          # Capa de Presentación
│   │   ├── api_controller.py  # Controlador de API
│   │   └── __init__.py
│   ├── business/              # Capa de Lógica de Negocio
│   │   ├── services/          # Servicios de negocio
│   │   │   ├── analysis_service.py
│   │   │   ├── health_service.py
│   │   │   └── __init__.py
│   │   └── __init__.py
│   ├── data/                  # Capa de Acceso a Datos
│   │   ├── repositories/      # Repositorios
│   │   │   ├── model_repository.py
│   │   │   └── __init__.py
│   │   └── __init__.py
│   └── infrastructure/        # Capa de Infraestructura
│       ├── exceptions/        # Excepciones personalizadas
│       │   ├── api_exceptions.py
│       │   └── __init__.py
│       ├── image_processor.py # Procesador de imágenes
│       ├── confidence_scorer.py # Calculador de confianza
│       └── __init__.py
├── config/                    # Configuración
│   ├── settings.py
│   └── __init__.py
├── tests/                     # Tests
│   ├── test_api.py
│   └── __init__.py
├── utils/                     # Utilidades
│   ├── helpers.py
│   └── __init__.py
├── app.py                     # Aplicación principal
├── requirements.txt
└── colon_cancer_binary_cnn.h5 # Modelo entrenado
```

## 🚀 Cómo Ejecutar

```bash
# Instalar dependencias
pip install -r requirements.txt

# Ejecutar aplicación
python app.py
```

## 🏗️ Beneficios de esta Arquitectura

- **Separación de responsabilidades**: Cada capa tiene una función específica
- **Mantenibilidad**: Fácil de mantener y extender
- **Testabilidad**: Cada capa se puede probar independientemente
- **Escalabilidad**: Fácil agregar nuevas funcionalidades


