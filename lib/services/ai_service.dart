import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../model/api_response.dart';

class AIService {
  // URL del backend (ajusta según tu configuración)
  static const String baseUrl = 'http://localhost:5000';
  
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

  /// Verifica si el backend está funcionando
  Future<ApiResponse<bool>> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(
          data['model_loaded'] ?? false,
          message: data['message'] ?? 'API funcionando'
        );
      } else {
        return ApiResponse.error('Error conectando con el servidor');
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Analiza una imagen para detectar cáncer de colon
  Future<ApiResponse<Map<String, dynamic>>> analyzeImage(XFile image) async {
    try {
      // Convertir imagen a base64
      final base64Image = await _imageToBase64(image);
      if (base64Image == null) {
        return ApiResponse.error('Error procesando la imagen');
      }

      // Enviar petición al backend
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return ApiResponse.success(data, message: 'Análisis completado');
        } else {
          return ApiResponse.error(data['error'] ?? 'Error en el análisis');
        }
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Analiza una imagen desde bytes (para imágenes de red)
  Future<ApiResponse<Map<String, dynamic>>> analyzeImageFromBytes(Uint8List imageBytes) async {
    try {
      // Convertir bytes a base64
      final base64Image = base64Encode(imageBytes);

      // Enviar petición al backend
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return ApiResponse.success(data, message: 'Análisis completado');
        } else {
          return ApiResponse.error(data['error'] ?? 'Error en el análisis');
        }
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
      }
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Simula análisis para desarrollo (cuando el backend no está disponible)
  Future<ApiResponse<Map<String, dynamic>>> simulateAnalysis() async {
    try {
      // Simular delay de procesamiento
      await Future.delayed(const Duration(seconds: 3));
      
      // Datos simulados
      final mockData = {
        'analysis_id': 'sim_${DateTime.now().millisecondsSinceEpoch}',
        'result': 'Cáncer de Colon Detectado',
        'confidence': 0.87,
        'stage': 'Requiere atención médica inmediata',
        'risk_level': 'Alto',
        'recommendation': 'Consulte con un especialista para confirmación'
      };
      
      return ApiResponse.success(mockData, message: 'Análisis simulado completado');
    } catch (e) {
      return ApiResponse.error('Error en análisis simulado: $e');
    }
  }
}
