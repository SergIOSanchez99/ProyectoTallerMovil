# Informe de Despliegue del Proyecto en la Nube

**Asignatura:** Taller de Desarrollo Móvil
**Proyecto:** Sistema de Detección de Cáncer de Colon

Este documento detalla los pasos técnicos realizados para desplegar la arquitectura completa del proyecto en la nube, utilizando **Google Cloud Platform (GCP)** para el backend y base de datos, y **Firebase** para el frontend y distribución.

---

## 1. Arquitectura en la Nube

El proyecto se ha desplegado utilizando una arquitectura de microservicios serverless y base de datos gestionada:

- **Frontend (Móvil/Web):** Flutter Web alojado en **Firebase Hosting**.
- **Backend (API):** Python (Flask) contenedorizado en **Google Cloud Run**.
- **Base de Datos:** MySQL gestionado en **Google Cloud SQL**.
- **Almacenamiento:** Google Container Registry (para imágenes Docker).

---

## 2. Pasos de Despliegue del Backend (Google Cloud)

El backend se encarga de la lógica de negocio, procesamiento de imágenes y conexión segura a la base de datos.

### Paso 2.1: Configuración de la Base de Datos (Cloud SQL)

1.  Se creó una instancia de **Cloud SQL** (MySQL) en la región `us-central1`.
2.  **Nombre de la instancia:** `taller-movil-db`
3.  **Conexión:** Se configuró el acceso mediante **Socket Unix** para garantizar una conexión segura y de baja latencia desde Cloud Run, evitando exponer la base de datos a internet público.
4.  **Usuario:** Se creó el usuario `sergio` con permisos específicos para la base de datos `taller-movil-db`.

### Paso 2.2: Contenedorización (Docker)

Se creó un archivo `Dockerfile` para empaquetar la aplicación Python:

- **Imagen Base:** `python:3.9-slim` (versión ligera de Linux).
- **Dependencias del Sistema:** Se instalaron librerías necesarias para MySQL (`default-libmysqlclient-dev`).
- **Servidor de Aplicaciones:** Se configuró **Gunicorn** como servidor WSGI de producción para manejar múltiples peticiones concurrentes (`workers 1`, `threads 8`).

### Paso 2.3: Despliegue en Cloud Run

Se utilizó un script de automatización (`deploy.ps1`) que ejecuta los siguientes comandos de Google Cloud CLI:

1.  **Construcción de la Imagen:**
    El código se sube a Google Cloud Build, que crea la imagen Docker y la guarda en el registro privado.

    ```powershell
    gcloud builds submit --tag "gcr.io/tallermovilapp-6efec/taller-backend"
    ```

2.  **Despliegue del Servicio:**
    Se despliega el contenedor en Cloud Run con la configuración de conexión a base de datos inyectada.
    ```powershell
    gcloud run deploy taller-backend `
      --image "gcr.io/tallermovilapp-6efec/taller-backend" `
      --platform managed `
      --region us-central1 `
      --allow-unauthenticated `  # Permite acceso público a la API
      --add-cloudsql-instances "tallermovilapp-6efec:us-central1:taller-movil-db" `
      --set-env-vars "DB_HOST=/cloudsql/tallermovilapp-6efec:us-central1:taller-movil-db,DB_USER=sergio,..."
    ```

---

## 3. Pasos de Despliegue del Frontend (Firebase)

La aplicación Flutter se compiló para web y se subió a la red de distribución de contenido (CDN) de Firebase.

### Paso 3.1: Preparación del Proyecto Flutter

1.  Se configuró el proyecto para soporte web.
2.  Se verificó que las llamadas a la API apunten a la URL del backend en Cloud Run: `https://taller-backend-663984572750.us-central1.run.app`.

### Paso 3.2: Compilación (Build)

Se generó la versión optimizada para producción de la aplicación web:

```bash
flutter build web --release
```

Esto crea los archivos estáticos (HTML, JS, CSS) en la carpeta `build/web`.

### Paso 3.3: Configuración de Firebase

1.  Se inicializó el proyecto con `firebase init hosting`.
2.  Se configuró el archivo `firebase.json` para servir la carpeta `build/web` y redirigir todas las rutas a `index.html` (necesario para Single Page Applications como Flutter).

### Paso 3.4: Despliegue

Se subieron los archivos a los servidores de Firebase:

```bash
firebase deploy --only hosting
```

**Resultado:** La aplicación es accesible globalmente a través de la URL proporcionada por Firebase (ej. `https://taller-backend-663984572750.web.app`).

---

## 4. Resumen de Tecnologías e Integración

| Componente        | Tecnología     | Función                | Integración                          |
| :---------------- | :------------- | :--------------------- | :----------------------------------- |
| **App Móvil/Web** | Flutter        | Interfaz de Usuario    | Consume API REST vía HTTPS           |
| **API Backend**   | Python (Flask) | Lógica y Procesamiento | Expone endpoints JSON                |
| **Ejecución**     | Cloud Run      | Serverless Compute     | Escala automáticamente según tráfico |
| **Base de Datos** | Cloud SQL      | Persistencia de Datos  | Conexión vía Unix Socket (Seguro)    |
| **Hosting**       | Firebase       | Alojamiento Web        | Entrega rápida de contenido estático |

Este despliegue asegura que la aplicación sea **escalable** (Cloud Run sube instancias si hay muchos usuarios), **segura** (conexión interna a BD) y **accesible** (Firebase CDN global).
