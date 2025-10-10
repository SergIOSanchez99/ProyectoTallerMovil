import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user.dart';
import '../model/api_response.dart';

class AuthService {
  static const String _usersFilePath = 'assets/data/users.json';
  static const String _usersKey = 'saved_users';
  
  // Lista de usuarios en memoria
  static List<Map<String, dynamic>> _users = [];
  static bool _isInitialized = false;

  /// Inicializar el servicio y cargar usuarios guardados
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadUsersFromStorage();
      _isInitialized = true;
      print('✅ AuthService inicializado con ${_users.length} usuarios');
    } catch (e) {
      print('⚠️ Error inicializando AuthService: $e');
      await _loadUsersFromAssets();
      _isInitialized = true;
    }
  }

  /// Cargar usuarios desde SharedPreferences
  static Future<void> _loadUsersFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usersJson = prefs.getString(_usersKey);
      
      if (usersJson != null && usersJson.isNotEmpty) {
        final List<dynamic> usersList = json.decode(usersJson);
        _users = usersList.cast<Map<String, dynamic>>();
        print('📂 Usuarios cargados desde almacenamiento: ${_users.length}');
        _debugShowAllUsers(); // Mostrar usuarios al cargar
      } else {
        print('📝 No hay usuarios guardados, cargando desde assets');
        await _loadUsersFromAssets();
        await _saveUsersToStorage();
      }
    } catch (e) {
      print('⚠️ Error cargando usuarios desde almacenamiento: $e');
      await _loadUsersFromAssets();
    }
  }

  /// Cargar usuarios desde assets (usuarios iniciales)
  static Future<void> _loadUsersFromAssets() async {
    try {
      final String jsonString = await rootBundle.loadString(_usersFilePath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _users = List<Map<String, dynamic>>.from(jsonData['users'] ?? []);
      print('📂 Usuarios cargados desde assets: ${_users.length}');
    } catch (e) {
      print('⚠️ Error cargando usuarios desde assets: $e');
      _users = [];
    }
  }

  /// Guardar usuarios en SharedPreferences
  static Future<void> _saveUsersToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String usersJson = json.encode(_users);
      await prefs.setString(_usersKey, usersJson);
      print('💾 Usuarios guardados en almacenamiento: ${_users.length}');
      _debugShowAllUsers(); // Mostrar usuarios después de guardar
    } catch (e) {
      print('⚠️ Error guardando usuarios: $e');
    }
  }

  /// Función de debug para mostrar todos los usuarios
  static void _debugShowAllUsers() {
    print('👥 === LISTA COMPLETA DE USUARIOS ===');
    for (int i = 0; i < _users.length; i++) {
      final user = _users[i];
      print('👤 Usuario ${i + 1}:');
      print('   📧 Email: ${user['email']}');
      print('   👤 Nombre: ${user['name']}');
      print('   🔑 ID: ${user['id']}');
      print('   📅 Creado: ${user['createdAt']}');
      print('   ✅ Activo: ${user['isActive']}');
      print('');
    }
    print('👥 === FIN DE LA LISTA ===');
  }

  /// Autentica un usuario con email y contraseña
  Future<ApiResponse<User>> login(String email, String password) async {
    try {
      // Asegurar que el servicio esté inicializado
      if (!_isInitialized) {
        await initialize();
      }
      
      // Simulamos un delay de red
      await Future.delayed(const Duration(seconds: 1));

      // Validaciones básicas
      if (email.isEmpty || password.isEmpty) {
        return ApiResponse.error('Email y contraseña son requeridos');
      }

      if (!_isValidEmail(email)) {
        return ApiResponse.error('Formato de email inválido');
      }

      // Buscar usuario en la lista de usuarios del JSON
      final userData = _users.firstWhere(
        (user) => user['email'].toString().toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('Usuario no encontrado'),
      );

      // Verificar contraseña
      if (userData['password'] != password) {
        return ApiResponse.error('Contraseña incorrecta');
      }

      // Crear objeto User
      final user = User(
        id: userData['id'].toString(),
        email: userData['email'].toString(),
        name: userData['name'].toString(),
      );

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
      if (!_isInitialized) {
        await initialize();
      }
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_users.isEmpty) {
        return ApiResponse.error('No hay usuarios disponibles');
      }
      
      // Simulamos que siempre hay un usuario logueado (el primero)
      final userData = _users.first;
      final user = User(
        id: userData['id'].toString(),
        email: userData['email'].toString(),
        name: userData['name'].toString(),
      );
      
      return ApiResponse.success(user);
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
      if (!_isInitialized) {
        await initialize();
      }
      await Future.delayed(const Duration(seconds: 1));

      if (email.isEmpty) {
        return ApiResponse.error('Email es requerido');
      }

      if (!_isValidEmail(email)) {
        return ApiResponse.error('Formato de email inválido');
      }

      // Verificar si el email existe
      final userExists = _users.any(
        (user) => user['email'].toString().toLowerCase() == email.toLowerCase(),
      );

      if (!userExists) {
        return ApiResponse.error('Email no encontrado');
      }

      return ApiResponse.success(true, message: 'Instrucciones enviadas al email');
    } catch (e) {
      return ApiResponse.error('Error al procesar solicitud');
    }
  }

  /// Registra un nuevo usuario
  Future<ApiResponse<User>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      await Future.delayed(const Duration(seconds: 1));

      // Validaciones
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        return ApiResponse.error('Todos los campos son requeridos');
      }

      if (!_isValidEmail(email)) {
        return ApiResponse.error('Formato de email inválido');
      }

      if (password.length < 6) {
        return ApiResponse.error('La contraseña debe tener al menos 6 caracteres');
      }

      if (name.length < 2) {
        return ApiResponse.error('El nombre debe tener al menos 2 caracteres');
      }

      // Verificar si el email ya existe
      final emailExists = _users.any(
        (user) => user['email'].toString().toLowerCase() == email.toLowerCase(),
      );

      if (emailExists) {
        return ApiResponse.error('El email ya está registrado');
      }

      // Generar nuevo ID
      final newId = (_users.length + 1).toString();
      
      // Crear nuevo usuario
      final newUser = {
        'id': newId,
        'email': email.toLowerCase(),
        'password': password,
        'name': name,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };

      // Agregar a la lista y guardar permanentemente
      _users.add(newUser);
      await _saveUsersToStorage();

      // Crear objeto User para retornar
      final user = User(
        id: newUser['id'].toString(),
        email: newUser['email'].toString(),
        name: newUser['name'].toString(),
      );

      return ApiResponse.success(user, message: 'Usuario registrado exitosamente');
    } catch (e) {
      return ApiResponse.error('Error al registrar usuario: $e');
    }
  }

  /// Obtiene todos los usuarios (para debug)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    if (!_isInitialized) {
      await initialize();
    }
    return List.from(_users);
  }

  /// Método público para mostrar todos los usuarios en consola (debug)
  static Future<void> debugShowAllUsers() async {
    if (!_isInitialized) {
      await initialize();
    }
    _debugShowAllUsers();
  }
}
