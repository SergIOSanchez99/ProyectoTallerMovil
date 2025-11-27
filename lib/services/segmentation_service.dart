import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../model/api_response.dart';

class SegmentationService {
  // URL del backend (ajusta según tu configuración)
  // Para desarrollo local: 'http://localhost:5000' o 'http://10.0.2.2:5000' (Android Emulator)
  static const String baseUrl = 'https://taller-backend-663984572750.us-central1.run.app';
  
  /// Convierte una imagen a base64 para enviar al backend
  Future<String?> _imageToBase64(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      print('Error convirtiendo imagen a base64: $e');
      return null;
    }
  }

  /// Convierte bytes de imagen a base64
  String _bytesToBase64(Uint8List bytes) {
    try {
      return base64Encode(bytes);
    } catch (e) {
      print('Error convirtiendo bytes a base64: $e');
      rethrow;
    }
  }

  /// Segmenta una imagen médica
  Future<ApiResponse<Map<String, dynamic>>> segmentImage(
    XFile image, {
    double alpha = 0.5,
  }) async {
    try {
      print('🔵 [SegmentationService] Iniciando segmentación de imagen...');
      
      // Convertir imagen a base64
      final base64Image = await _imageToBase64(image);
      if (base64Image == null) {
        print('❌ [SegmentationService] Error: base64Image es null');
        return ApiResponse.error('Error procesando la imagen');
      }

      if (base64Image.isEmpty) {
        print('❌ [SegmentationService] Error: base64Image está vacío');
        return ApiResponse.error('La imagen codificada está vacía');
      }
      
      print('✅ [SegmentationService] Imagen codificada: ${base64Image.length} caracteres');
      
      // Enviar petición al backend
      final jsonBody = jsonEncode({
        'image': base64Image,
        'alpha': alpha,
      });
      
      if (jsonBody.isEmpty || jsonBody == '{}') {
        print('❌ [SegmentationService] Error: jsonBody está vacío');
        return ApiResponse.error('Error generando el cuerpo de la petición');
      }
      
      print('✅ [SegmentationService] JSON generado: ${jsonBody.length} caracteres');
      
      // Crear headers
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };
      
      print('📤 [SegmentationService] Enviando petición POST a: $baseUrl/segment');
      
      final response = await http.post(
        Uri.parse('$baseUrl/segment'),
        headers: headers,
        body: jsonBody,
      );

      print('📥 [SegmentationService] Respuesta recibida: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          print('✅ [SegmentationService] Segmentación completada exitosamente');
          return ApiResponse.success(data, message: 'Segmentación completada');
        } else {
          print('❌ [SegmentationService] Error en segmentación: ${data['error']}');
          return ApiResponse.error(data['error'] ?? 'Error en la segmentación');
        }
      } else {
        print('❌ [SegmentationService] Error del servidor: Status ${response.statusCode}');
        final errorData = json.decode(response.body);
        print('❌ [SegmentationService] Error message: ${errorData['error']}');
        return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
      }
    } catch (e, stackTrace) {
      print('❌ [SegmentationService] Excepción: $e');
      print('❌ [SegmentationService] Stack trace: $stackTrace');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Segmenta una imagen desde bytes
  Future<ApiResponse<Map<String, dynamic>>> segmentImageFromBytes(
    Uint8List imageBytes, {
    double alpha = 0.5,
  }) async {
    try {
      print('🔵 [SegmentationService] Iniciando segmentación desde bytes (${imageBytes.length} bytes)...');
      
      // Convertir bytes a base64
      final base64Image = _bytesToBase64(imageBytes);

      if (base64Image.isEmpty) {
        print('❌ [SegmentationService] Error: base64Image está vacío');
        return ApiResponse.error('La imagen codificada está vacía');
      }
      
      print('✅ [SegmentationService] Imagen codificada: ${base64Image.length} caracteres');
      
      // Enviar petición al backend
      final jsonBody = jsonEncode({
        'image': base64Image,
        'alpha': alpha,
      });
      
      if (jsonBody.isEmpty || jsonBody == '{}') {
        print('❌ [SegmentationService] Error: jsonBody está vacío');
        return ApiResponse.error('Error generando el cuerpo de la petición');
      }
      
      print('✅ [SegmentationService] JSON generado: ${jsonBody.length} caracteres');
      
      // Crear headers
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };
      
      print('📤 [SegmentationService] Enviando petición POST a: $baseUrl/segment');
      
      final response = await http.post(
        Uri.parse('$baseUrl/segment'),
        headers: headers,
        body: jsonBody,
      );

      print('📥 [SegmentationService] Respuesta recibida: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          print('✅ [SegmentationService] Segmentación completada exitosamente');
          return ApiResponse.success(data, message: 'Segmentación completada');
        } else {
          print('❌ [SegmentationService] Error en segmentación: ${data['error']}');
          return ApiResponse.error(data['error'] ?? 'Error en la segmentación');
        }
      } else {
        print('❌ [SegmentationService] Error del servidor: Status ${response.statusCode}');
        final errorData = json.decode(response.body);
        print('❌ [SegmentationService] Error message: ${errorData['error']}');
        return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
      }
    } catch (e, stackTrace) {
      print('❌ [SegmentationService] Excepción: $e');
      print('❌ [SegmentationService] Stack trace: $stackTrace');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Decodifica una imagen base64 a bytes
  Uint8List? decodeBase64Image(String base64String) {
    try {
      // Remover prefijo data URI si existe
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',')[1];
      }
      
      return base64Decode(cleanBase64);
    } catch (e) {
      print('Error decodificando imagen base64: $e');
      return null;
    }
  }
}

