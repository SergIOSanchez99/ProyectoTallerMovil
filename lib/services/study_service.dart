import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/api_response.dart';

class StudyService {
  // URL del backend (ajusta según tu configuración)
  static const String baseUrl = 'https://taller-backend-663984572750.us-central1.run.app';
  
  /// Crea un nuevo estudio/reporte
  Future<ApiResponse<Map<String, dynamic>>> createStudy({
    required String result,
    String? stage,
    double? confidence,
    String? riskLevel,
    int? patientId,
    int? userId,
    String? imagePath,
    String? studyDate,
    String? doctorName,
    String? observations,
  }) async {
    try {
      final body = {
        'result': result,
        if (stage != null) 'stage': stage,
        if (confidence != null) 'confidence': confidence,
        if (riskLevel != null) 'risk_level': riskLevel,
        if (patientId != null) 'patient_id': patientId,
        if (userId != null) 'user_id': userId,
        if (imagePath != null) 'image_path': imagePath,
        if (studyDate != null) 'study_date': studyDate,
        if (doctorName != null) 'doctor_name': doctorName,
        if (observations != null) 'observations': observations,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/studies'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      print('📤 POST /studies - Status: ${response.statusCode}');
      print('📤 Request Body: ${json.encode(body)}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = json.decode(response.body);
          
          if (data['success'] == true) {
            return ApiResponse.success(
              data['data'] as Map<String, dynamic>,
              message: data['message'] ?? 'Estudio creado exitosamente'
            );
          } else {
            final errorMsg = data['error'] ?? data['message'] ?? 'Error al crear estudio';
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
      print('❌ Excepción en createStudy: $e');
      print('❌ Stack trace: $stackTrace');
      if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        return ApiResponse.error('No se pudo conectar al servidor. Verifica que el backend esté corriendo en $baseUrl');
      }
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Obtiene todos los estudios
  Future<ApiResponse<List<Map<String, dynamic>>>> getAllStudies({
    int? userId,
    int? patientId,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (userId != null) {
        queryParams['user_id'] = userId.toString();
      }
      if (patientId != null) {
        queryParams['patient_id'] = patientId.toString();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      if (offset != null) {
        queryParams['offset'] = offset.toString();
      }
      
      final uri = Uri.parse('$baseUrl/studies').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('📤 GET /studies - Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          
          if (data['success'] == true) {
            final studies = (data['data'] as List)
                .map((s) => s as Map<String, dynamic>)
                .toList();
            return ApiResponse.success(
              studies,
              message: data['message'] ?? 'Estudios obtenidos exitosamente'
            );
          } else {
            return ApiResponse.error(data['error'] ?? 'Error al obtener estudios');
          }
        } catch (e) {
          print('❌ Error al decodificar respuesta: $e');
          return ApiResponse.error('Error al procesar respuesta del servidor: $e');
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
        } catch (e) {
          return ApiResponse.error('Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Excepción en getAllStudies: $e');
      print('❌ Stack trace: $stackTrace');
      if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        return ApiResponse.error('No se pudo conectar al servidor. Verifica que el backend esté corriendo en $baseUrl');
      }
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Obtiene un estudio por ID
  Future<ApiResponse<Map<String, dynamic>>> getStudyById(int studyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/studies/$studyId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📤 GET /studies/$studyId - Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          
          if (data['success'] == true) {
            return ApiResponse.success(
              data['data'] as Map<String, dynamic>,
              message: data['message'] ?? 'Estudio obtenido exitosamente'
            );
          } else {
            return ApiResponse.error(data['error'] ?? 'Error al obtener estudio');
          }
        } catch (e) {
          print('❌ Error al decodificar respuesta: $e');
          return ApiResponse.error('Error al procesar respuesta del servidor: $e');
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
        } catch (e) {
          return ApiResponse.error('Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Excepción en getStudyById: $e');
      print('❌ Stack trace: $stackTrace');
      if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        return ApiResponse.error('No se pudo conectar al servidor. Verifica que el backend esté corriendo en $baseUrl');
      }
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Elimina un estudio
  Future<ApiResponse<void>> deleteStudy(int studyId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/studies/$studyId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📤 DELETE /studies/$studyId - Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          
          if (data['success'] == true) {
            return ApiResponse.success(
              null,
              message: data['message'] ?? 'Estudio eliminado exitosamente'
            );
          } else {
            return ApiResponse.error(data['error'] ?? 'Error al eliminar estudio');
          }
        } catch (e) {
          print('❌ Error al decodificar respuesta: $e');
          return ApiResponse.error('Error al procesar respuesta del servidor: $e');
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
        } catch (e) {
          return ApiResponse.error('Error del servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Excepción en deleteStudy: $e');
      print('❌ Stack trace: $stackTrace');
      if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
        return ApiResponse.error('No se pudo conectar al servidor. Verifica que el backend esté corriendo en $baseUrl');
      }
      return ApiResponse.error('Error de conexión: $e');
    }
  }
}

