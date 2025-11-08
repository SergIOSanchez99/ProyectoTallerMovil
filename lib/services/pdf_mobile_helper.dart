// Helper para compartir PDFs en plataformas móviles
// Este archivo solo se usa cuando NO estamos en web

import 'dart:io';
import 'package:share_plus/share_plus.dart';

class PDFMobileHelper {
  /// Comparte un PDF en plataformas móviles usando share_plus
  static Future<bool> sharePDF(File file, String filePath) async {
    try {
      print('📤 Intentando compartir archivo: $filePath');
      
      // Verificar que el archivo existe y tiene contenido
      if (!await file.exists()) {
        print('❌ Error: El archivo no existe antes de compartir');
        throw Exception('El archivo no existe en: $filePath');
      }
      
      final fileSize = await file.length();
      print('📤 Tamaño del archivo: $fileSize bytes');
      
      if (fileSize == 0) {
        print('❌ Error: El archivo está vacío');
        throw Exception('El archivo está vacío');
      }
      
      print('✅ Archivo verificado: $fileSize bytes');
      print('📤 Intentando compartir con share_plus...');
      
      // Intentar compartir con share_plus
      try {
        await Share.shareXFiles(
          [XFile(filePath, mimeType: 'application/pdf')],
          text: 'Reporte de Colonoscopia',
          subject: 'Reporte de Análisis de Colonoscopia',
        );
        print('✅ PDF generado y compartido exitosamente');
        return true;
      } catch (shareError) {
        print('❌ Error específico de share_plus: $shareError');
        print('❌ Tipo de error: ${shareError.runtimeType}');
        
        // Intentar una segunda vez sin especificar mimeType
        try {
          print('🔄 Intentando compartir sin mimeType...');
          await Share.shareXFiles([XFile(filePath)]);
          print('✅ PDF compartido exitosamente (sin mimeType)');
          return true;
        } catch (shareError2) {
          print('❌ Error en segundo intento: $shareError2');
          print('❌ Tipo de error en segundo intento: ${shareError2.runtimeType}');
          throw shareError;
        }
      }
    } catch (shareError, shareStackTrace) {
      print('⚠️ Error al compartir el archivo: $shareError');
      print('⚠️ Tipo de error: ${shareError.runtimeType}');
      print('⚠️ Stack trace del error de compartir: $shareStackTrace');
      print('ℹ️ El archivo PDF se generó correctamente en: $filePath');
      try {
        final fileSize = await file.length();
        print('ℹ️ Tamaño del archivo: $fileSize bytes');
        print('ℹ️ Ruta completa: ${file.absolute.path}');
        print('ℹ️ Archivo existe: ${await file.exists()}');
      } catch (e) {
        print('⚠️ No se pudo obtener información del archivo: $e');
      }
      
      return false;
    }
  }
  
  /// Crea un archivo File en el sistema de archivos móvil
  static File createFile(String filePath) {
    return File(filePath);
  }
}

