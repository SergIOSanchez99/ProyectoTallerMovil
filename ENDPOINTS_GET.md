# Endpoints GET del Backend

## Lista Completa de Endpoints GET

### 1. Health Check
**Ruta:** `GET /health`  
**Descripción:** Endpoint de salud del sistema  
**Parámetros:** Ninguno  
**Respuesta exitosa (200):**
```json
{
  "status": "OK",
  "message": "Sistema funcionando correctamente",
  "timestamp": "2025-11-20T15:53:49.608961",
  ...resultados del health_service
}
```
**Respuesta error (500):**
```json
{
  "status": "ERROR",
  "message": "Error interno del servidor"
}
```

---

### 2. Obtener Todos los Usuarios
**Ruta:** `GET /auth/users`  
**Descripción:** Obtener todos los usuarios registrados  
**Parámetros Query (opcionales):**
- `active_only` (string): `"true"` o `"false"` - Filtrar solo usuarios activos (default: `"false"`)

**Ejemplo de uso:**
```
GET http://127.0.0.1:5000/auth/users
GET http://127.0.0.1:5000/auth/users?active_only=true
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [...],
  "count": 2,
  "message": "..."
}
```

**Respuesta error (500):**
```json
{
  "success": false,
  "error": "..."
}
```

---

### 3. Obtener Todos los Pacientes
**Ruta:** `GET /patients`  
**Descripción:** Obtener todos los pacientes  
**Parámetros Query (opcionales):**
- `active_only` (string): `"true"` o `"false"` - Filtrar solo pacientes activos (default: `"true"`)
- `search` (string): Texto para buscar por nombre o identificación

**Ejemplo de uso:**
```
GET http://127.0.0.1:5000/patients
GET http://127.0.0.1:5000/patients?active_only=true
GET http://127.0.0.1:5000/patients?search=Juan
GET http://127.0.0.1:5000/patients?active_only=true&search=123456
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "full_name": "Juan Pérez",
      "identification": "1234567890",
      "age": 45,
      "created_at": "...",
      "updated_at": "...",
      "is_active": true
    }
  ],
  "message": "..."
}
```

**Respuesta error (500):**
```json
{
  "success": false,
  "error": "..."
}
```

---

### 4. Obtener Paciente por ID
**Ruta:** `GET /patients/<int:patient_id>`  
**Descripción:** Obtener un paciente específico por su ID  
**Parámetros URL:**
- `patient_id` (int): ID del paciente (requerido)

**Ejemplo de uso:**
```
GET http://127.0.0.1:5000/patients/1
GET http://127.0.0.1:5000/patients/5
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "full_name": "Juan Pérez",
    "identification": "1234567890",
    "age": 45,
    "created_at": "...",
    "updated_at": "...",
    "is_active": true
  },
  "message": "..."
}
```

**Respuesta error (404):**
```json
{
  "success": false,
  "error": "Paciente no encontrado"
}
```

---

### 5. Buscar Paciente por Identificación
**Ruta:** `GET /patients/search`  
**Descripción:** Buscar un paciente por su número de identificación  
**Parámetros Query (requerido):**
- `identification` o `identificacion` (string): Número de identificación del paciente

**Ejemplo de uso:**
```
GET http://127.0.0.1:5000/patients/search?identification=1234567890
GET http://127.0.0.1:5000/patients/search?identificacion=1234567890
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "full_name": "Juan Pérez",
    "identification": "1234567890",
    "age": 45,
    ...
  },
  "message": "..."
}
```

**Respuesta error (400):**
```json
{
  "success": false,
  "error": "Parámetro 'identification' requerido"
}
```

**Respuesta error (404):**
```json
{
  "success": false,
  "error": "Paciente no encontrado"
}
```

---

### 6. Obtener Todos los Estudios
**Ruta:** `GET /studies`  
**Descripción:** Obtener todos los estudios/reportes  
**Parámetros Query (opcionales):**
- `user_id` o `userId` (int): Filtrar por ID de usuario
- `patient_id` o `patientId` (int): Filtrar por ID de paciente
- `limit` (int): Límite de resultados para paginación
- `offset` (int): Offset para paginación

**Ejemplo de uso:**
```
GET http://127.0.0.1:5000/studies
GET http://127.0.0.1:5000/studies?patient_id=1
GET http://127.0.0.1:5000/studies?patientId=1
GET http://127.0.0.1:5000/studies?user_id=2&limit=10&offset=0
GET http://127.0.0.1:5000/studies?patient_id=1&limit=5
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "patient_id": 1,
      "user_id": null,
      "result": "Normal",
      "stage": "Sin anomalías detectadas",
      "confidence": 0.95,
      "risk_level": "Bajo",
      "image_path": null,
      "study_date": "2025-11-20",
      "doctor_name": "Dr. García",
      "observations": "...",
      "created_at": "...",
      "updated_at": "...",
      "is_active": true,
      "patient_name": "Juan Pérez",
      "patient_identification": "1234567890"
    }
  ],
  "message": "Se encontraron X estudios"
}
```

**Respuesta error (500):**
```json
{
  "success": false,
  "error": "...",
  "data": []
}
```

---

### 7. Obtener Estudio por ID
**Ruta:** `GET /studies/<int:study_id>`  
**Descripción:** Obtener un estudio específico por su ID  
**Parámetros URL:**
- `study_id` (int): ID del estudio (requerido)

**Ejemplo de uso:**
```
GET http://127.0.0.1:5000/studies/1
GET http://127.0.0.1:5000/studies/5
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "patient_id": 1,
    "user_id": null,
    "result": "Normal",
    "stage": "Sin anomalías detectadas",
    "confidence": 0.95,
    "risk_level": "Bajo",
    "image_path": null,
    "study_date": "2025-11-20",
    "doctor_name": "Dr. García",
    "observations": "...",
    "created_at": "...",
    "updated_at": "...",
    "is_active": true,
    "patient_name": "Juan Pérez",
    "patient_identification": "1234567890"
  },
  "message": "Estudio obtenido exitosamente"
}
```

**Respuesta error (404):**
```json
{
  "success": false,
  "error": "Estudio no encontrado",
  "data": null
}
```

---

## Resumen

**Total de endpoints GET: 7**

1. ✅ `GET /health` - Health check
2. ✅ `GET /auth/users` - Listar usuarios (con `active_only`)
3. ✅ `GET /patients` - Listar pacientes (con `active_only` y `search`)
4. ✅ `GET /patients/<id>` - Obtener paciente por ID
5. ✅ `GET /patients/search` - Buscar paciente por identificación
6. ✅ `GET /studies` - Listar estudios (con `user_id`, `patient_id`, `limit`, `offset`)
7. ✅ `GET /studies/<id>` - Obtener estudio por ID

## Base URL

Todos los endpoints están disponibles en:
```
http://127.0.0.1:5000
```

## Headers CORS

Todos los endpoints incluyen headers CORS:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type, Accept`

## Notas

- Todos los endpoints soportan `OPTIONS` para preflight CORS
- Los parámetros de query son opcionales a menos que se indique lo contrario
- Los IDs en las rutas deben ser números enteros
- Las respuestas siempre incluyen un campo `success` (boolean)
- Los errores incluyen un campo `error` con el mensaje descriptivo

