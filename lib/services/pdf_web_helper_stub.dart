// Stub para cuando no estamos en web
// Este archivo se usa cuando dart:html no está disponible

import 'dart:typed_data';

class PDFWebHelper {
  static Future<bool> downloadPDF(Uint8List pdfBytes, String fileName) async {
    // Este método nunca se debería llamar si no estamos en web
    throw UnsupportedError('downloadPDF solo está disponible en web');
  }
}

