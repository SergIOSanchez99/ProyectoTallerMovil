// Stub para cuando estamos en web
// Este archivo se usa cuando dart:io no está disponible

import 'dart:typed_data';

class PDFMobileHandler {
  static Future<bool> handleDownload(Uint8List pdfBytes, Map<String, dynamic> reportData) async {
    // Este método nunca se debería llamar si estamos en web
    throw UnsupportedError('handleDownload solo está disponible en plataformas móviles');
  }
}

