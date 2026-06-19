"""
Utility Functions
Funciones de utilidad general
"""

import uuid
from datetime import datetime

def generate_analysis_id() -> str:
    """Genera un ID único para análisis"""
    return f"ana_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{str(uuid.uuid4())[:8]}"

def format_timestamp() -> str:
    """Formatea timestamp actual"""
    return datetime.now().isoformat()

def validate_base64_image(image_data: str) -> bool:
    """Valida que los datos sean una imagen base64 válida"""
    try:
        import base64
        decoded = base64.b64decode(image_data)
        return len(decoded) > 0
    except Exception:
        return False


