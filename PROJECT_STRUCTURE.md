# Estructura del Proyecto - Taller Móvil App Colon

## 📁 Estructura de Carpetas

```
lib/
├── main.dart                    # Punto de entrada de la aplicación
├── constants/                   # Constantes de la aplicación
│   ├── app_colors.dart         # Colores del tema
│   ├── app_dimensions.dart     # Dimensiones y espaciados
│   └── app_strings.dart        # Textos y etiquetas
├── pages/                      # Pantallas principales de la aplicación
│   ├── login_page.dart         # Pantalla de inicio de sesión
│   ├── home_page.dart          # Pantalla principal
│   ├── search_page.dart        # Pantalla de búsqueda
│   ├── upload_image_page.dart  # Pantalla de subida de imágenes
│   ├── profile_page.dart       # Pantalla de perfil
│   ├── report_history_page.dart # Historial de reportes
│   ├── generate_reports_page.dart # Generación de reportes
│   ├── forgot_password_page.dart # Recuperar contraseña
│   ├── settings_page.dart      # Configuración
│   └── about_page.dart         # Acerca de
├── routes/                     # Sistema de rutas
│   ├── app_routes.dart         # Definición de rutas
│   └── route_generator.dart    # Generador de rutas
├── widgets/                    # Componentes UI reutilizables
│   ├── custom_button.dart      # Botón personalizado
│   ├── custom_text_field.dart  # Campo de texto personalizado
│   └── custom_card.dart        # Tarjeta personalizada
├── utils/                      # Utilidades y helpers
│   ├── extensions.dart         # Extensiones de Flutter
│   ├── helpers.dart            # Funciones auxiliares
│   └── validators.dart         # Validadores de formularios
├── services/                   # Servicios y APIs
│   ├── auth_service.dart       # Servicio de autenticación
│   └── person_service.dart     # Servicio de personas
├── model/                      # Modelos de datos
│   ├── api_response.dart       # Respuesta de API
│   ├── person.dart            # Modelo de persona
│   └── user.dart              # Modelo de usuario
└── viewmodels/                 # ViewModels (MVVM)
    ├── login_viewmodel.dart    # ViewModel de login
    └── search_viewmodel.dart   # ViewModel de búsqueda
```

## 🎯 Características de la Nueva Estructura

### ✅ **Organización Profesional**

- **Separación clara de responsabilidades**: Cada carpeta tiene un propósito específico
- **Arquitectura escalable**: Fácil de mantener y extender
- **Convenciones de nombres**: Consistencia en toda la aplicación

### 🎨 **Sistema de Diseño**

- **Constantes centralizadas**: Colores, dimensiones y textos en archivos dedicados
- **Widgets reutilizables**: Componentes UI consistentes
- **Tema unificado**: Configuración centralizada en `main.dart`

### 🚀 **Navegación Profesional**

- **Sistema de rutas**: Gestión centralizada de navegación
- **Generador de rutas**: Manejo automático de rutas
- **Navegación tipada**: Prevención de errores en tiempo de compilación

### 🛠️ **Utilidades y Helpers**

- **Extensiones de contexto**: Métodos útiles para navegación y UI
- **Validadores**: Validación consistente de formularios
- **Helpers**: Funciones auxiliares para fechas, texto, etc.

## 📱 Páginas Implementadas

1. **LoginPage** - Autenticación de usuarios
2. **HomePage** - Pantalla principal con navegación
3. **SearchPage** - Búsqueda de contenido
4. **UploadImagePage** - Subida y procesamiento de imágenes
5. **ProfilePage** - Gestión de perfil de usuario
6. **ReportHistoryPage** - Historial de reportes médicos
7. **GenerateReportsPage** - Generación de reportes
8. **ForgotPasswordPage** - Recuperación de contraseña
9. **SettingsPage** - Configuración de la aplicación
10. **AboutPage** - Información de la aplicación

## 🔧 Widgets Personalizados

- **CustomButton** - Botón con estados de carga y variantes
- **CustomTextField** - Campo de texto con validación
- **CustomCard** - Tarjeta con sombras y estilos consistentes
- **ActionCard** - Tarjeta de acción para la pantalla principal

## 🎨 Sistema de Colores

```dart
// Colores principales
primaryBlue: #1E6091
secondaryBlue: #0066CC
darkBlue: #003366
lightBlue: #E6F3FF
veryLightBlue: #F0F8FF

// Colores de estado
success: #4CAF50
warning: #FF9800
error: #F44336
info: #2196F3
```

## 📏 Sistema de Dimensiones

- **Espaciado**: XS (4px) hasta Huge (80px)
- **Bordes**: S (8px), M (12px), L (16px)
- **Iconos**: S (16px) hasta XL (48px)
- **Fuentes**: XS (10px) hasta Huge (24px)

## 🚀 Cómo Usar

1. **Navegación**: Usar `context.pushNamed(AppRoutes.routeName)`
2. **Widgets**: Importar desde `widgets/` folder
3. **Constantes**: Usar `AppColors`, `AppDimensions`, `AppStrings`
4. **Validación**: Usar `Validators` para formularios
5. **Extensiones**: Usar métodos de `ContextExtensions`

## 📈 Beneficios

- ✅ **Mantenibilidad**: Código organizado y fácil de mantener
- ✅ **Escalabilidad**: Estructura preparada para crecer
- ✅ **Consistencia**: Diseño y comportamiento uniforme
- ✅ **Reutilización**: Componentes y utilidades reutilizables
- ✅ **Profesionalismo**: Estructura de nivel empresarial
- ✅ **Productividad**: Desarrollo más rápido y eficiente

## 🔄 Migración Completada

- ✅ Archivos antiguos eliminados
- ✅ Nueva estructura implementada
- ✅ Importaciones actualizadas
- ✅ Sistema de rutas configurado
- ✅ Widgets personalizados creados
- ✅ Constantes centralizadas
- ✅ Sin errores de linting












