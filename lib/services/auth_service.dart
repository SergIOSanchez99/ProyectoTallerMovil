import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user.dart';
import '../model/api_response.dart';

class AuthService {
  // URL del backend (ajusta según tu configuración)
  static const String baseUrl = 'https://taller-backend-663984572750.us-central1.run.app';
  
  // Clave para guardar el usuario actual en SharedPreferences
  static const String _currentUserKey = 'current_user';


  /// Autentica un usuario con email y contraseña
  Future<ApiResponse<User>> login(String email, String password) async {
    try {
      // Validaciones básicas
      if (email.isEmpty || password.isEmpty) {
        return ApiResponse.error('Email y contraseña son requeridos');
      }

      if (!_isValidEmail(email)) {
        return ApiResponse.error('Formato de email inválido');
      }

      // Hacer petición al backend
      // Usar jsonEncode en lugar de json.encode para evitar problemas
      final body = jsonEncode({
        'email': email.trim(),
        'password': password,
      });
      
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      // Verificar Content-Type en los headers
      final contentType = response.headers['content-type'] ?? response.headers['Content-Type'] ?? '';
      if (contentType.contains(',')) {
        print('⚠️ Content-Type duplicado detectado en login: $contentType');
      }
      
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Guardar usuario en SharedPreferences
        final userData = responseData['data'];
        final user = User(
          id: userData['id'].toString(),
          email: userData['email'],
          name: userData['name'],
          profileImage: userData['profileImage'],
        );
        
        // Guardar usuario actual
        await _saveCurrentUser(user);
        
        return ApiResponse.success(user, message: responseData['message'] ?? 'Login exitoso');
      } else {
        // Usar el mensaje de error del backend, o un mensaje por defecto
        final errorMsg = responseData['error'] ?? responseData['message'] ?? 'Las credenciales ingresadas no existen. Verifica tu email y contraseña.';
        return ApiResponse.error(errorMsg);
      }
    } catch (e) {
      print('❌ Error en login: $e');
      if (e.toString().contains('TimeoutException') || e.toString().contains('SocketException')) {
        return ApiResponse.error('Error de conexión. Verifica que el backend esté ejecutándose.');
      }
      return ApiResponse.error('Error al autenticar: $e');
    }
  }

  /// Valida el formato del email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Obtiene el usuario actual desde el almacenamiento local
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final user = await getCurrentUserFromStorage();
      if (user != null) {
        return ApiResponse.success(user);
      } else {
        return ApiResponse.error('No hay usuario logueado');
      }
    } catch (e) {
      return ApiResponse.error('Error al obtener usuario actual');
    }
  }

  /// Cierra la sesión del usuario
  Future<ApiResponse<bool>> logout() async {
    try {
      // Eliminar usuario actual del almacenamiento
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      return ApiResponse.success(true, message: 'Sesión cerrada exitosamente');
    } catch (e) {
      return ApiResponse.error('Error al cerrar sesión');
    }
  }

  /// Recupera contraseña (simulado - pendiente de implementar en backend)
  Future<ApiResponse<bool>> forgotPassword(String email) async {
    try {
      if (email.isEmpty) {
        return ApiResponse.error('Email es requerido');
      }

      if (!_isValidEmail(email)) {
        return ApiResponse.error('Formato de email inválido');
      }

      // TODO: Implementar endpoint en backend para recuperación de contraseña
      // Por ahora, solo validamos el formato del email
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

      // Hacer petición al backend
      // Usar jsonEncode en lugar de json.encode para evitar problemas
      final body = jsonEncode({
        'email': email.trim(),
        'password': password,
        'name': name.trim(),
      });
      
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };
      
      print('📤 Enviando petición de registro a: $baseUrl/auth/register');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      print('📥 Respuesta recibida: Status ${response.statusCode}');
      print('📋 Headers de respuesta: ${response.headers}');
      print('📄 Body de respuesta (longitud: ${response.body.length}): ${response.body}');

      // Verificar si la respuesta es válida
      if (response.body.isEmpty) {
        print('❌ Error: El cuerpo de la respuesta está vacío');
        return ApiResponse.error('El servidor no devolvió datos');
      }

      // Verificar Content-Type en los headers
      final contentType = response.headers['content-type'] ?? response.headers['Content-Type'] ?? '';
      print('📋 Content-Type recibido: $contentType');
      
      // Limpiar Content-Type si está duplicado
      String cleanContentType = contentType;
      if (contentType.contains(',')) {
        cleanContentType = contentType.split(',')[0].trim();
        print('⚠️ Content-Type duplicado detectado, usando: $cleanContentType');
      }

      dynamic responseData;
      try {
        // Intentar decodificar el JSON
        final bodyString = response.body;
        print('🔍 Intentando decodificar JSON de ${bodyString.length} caracteres');
        
        // Limpiar el body si tiene caracteres extraños al inicio
        String cleanedBody = bodyString.trim();
        if (cleanedBody.startsWith('application/json')) {
          // Si el body comienza con "application/json", es un error del servidor
          print('⚠️ El body parece contener el Content-Type, limpiando...');
          final parts = cleanedBody.split('\n');
          if (parts.length > 1) {
            cleanedBody = parts.sublist(1).join('\n').trim();
          }
        }
        
        responseData = jsonDecode(cleanedBody);
        print('✅ JSON decodificado correctamente: $responseData');
      } catch (e, stackTrace) {
        print('❌ Error decodificando JSON: $e');
        print('❌ Stack trace: $stackTrace');
        print('❌ Body recibido (primeros 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        print('❌ Headers completos: ${response.headers}');
        
        // Si el error menciona "Invalid media type", el problema está en el Content-Type
        if (e.toString().contains('Invalid media type') || e.toString().contains('application/json, application/json')) {
          print('⚠️ Error de Content-Type duplicado detectado');
          // Intentar parsear el body ignorando el Content-Type
          try {
            final bodyLines = response.body.split('\n');
            String jsonBody = response.body;
            // Si el body comienza con "application/json", saltar esa línea
            if (bodyLines.isNotEmpty && bodyLines[0].contains('application/json')) {
              jsonBody = bodyLines.sublist(1).join('\n').trim();
            }
            responseData = jsonDecode(jsonBody);
            print('✅ JSON decodificado después de limpiar Content-Type: $responseData');
          } catch (e2) {
            print('❌ Error persistente después de limpiar: $e2');
            return ApiResponse.error('Error al procesar la respuesta del servidor. El servidor puede estar devolviendo un Content-Type duplicado.');
          }
        } else {
          return ApiResponse.error('Error al procesar la respuesta del servidor: $e');
        }
      }

      if ((response.statusCode == 201 || response.statusCode == 200) && 
          responseData['success'] == true) {
        // Verificar que data existe
        if (responseData['data'] == null) {
          print('❌ Error: responseData[\'data\'] es null');
          return ApiResponse.error('El servidor no devolvió datos del usuario');
        }
        
        // Guardar usuario en SharedPreferences
        final userData = responseData['data'];
        print('📋 Datos del usuario recibidos: $userData');
        
        // Validar campos requeridos
        if (userData['id'] == null || userData['email'] == null || userData['name'] == null) {
          print('❌ Error: Faltan campos requeridos en userData');
          return ApiResponse.error('Datos incompletos del usuario');
        }
        
        final user = User(
          id: userData['id'].toString(),
          email: userData['email'].toString(),
          name: userData['name'].toString(),
          profileImage: userData['profileImage']?.toString(), // Puede ser null
        );
        
        // Guardar usuario actual
        try {
          await _saveCurrentUser(user);
          print('✅ Usuario guardado en SharedPreferences');
        } catch (e) {
          print('⚠️ Error guardando usuario en SharedPreferences: $e');
          // Continuar aunque falle el guardado local
        }
        
        print('✅ Usuario registrado exitosamente: ${user.name} (${user.email})');
        
        return ApiResponse.success(user, message: responseData['message'] ?? 'Usuario registrado exitosamente');
      } else {
        final errorMsg = responseData['error'] ?? responseData['message'] ?? 'Error al registrar usuario';
        print('❌ Error en registro: $errorMsg');
        return ApiResponse.error(errorMsg);
      }
    } catch (e) {
      print('❌ Error en registro: $e');
      if (e.toString().contains('TimeoutException') || e.toString().contains('SocketException')) {
        return ApiResponse.error('Error de conexión. Verifica que el backend esté ejecutándose.');
      }
      return ApiResponse.error('Error al registrar usuario: $e');
    }
  }
  
  /// Guarda el usuario actual en SharedPreferences
  Future<void> _saveCurrentUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, json.encode(user.toJson()));
    } catch (e) {
      print('⚠️ Error guardando usuario actual: $e');
    }
  }
  
  /// Obtiene el usuario actual guardado
  Future<User?> getCurrentUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      if (userJson != null) {
        final userData = json.decode(userJson);
        return User.fromJson(userData);
      }
    } catch (e) {
      print('⚠️ Error obteniendo usuario actual: $e');
    }
    return null;
  }

}
