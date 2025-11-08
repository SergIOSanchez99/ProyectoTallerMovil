// Helper para descargar PDFs en web
// Este archivo solo se usa cuando kIsWeb es true

import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

class PDFWebHelper {
  /// Descarga un PDF en el navegador
  static Future<bool> downloadPDF(Uint8List pdfBytes, String fileName) async {
    try {
      print('🌐 Descargando PDF en web: $fileName');
      
      // Crear blob
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Crear elemento anchor y simular clic
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      
      // Limpiar URL
      html.Url.revokeObjectUrl(url);
      
      print('✅ PDF descargado exitosamente');
      return true;
    } catch (e) {
      print('❌ Error descargando PDF: $e');
      
      // Método alternativo: usar data URL
      try {
        final base64 = base64Encode(pdfBytes);
        final dataUrl = 'data:application/pdf;base64,$base64';
        
        final anchor = html.AnchorElement(href: dataUrl)
          ..setAttribute('download', fileName)
          ..style.display = 'none';
        
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        
        print('✅ PDF descargado usando data URL');
        return true;
      } catch (e2) {
        print('❌ Error con método alternativo: $e2');
        return false;
      }
    }
  }
}

