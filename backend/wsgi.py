#!/usr/bin/env python3
"""
WSGI Entry Point for Production (Cloud Run)
This file is used by gunicorn and skips the virtual environment setup logic
"""

import os
import sys
import logging
import structlog

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = structlog.get_logger()

# Import the API Controller
from layers.presentation.api_controller import APIController
from config.settings import Settings

# Initialize settings
settings = Settings()

# Create the Flask app
logger.info("🚀 Initializing API Controller...")
api = APIController()
app = api.app

logger.info(f"✅ API initialized successfully")
logger.info(f"📊 Model path: {settings.MODEL_PATH}")
logger.info(f"🌐 CORS origins: {settings.CORS_ORIGINS}")

if __name__ == "__main__":
    # This is only used for local development with `python wsgi.py`
    port = int(os.environ.get("PORT", 8080))
    logger.info(f"🚀 Starting server on port {port}")
    app.run(host="0.0.0.0", port=port, debug=False)
