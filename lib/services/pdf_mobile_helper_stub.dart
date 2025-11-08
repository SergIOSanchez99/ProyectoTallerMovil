// Stub para cuando estamos en web
// Este archivo se usa cuando dart:io no está disponible
// NOTA: Este código nunca se ejecutará en web porque está dentro de un bloque if (!kIsWeb)

class PDFMobileHelper {
  static Future<bool> sharePDF(dynamic file, String filePath) async {
    // Este método nunca se debería llamar si estamos en web
    // porque está dentro de un bloque if (!kIsWeb)
    throw UnsupportedError('sharePDF solo está disponible en plataformas móviles');
  }
  
  // Tipo dinámico para evitar problemas de tipo en tiempo de compilación
  // En web, este método nunca se llamará
  static dynamic createFile(String filePath) {
    // Este método nunca se debería llamar si estamos en web
    // porque está dentro de un bloque if (!kIsWeb)
    throw UnsupportedError('createFile solo está disponible en plataformas móviles');
  }
}

