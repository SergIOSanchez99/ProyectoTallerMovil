import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/api_response.dart';

class PatientService {
  // URL del backend (ajusta según tu configuración)
  static const String baseUrl = 'https://taller-backend-663984572750.us-central1.run.app';
  
  /// Obtiene todos los pacientes
  Future<ApiResponse<List<Map<String, dynamic>>>> getAllPatients({
    bool activeOnly = true,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'active_only': activeOnly.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final uri = Uri.parse('$baseUrl/patients').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final patients = (data['data'] as List)
              .map((p) => p as Map<String, dynamic>)
              .toList();
          return ApiResponse.success(
            patients,
            message: data['message'] ?? 'Pacientes obtenidos exitosamente'
          );
        } else {
          return ApiResponse.error(data['error'] ?? 'Error al obtener pacientes');
        }
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Obtiene un paciente por ID
  Future<ApiResponse<Map<String, dynamic>>> getPatientById(int patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/patients/$patientId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return ApiResponse.success(
            data['data'] as Map<String, dynamic>,
            message: data['message'] ?? 'Paciente obtenido exitosamente'
          );
        } else {
          return ApiResponse.error(data['error'] ?? 'Paciente no encontrado');
        }
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Busca un paciente por identificación
  Future<ApiResponse<Map<String, dynamic>>> searchPatientByIdentification(String identification) async {
    try {
      final uri = Uri.parse('$baseUrl/patients/search').replace(
        queryParameters: {'identification': identification},
      );
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return ApiResponse.success(
            data['data'] as Map<String, dynamic>,
            message: data['message'] ?? 'Paciente encontrado'
          );
        } else {
          return ApiResponse.error(data['error'] ?? 'Paciente no encontrado');
        }
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Crea un nuevo paciente
  Future<ApiResponse<Map<String, dynamic>>> createPatient({
    required String fullName,
    required String identification,
    int? age,
  }) async {
    try {
      final body = jsonEncode({
        'full_name': fullName,
        'identification': identification,
        if (age != null) 'age': age,
      });

      print('📤 Enviando petición POST a: $baseUrl/patients');
      print('📤 Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/patients'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifica que el servidor esté corriendo.');
        },
      );

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = json.decode(response.body);
          
          if (data['success'] == true) {
            return ApiResponse.success(
              data['data'] as Map<String, dynamic>,
              message: data['message'] ?? 'Paciente creado exitosamente'
            );
          } else {
            final errorMsg = data['error'] ?? data['message'] ?? 'Error al crear paciente';
            print('❌ Error en respuesta: $errorMsg');
            return ApiResponse.error(errorMsg);
          }
        } catch (e) {
          print('❌ Error al decodificar respuesta: $e');
          return ApiResponse.error('Error al procesar respuesta del servidor: $e');
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMsg = errorData['error'] ?? errorData['message'] ?? 'Error del servidor (${response.statusCode})';
          print('❌ Error HTTP ${response.statusCode}: $errorMsg');
          return ApiResponse.error(errorMsg);
        } catch (e) {
          print('❌ Error al decodificar error: $e');
          return ApiResponse.error('Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Excepción en createPatient: $e');
      print('❌ Stack trace: $stackTrace');
      if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        return ApiResponse.error('No se pudo conectar al servidor. Verifica que el backend esté corriendo en $baseUrl');
      }
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Actualiza un paciente
  Future<ApiResponse<Map<String, dynamic>>> updatePatient(
    int patientId, {
    String? fullName,
    String? identification,
    int? age,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (fullName != null) body['full_name'] = fullName;
      if (identification != null) body['identification'] = identification;
      if (age != null) body['age'] = age;

      final response = await http.put(
        Uri.parse('$baseUrl/patients/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return ApiResponse.success(
            data['data'] as Map<String, dynamic>,
            message: data['message'] ?? 'Paciente actualizado exitosamente'
          );
        } else {
          return ApiResponse.error(data['error'] ?? 'Error al actualizar paciente');
        }
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Elimina un paciente
  Future<ApiResponse<bool>> deletePatient(int patientId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/patients/$patientId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return ApiResponse.success(
            true,
            message: data['message'] ?? 'Paciente eliminado exitosamente'
          );
        } else {
          return ApiResponse.error(data['error'] ?? 'Error al eliminar paciente');
        }
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }
}

