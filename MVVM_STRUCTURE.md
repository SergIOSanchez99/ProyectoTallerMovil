# Estructura MVVM del Proyecto

## 📁 **Estructura de Carpetas**

```
lib/
├── main.dart                    # Punto de entrada de la aplicación
├── model/                       # 📊 Modelos de datos
│   ├── user.dart               # Modelo de usuario
│   ├── person.dart             # Modelo de persona
│   └── api_response.dart       # Modelo de respuesta de API
├── services/                    # 🔧 Servicios de datos
│   ├── auth_service.dart       # Servicio de autenticación
│   └── person_service.dart     # Servicio de personas
├── viewmodels/                  # 🧠 Lógica de negocio
│   ├── login_viewmodel.dart    # ViewModel de login
│   └── search_viewmodel.dart   # ViewModel de búsqueda
└── view/                        # 🎨 Interfaces de usuario
    ├── login_view.dart         # Vista de login
    └── search_view.dart        # Vista de búsqueda
```

## 🏗️ **Patrón MVVM Implementado**

### **1. Model (Modelo)**

- **Responsabilidad:** Representar los datos y la estructura de información
- **Ubicación:** `lib/model/`
- **Archivos:**
  - `user.dart`: Modelo de usuario con propiedades y métodos
  - `person.dart`: Modelo de persona con lógica de negocio básica
  - `api_response.dart`: Wrapper genérico para respuestas de API

### **2. Services (Servicios)**

- **Responsabilidad:** Manejar la comunicación con APIs, base de datos o servicios externos
- **Ubicación:** `lib/services/`
- **Archivos:**
  - `auth_service.dart`: Maneja autenticación, login, logout
  - `person_service.dart`: Maneja operaciones CRUD de personas

### **3. ViewModels**

- **Responsabilidad:** Contener la lógica de presentación y estado de la UI
- **Ubicación:** `lib/viewmodels/`
- **Características:**
  - Extienden `ChangeNotifier` para notificar cambios a la UI
  - Manejan estados (loading, error, data)
  - Comunican con Services para obtener datos
  - Transforman datos del Model para la View

### **4. View (Vista)**

- **Responsabilidad:** Mostrar la interfaz de usuario y manejar interacciones
- **Ubicación:** `lib/view/`
- **Características:**
  - Usan `Consumer` para escuchar cambios del ViewModel
  - Muestran estados de carga y errores
  - Manejan eventos de usuario y los pasan al ViewModel

## 🔄 **Flujo de Datos MVVM**

```
User Interaction → View → ViewModel → Service → Model
                     ↑                            ↓
                     ← ← ← ← ← ← ← ← ← ← ← ← ← ← ←
```

1. **Usuario interactúa** con la View
2. **View** pasa el evento al ViewModel
3. **ViewModel** procesa la lógica y llama al Service
4. **Service** obtiene/manipula datos del Model
5. **Model** retorna datos al Service
6. **Service** retorna resultado al ViewModel
7. **ViewModel** actualiza su estado y notifica a la View
8. **View** se actualiza automáticamente

## 🛠️ **Tecnologías Utilizadas**

- **Provider:** Para inyección de dependencias y gestión de estado
- **ChangeNotifier:** Para notificar cambios a la UI
- **Consumer:** Para escuchar cambios en ViewModels
- **Future/Async:** Para operaciones asíncronas

## 📱 **Pantallas Implementadas**

### **Login View (`login_view.dart`)**

- Campos de email y contraseña
- Validación de formularios
- Integración con `LoginViewModel`
- Navegación a `SearchView` tras login exitoso

### **Search View (`search_view.dart`)**

- Barra de búsqueda en tiempo real
- Lista de resultados con avatares
- Integración con `SearchViewModel`
- Manejo de estados de carga y error

## 🎯 **Beneficios del Patrón MVVM**

1. **Separación de responsabilidades:** Cada capa tiene una función específica
2. **Testabilidad:** ViewModels pueden probarse independientemente
3. **Mantenibilidad:** Código organizado y fácil de mantener
4. **Escalabilidad:** Fácil agregar nuevas funcionalidades
5. **Reutilización:** ViewModels pueden usarse en múltiples Views

## 🚀 **Cómo Agregar Nueva Funcionalidad**

1. **Crear Model** en `lib/model/` si es necesario
2. **Crear Service** en `lib/services/` para manejo de datos
3. **Crear ViewModel** en `lib/viewmodels/` para lógica de negocio
4. **Crear View** en `lib/view/` para interfaz de usuario
5. **Integrar** usando Provider en `main.dart`

## 📋 **Próximas Mejoras**

- [ ] Implementar inyección de dependencias más robusta
- [ ] Agregar tests unitarios para ViewModels
- [ ] Implementar cache de datos
- [ ] Agregar manejo de estados globales
- [ ] Implementar navegación más sofisticada

