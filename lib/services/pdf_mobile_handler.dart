// Handler para descargar PDFs en plataformas móviles
// Este archivo solo se compila cuando dart:io está disponible (móvil)

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'pdf_mobile_helper.dart';

class PDFMobileHandler {
  /// Maneja la descarga de PDF en plataformas móviles
  static Future<bool> handleDownload(Uint8List pdfBytes, Map<String, dynamic> reportData) async {
    print('📱 Plataforma móvil detectada - descargando PDF');
    
    // Generar nombre del archivo
    final fileName = _generateFileName(reportData);
    final cleanFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    
    // Intentar guardar en la mejor ubicación disponible
    String? filePath;
    String? savedLocation;
    
    try {
      // Intentar guardar en la carpeta de Descargas (Android) o Documentos (iOS)
      if (Platform.isAndroid) {
        // En Android, intentar usar el directorio de Descargas
        filePath = await _getAndroidDownloadsPath(cleanFileName);
        if (filePath != null) {
          savedLocation = 'Carpeta de Descargas';
          print('📁 Intentando guardar en Descargas: $filePath');
        }
      }
      
      // Si no se pudo obtener la ruta de Descargas, usar el directorio de documentos de la app
      if (filePath == null) {
        print('📁 Obteniendo directorio de documentos de la aplicación...');
        final directory = await getApplicationDocumentsDirectory();
        
        if (!await directory.exists()) {
          print('❌ Error: El directorio no existe: ${directory.path}');
          throw Exception('El directorio de documentos no existe');
        }
        
        filePath = '${directory.path}/$cleanFileName';
        savedLocation = 'Documentos de la aplicación';
        print('📁 Guardando en documentos de la app: $filePath');
      }
      
      // Crear el archivo
      final file = PDFMobileHelper.createFile(filePath!);
      
      // Verificar si el archivo ya existe y eliminarlo
      if (await file.exists()) {
        print('⚠️ El archivo ya existe, eliminándolo...');
        await file.delete();
      }
      
      // Escribir el archivo
      await file.writeAsBytes(pdfBytes);
      
      // Verificar que el archivo se creó correctamente
      if (!await file.exists()) {
        print('❌ Error: El archivo no se creó correctamente');
        throw Exception('Error al crear el archivo PDF');
      }
      
      final fileSize = await file.length();
      print('✅ Archivo creado exitosamente: $filePath');
      print('📊 Tamaño del archivo: $fileSize bytes');
      print('📍 Ubicación: $savedLocation');
      
      // Abrir el diálogo de compartir para que el usuario pueda elegir dónde guardarlo
      // Esto permite al usuario elegir "Guardar" o compartir con otras apps
      print('📤 Abriendo diálogo de compartir/guardar...');
      final shareSuccess = await PDFMobileHelper.sharePDF(file, filePath);
      
      if (shareSuccess) {
        print('✅ PDF compartido/descargado exitosamente');
        return true;
      } else {
        // Aunque el compartir falle, el archivo ya está guardado
        print('⚠️ El diálogo de compartir no se abrió, pero el archivo está guardado en: $filePath');
        return true;
      }
    } catch (e, stackTrace) {
      print('❌ Error guardando PDF: $e');
      print('❌ Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Intenta obtener la ruta de la carpeta de Descargas en Android
  static Future<String?> _getAndroidDownloadsPath(String fileName) async {
    try {
      if (!Platform.isAndroid) {
        return null;
      }
      
      // En Android, intentar acceder al directorio de Descargas público
      // Esto funciona en Android 9 y anteriores, o con permisos adecuados
      final downloadsDir = Directory('/storage/emulated/0/Download');
      
      if (await downloadsDir.exists()) {
        final filePath = '${downloadsDir.path}/$fileName';
        print('✅ Directorio de Descargas encontrado: ${downloadsDir.path}');
        return filePath;
      }
      
      // Intentar con la ruta alternativa
      final altDownloadsDir = Directory('/sdcard/Download');
      if (await altDownloadsDir.exists()) {
        final filePath = '${altDownloadsDir.path}/$fileName';
        print('✅ Directorio de Descargas alternativo encontrado: ${altDownloadsDir.path}');
        return filePath;
      }
      
      print('⚠️ No se pudo acceder al directorio de Descargas');
      return null;
    } catch (e) {
      print('⚠️ Error obteniendo ruta de Descargas: $e');
      return null;
    }
  }
  
  /// Genera el nombre del archivo PDF
  static String _generateFileName(Map<String, dynamic> reportData) {
    final now = DateTime.now();
    final reportId = reportData['id']?.toString() ?? 'reporte';
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'reporte_colonoscopia_${reportId}_$date.pdf';
  }
}

