import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../model/api_response.dart';

class AIService {
  // URL del backend (ajusta según tu configuración)
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
      print('🔵 [AIService] Iniciando análisis de imagen...');
      
      // Convertir imagen a base64
      final base64Image = await _imageToBase64(image);
      if (base64Image == null) {
        print('❌ [AIService] Error: base64Image es null');
        return ApiResponse.error('Error procesando la imagen');
      }

      // Validar que la imagen base64 no esté vacía
      if (base64Image.isEmpty) {
        print('❌ [AIService] Error: base64Image está vacío');
        return ApiResponse.error('La imagen codificada está vacía');
      }
      
      print('✅ [AIService] Imagen codificada: ${base64Image.length} caracteres');
      
      // Enviar petición al backend
      final jsonBody = jsonEncode({
        'image': base64Image,
      });
      
      // Validar que el JSON no esté vacío
      if (jsonBody.isEmpty || jsonBody == '{}') {
        print('❌ [AIService] Error: jsonBody está vacío o es {}');
        return ApiResponse.error('Error generando el cuerpo de la petición');
      }
      
      print('✅ [AIService] JSON generado: ${jsonBody.length} caracteres');
      print('📝 [AIService] JSON preview (primeros 100 chars): ${jsonBody.substring(0, jsonBody.length > 100 ? 100 : jsonBody.length)}...');
      
      // Crear headers explícitos
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };
      
      print('📤 [AIService] Enviando petición POST a: $baseUrl/predict');
      print('📋 [AIService] Headers: $headers');
      print('📦 [AIService] Body length: ${jsonBody.length} caracteres');
      
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: headers,
        body: jsonBody,
      );

      print('📥 [AIService] Respuesta recibida: Status ${response.statusCode}');
      print('📄 [AIService] Response body (primeros 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          print('✅ [AIService] Análisis completado exitosamente');
          return ApiResponse.success(data, message: 'Análisis completado');
        } else {
          print('❌ [AIService] Error en análisis: ${data['error']}');
          return ApiResponse.error(data['error'] ?? 'Error en el análisis');
        }
      } else {
        print('❌ [AIService] Error del servidor: Status ${response.statusCode}');
        final errorData = json.decode(response.body);
        print('❌ [AIService] Error message: ${errorData['error']}');
        return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
      }
    } catch (e, stackTrace) {
      print('❌ [AIService] Excepción: $e');
      print('❌ [AIService] Stack trace: $stackTrace');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Analiza una imagen desde bytes (para imágenes de red)
  Future<ApiResponse<Map<String, dynamic>>> analyzeImageFromBytes(Uint8List imageBytes) async {
    try {
      print('🔵 [AIService] Iniciando análisis desde bytes (${imageBytes.length} bytes)...');
      
      // Convertir bytes a base64
      final base64Image = base64Encode(imageBytes);

      // Validar que la imagen base64 no esté vacía
      if (base64Image.isEmpty) {
        print('❌ [AIService] Error: base64Image está vacío');
        return ApiResponse.error('La imagen codificada está vacía');
      }
      
      print('✅ [AIService] Imagen codificada: ${base64Image.length} caracteres');
      
      // Enviar petición al backend
      final jsonBody = jsonEncode({
        'image': base64Image,
      });
      
      // Validar que el JSON no esté vacío
      if (jsonBody.isEmpty || jsonBody == '{}') {
        print('❌ [AIService] Error: jsonBody está vacío o es {}');
        return ApiResponse.error('Error generando el cuerpo de la petición');
      }
      
      print('✅ [AIService] JSON generado: ${jsonBody.length} caracteres');
      
      // Crear headers explícitos
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };
      
      print('📤 [AIService] Enviando petición POST a: $baseUrl/predict');
      print('📋 [AIService] Headers: $headers');
      print('📦 [AIService] Body length: ${jsonBody.length} caracteres');
      
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: headers,
        body: jsonBody,
      );

      print('📥 [AIService] Respuesta recibida: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          print('✅ [AIService] Análisis completado exitosamente');
          return ApiResponse.success(data, message: 'Análisis completado');
        } else {
          print('❌ [AIService] Error en análisis: ${data['error']}');
          return ApiResponse.error(data['error'] ?? 'Error en el análisis');
        }
      } else {
        print('❌ [AIService] Error del servidor: Status ${response.statusCode}');
        final errorData = json.decode(response.body);
        print('❌ [AIService] Error message: ${errorData['error']}');
        return ApiResponse.error(errorData['error'] ?? 'Error del servidor');
      }
    } catch (e, stackTrace) {
      print('❌ [AIService] Excepción: $e');
      print('❌ [AIService] Stack trace: $stackTrace');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  /// Simula análisis para desarrollo (cuando el backend no está disponible)
  Future<ApiResponse<Map<String, dynamic>>> simulateAnalysis() async {
    try {
      // Simular delay de procesamiento
      await Future.delayed(const Duration(seconds: 3));
      
      // Generar resultados variados y realistas
      final results = [
        {
          'result': 'Cáncer de Colon Detectado',
          'confidence': 0.87,
          'stage': 'Requiere atención médica inmediata',
          'risk_level': 'Alto',
          'recommendation': 'Consulte con un especialista para confirmación'
        },
        {
          'result': 'Tejido Benigno',
          'confidence': 0.23,
          'stage': 'Sin signos de cáncer',
          'risk_level': 'Bajo',
          'recommendation': 'Mantenga revisiones regulares'
        },
        {
          'result': 'Posible Cáncer de Colon',
          'confidence': 0.65,
          'stage': 'Requiere evaluación médica urgente',
          'risk_level': 'Medio-Alto',
          'recommendation': 'Programe una consulta médica lo antes posible'
        },
        {
          'result': 'Anomalía Detectada',
          'confidence': 0.42,
          'stage': 'Revisión médica recomendada',
          'risk_level': 'Medio',
          'recommendation': 'Consulte con su médico para seguimiento'
        },
        {
          'result': 'Tejido Normal',
          'confidence': 0.15,
          'stage': 'Sin signos de cáncer',
          'risk_level': 'Bajo',
          'recommendation': 'Continúe con revisiones periódicas'
        }
      ];
      
      // Seleccionar resultado aleatorio
      final randomIndex = DateTime.now().millisecondsSinceEpoch % results.length;
      final selectedResult = results[randomIndex];
      
      // Datos simulados con resultado variado
      final mockData = {
        'analysis_id': 'sim_${DateTime.now().millisecondsSinceEpoch}',
        'result': selectedResult['result'],
        'confidence': selectedResult['confidence'],
        'stage': selectedResult['stage'],
        'risk_level': selectedResult['risk_level'],
        'recommendation': selectedResult['recommendation']
      };
      
      return ApiResponse.success(mockData, message: 'Análisis simulado completado');
    } catch (e) {
      return ApiResponse.error('Error en análisis simulado: $e');
    }
  }
}
