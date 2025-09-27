import '../model/user.dart';
import '../model/api_response.dart';

class AuthService {
  // Simulamos una base de datos de usuarios
  static final List<User> _users = [
    User(
      id: '1',
      email: 'admin@cancer.com',
      name: 'Administrador',
    ),
    User(
      id: '2',
      email: 'doctor@cancer.com',
      name: 'Dr. García',
    ),
    User(
      id: '3',
      email: 'investigador@cancer.com',
      name: 'Investigador López',
    ),
  ];

  /// Autentica un usuario con email y contraseña
  Future<ApiResponse<User>> login(String email, String password) async {
    try {
      // Simulamos un delay de red
      await Future.delayed(const Duration(seconds: 1));

      // Validaciones básicas
      if (email.isEmpty || password.isEmpty) {
        return ApiResponse.error('Email y contraseña son requeridos');
      }

      if (!_isValidEmail(email)) {
        return ApiResponse.error('Formato de email inválido');
      }

      // Buscar usuario en la "base de datos"
      final user = _users.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('Usuario no encontrado'),
      );

      // Simulamos validación de contraseña (en la realidad sería hash)
      if (password.length < 6) {
        return ApiResponse.error('Contraseña debe tener al menos 6 caracteres');
      }

      return ApiResponse.success(user, message: 'Login exitoso');
    } catch (e) {
      return ApiResponse.error('Credenciales inválidas');
    }
  }

  /// Valida el formato del email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Obtiene el usuario actual (simulado)
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // Simulamos que siempre hay un usuario logueado
      return ApiResponse.success(_users.first);
    } catch (e) {
      return ApiResponse.error('Error al obtener usuario actual');
    }
  }

  /// Cierra la sesión del usuario
  Future<ApiResponse<bool>> logout() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return ApiResponse.success(true, message: 'Sesión cerrada exitosamente');
    } catch (e) {
      return ApiResponse.error('Error al cerrar sesión');
    }
  }

  /// Recupera contraseña (simulado)
  Future<ApiResponse<bool>> forgotPassword(String email) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      if (email.isEmpty) {
        return ApiResponse.error('Email es requerido');
      }

      if (!_isValidEmail(email)) {
        return ApiResponse.error('Formato de email inválido');
      }

      // Verificar si el email existe
      final userExists = _users.any(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
      );

      if (!userExists) {
        return ApiResponse.error('Email no encontrado');
      }

      return ApiResponse.success(true, message: 'Instrucciones enviadas al email');
    } catch (e) {
      return ApiResponse.error('Error al procesar solicitud');
    }
  }
}
