FROM python:3.9-slim

WORKDIR /app

# Install system dependencies for mysql-connector and others
RUN apt-get update && apt-get install -y \
    default-libmysqlclient-dev \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Expose port
ENV PORT=8080
EXPOSE 8080

# Run with gunicorn (production server) using wsgi.py
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 wsgi:app
