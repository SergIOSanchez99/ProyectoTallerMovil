import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../model/api_response.dart';

/// Servicio de segmentación de imágenes médicas de colonoscopia.
///
/// Intenta llamar al endpoint [/segment] del backend.
/// Si no está disponible, genera una segmentación simulada coloreando
/// píxeles según su luminosidad usando el paquete `image`.
class SegmentationService {
  static const String _baseUrl = 'http://127.0.0.1:5000';

  // ─── API pública ──────────────────────────────────────────────────────────

  /// Segmenta una imagen a partir de sus bytes (PNG o JPEG).
  ///
  /// [imageBytes] — bytes crudos de la imagen.
  /// [alpha]      — opacidad del overlay de colores (0.0–1.0).
  ///
  /// Respuesta exitosa contiene:
  ///   - `segmented_image` : String base64 de la imagen segmentada.
  ///   - `statistics`      : Map con porcentajes de tejido sano, canceroso y background.
  Future<ApiResponse<Map<String, dynamic>>> segmentImageFromBytes(
    Uint8List imageBytes, {
    double alpha = 0.5,
  }) async {
    // 1. Intentar con el backend real
    try {
      final backendResult = await _callBackendSegment(imageBytes, alpha);
      if (backendResult != null) return backendResult;
    } catch (_) {
      // Backend no disponible → fallback local
    }

    // 2. Segmentación simulada en el cliente
    return _simulateSegmentation(imageBytes, alpha);
  }

  /// Decodifica una cadena base64 a bytes de imagen.
  /// Elimina el prefijo `data:image/...;base64,` si existe.
  Uint8List? decodeBase64Image(String base64String) {
    try {
      if (base64String.isEmpty) return null;
      String clean = base64String;
      if (clean.contains(',')) clean = clean.split(',').last;
      return base64Decode(clean);
    } catch (e) {
      print('⚠️ Error decodificando imagen: $e');
      return null;
    }
  }

  // ─── Backend ──────────────────────────────────────────────────────────────

  Future<ApiResponse<Map<String, dynamic>>?> _callBackendSegment(
    Uint8List imageBytes,
    double alpha,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/segment'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'image': base64Encode(imageBytes),
            'alpha': alpha,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return ApiResponse.success(data,
            message: 'Segmentación completada por el backend');
      }
    }
    return null; // 404 o error → usar fallback
  }

  // ─── Fallback local ───────────────────────────────────────────────────────

  Future<ApiResponse<Map<String, dynamic>>> _simulateSegmentation(
    Uint8List imageBytes,
    double alpha,
  ) async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Decodificar imagen con el paquete image
      final original = img.decodeImage(imageBytes);
      if (original == null) {
        return ApiResponse.error('No se pudo decodificar la imagen');
      }

      // Aplicar mapa de colores por luminosidad
      final segmented = _applySegmentationColors(original, alpha);

      // Codificar resultado como PNG
      final pngBytes = Uint8List.fromList(img.encodePng(segmented));
      final base64Result = base64Encode(pngBytes);

      // Calcular estadísticas reales de la segmentación
      final stats = _computeStatistics(original, alpha);

      return ApiResponse.success(
        {
          'success': true,
          'segmented_image': base64Result,
          'statistics': stats,
          'source': 'simulated',
        },
        message: 'Segmentación simulada completada',
      );
    } catch (e) {
      return ApiResponse.error('Error en segmentación: $e');
    }
  }

  /// Aplica colores de segmentación sobre la imagen original:
  /// • negro → background (luma < 40)
  /// • verde → tejido sano (40 ≤ luma ≤ 160)
  /// • rojo  → tejido canceroso (luma > 160)
  img.Image _applySegmentationColors(img.Image source, double alpha) {
    final output = img.Image(width: source.width, height: source.height);

    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final luma = (0.299 * r + 0.587 * g + 0.114 * b).round();

        int nr, ng, nb;

        if (luma < 40) {
          // Background → oscurecer
          nr = (r * (1 - alpha)).round();
          ng = (g * (1 - alpha)).round();
          nb = (b * (1 - alpha)).round();
        } else if (luma > 160) {
          // Alta intensidad → tinte rojo (canceroso)
          nr = _blend(r, 220, alpha);
          ng = _blend(g, 30, alpha);
          nb = _blend(b, 30, alpha);
        } else {
          // Intensidad media → tinte verde (sano)
          nr = _blend(r, 30, alpha);
          ng = _blend(g, 200, alpha);
          nb = _blend(b, 30, alpha);
        }

        output.setPixelRgba(x, y, nr, ng, nb, 255);
      }
    }

    return output;
  }

  int _blend(int original, int target, double alpha) {
    return ((original * (1 - alpha)) + (target * alpha)).round().clamp(0, 255);
  }

  /// Calcula estadísticas reales de segmentación contando píxeles por zona.
  Map<String, dynamic> _computeStatistics(img.Image source, double alpha) {
    int healthy = 0, cancerous = 0, background = 0;
    final total = source.width * source.height;

    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        final luma = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b)
            .round();
        if (luma < 40) {
          background++;
        } else if (luma > 160) {
          cancerous++;
        } else {
          healthy++;
        }
      }
    }

    return {
      'healthy_percentage': (healthy / total * 100),
      'cancerous_percentage': (cancerous / total * 100),
      'background_percentage': (background / total * 100),
    };
  }
}
