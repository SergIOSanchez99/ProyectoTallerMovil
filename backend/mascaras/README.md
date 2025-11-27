# Carpeta Mascaras - Segmentación de Imágenes

Esta carpeta contiene el código y scripts para la segmentación de imágenes de cáncer de colon.

## 📁 Estructura

```
mascaras/
├── scripts/              # Scripts de Python para entrenamiento y procesamiento
├── dataset/             # Dataset de imágenes (NO incluido en Git - ver abajo)
│   ├── images/          # Imágenes originales
│   ├── labels/          # Etiquetas YOLO
│   └── masks/           # Máscaras generadas
├── runs/                # Resultados de entrenamiento (NO incluido en Git)
├── requirements.txt     # Dependencias Python
├── Dockerfile           # Configuración Docker
└── compose.yml          # Configuración Docker Compose
```

## ⚠️ Archivos NO incluidos en Git

Los siguientes archivos son demasiado grandes para Git y están en `.gitignore`:

- **Datasets**: `dataset/images/`, `dataset/labels/`, `dataset/masks/`
- **Modelos entrenados**: `*.pt`, `*.pth`
- **Resultados de entrenamiento**: `runs/`

## 📥 Cómo obtener los archivos faltantes

### Opción 1: Descargar desde almacenamiento externo
Los datasets y modelos deben descargarse desde:
- Google Drive
- Cloud Storage
- Otro servicio de almacenamiento

### Opción 2: Generar los datos
Ejecuta los scripts para generar los datos:
```bash
python scripts/generate_masks.py
```

### Opción 3: Entrenar los modelos
Los modelos pueden ser entrenados ejecutando:
```bash
# Ver scripts/train.ipynb para instrucciones
```

## 🚀 Uso

1. Instalar dependencias:
```bash
pip install -r requirements.txt
```

2. Configurar el dataset (descargar o generar)

3. Ejecutar scripts según necesidad

## 📝 Notas

- Los archivos `.pt` y `.pth` son modelos entrenados que pesan varios GB
- Los datasets contienen miles de imágenes que suman varios GB
- Solo el código fuente y configuraciones están en Git

