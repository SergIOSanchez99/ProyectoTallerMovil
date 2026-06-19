import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Servicio para guardar y recuperar imágenes de forma persistente
class ImageStorageService {
  static const String _imagesFolderName = 'colonoscopy_images';

  /// Obtiene el directorio donde se guardarán las imágenes
  static Future<Directory> _getImagesDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDocDir.path}/$_imagesFolderName');

    // Crear el directorio si no existe
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
      print('📁 Directorio de imágenes creado: ${imagesDir.path}');
    }

    return imagesDir;
  }

  /// Guarda una imagen y retorna la ruta donde se guardó
  ///
  /// [imageBytes] - Los bytes de la imagen a guardar
  /// [fileName] - Nombre del archivo (opcional, se genera automáticamente si no se proporciona)
  ///
  /// Retorna la ruta completa del archivo guardado
  static Future<String> saveImage(
    Uint8List imageBytes, {
    String? fileName,
  }) async {
    try {
      final imagesDir = await _getImagesDirectory();

      // Generar nombre de archivo si no se proporciona
      if (fileName == null || fileName.isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        fileName = 'image_$timestamp.jpg';
      }

      // Asegurar que el nombre del archivo tenga extensión
      if (!fileName.toLowerCase().endsWith('.jpg') &&
          !fileName.toLowerCase().endsWith('.jpeg') &&
          !fileName.toLowerCase().endsWith('.png')) {
        fileName = '$fileName.jpg';
      }

      final filePath = '${imagesDir.path}/$fileName';
      final file = File(filePath);

      // Guardar la imagen
      await file.writeAsBytes(imageBytes);

      print('✅ Imagen guardada exitosamente: $filePath');
      print('📊 Tamaño: ${imageBytes.length} bytes');

      return filePath;
    } catch (e) {
      print('❌ Error guardando imagen: $e');
      rethrow;
    }
  }

  /// Carga una imagen desde una ruta
  ///
  /// [imagePath] - Ruta completa del archivo de imagen
  ///
  /// Retorna los bytes de la imagen o null si no se encuentra
  static Future<Uint8List?> loadImage(String imagePath) async {
    try {
      final file = File(imagePath);

      if (!await file.exists()) {
        print('⚠️ La imagen no existe en la ruta: $imagePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      print('✅ Imagen cargada exitosamente: $imagePath');
      print('📊 Tamaño: ${bytes.length} bytes');

      return bytes;
    } catch (e) {
      print('❌ Error cargando imagen: $imagePath - $e');
      return null;
    }
  }

  /// Elimina una imagen
  ///
  /// [imagePath] - Ruta completa del archivo de imagen a eliminar
  static Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);

      if (await file.exists()) {
        await file.delete();
        print('✅ Imagen eliminada: $imagePath');
        return true;
      } else {
        print('⚠️ La imagen no existe: $imagePath');
        return false;
      }
    } catch (e) {
      print('❌ Error eliminando imagen: $imagePath - $e');
      return false;
    }
  }

  /// Obtiene todas las imágenes guardadas
  ///
  /// Retorna una lista de rutas de archivos
  static Future<List<String>> getAllImages() async {
    try {
      final imagesDir = await _getImagesDirectory();

      if (!await imagesDir.exists()) {
        return [];
      }

      final files = imagesDir
          .listSync()
          .whereType<File>()
          .map((entity) => entity.path)
          .where((path) {
        final ext = path.toLowerCase().split('.').last;
        return ext == 'jpg' || ext == 'jpeg' || ext == 'png';
      }).toList();

      print('📁 Imágenes encontradas: ${files.length}');
      return files;
    } catch (e) {
      print('❌ Error obteniendo imágenes: $e');
      return [];
    }
  }

  /// Genera un nombre de archivo único basado en timestamp y datos del análisis
  static String generateImageFileName({
    String? result,
    DateTime? date,
  }) {
    final timestamp =
        date?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
    final resultPart = result != null && result.isNotEmpty
        ? '_${result.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}'
        : '';
    return 'colonoscopy${resultPart}_$timestamp.jpg';
  }

  /// Obtiene la ruta relativa desde el directorio de documentos
  /// Útil para almacenar en la base de datos
  static Future<String> getRelativePath(String fullPath) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    if (fullPath.startsWith(appDocDir.path)) {
      return fullPath.substring(appDocDir.path.length + 1);
    }
    return fullPath;
  }

  /// Convierte una ruta relativa a ruta absoluta
  static Future<String> getAbsolutePath(String relativePath) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    // Normalizar separadores de ruta
    final normalizedPath = relativePath.replaceAll('\\', '/');
    return '${appDocDir.path}/$normalizedPath';
  }
}
