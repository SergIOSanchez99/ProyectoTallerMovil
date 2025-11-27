FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

# Evitar prompts interactivos
ENV DEBIAN_FRONTEND=noninteractive

# Instalar Python + dependencias básicas
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv python3-dev \
    git wget curl nano \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Hacer que python apunte a python3
RUN ln -s /usr/bin/python3 /usr/bin/python

# Actualizar pip
RUN pip install --upgrade pip

# Instalar PyTorch con CUDA 12.1
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Instalar YOLO
RUN pip install ultralytics

# SAM
RUN pip install git+https://github.com/facebookresearch/segment-anything.git
RUN pip install opencv-python-headless matplotlib

# Instalar JupyterLab
RUN pip install jupyterlab

# Crear workspace
RUN mkdir /workspace
WORKDIR /workspace

# Exponer puerto Jupyter
EXPOSE 8888

# Comando de inicio
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--allow-root"]
