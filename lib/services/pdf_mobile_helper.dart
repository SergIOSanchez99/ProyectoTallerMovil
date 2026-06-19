// Helper para operaciones de archivo PDF en plataformas móviles/escritorio
// Solo se usa desde pdf_mobile_handler.dart (compilación nativa)

import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

class PDFMobileHelper {
  /// Crea un objeto File a partir de una ruta
  static File createFile(String path) => File(path);

  /// Comparte el PDF usando share_plus
  static Future<bool> sharePDF(File file, String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Reporte ColonSense',
      );
      return true;
    } catch (e) {
      print('⚠️ Error al compartir PDF: $e');
      return false;
    }
  }

  /// Escribe bytes en un archivo
  static Future<void> writeBytesToFile(File file, Uint8List bytes) async {
    await file.writeAsBytes(bytes);
  }
}
