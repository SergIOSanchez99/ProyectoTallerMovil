import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:convert';

// Helper para web (solo se importa cuando estamos en web)
// En móvil, usamos el stub; en web, usamos el helper real
import 'pdf_web_helper_stub.dart' if (dart.library.html) 'pdf_web_helper.dart' as web_helper;

// Handler para móvil (solo se importa cuando NO estamos en web)
// En web, usamos el stub; en móvil, usamos el handler real
import 'pdf_mobile_handler_stub.dart' if (dart.library.io) 'pdf_mobile_handler.dart' as mobile_handler;

class PDFService {
  static const String _appName = 'Taller Móvil - Colonoscopia';
  
  /// Genera un PDF del reporte de colonoscopia y lo descarga automáticamente
  static Future<bool> generateAndDownloadReport(Map<String, dynamic> reportData) async {
    try {
      print('📄 Iniciando generación de PDF...');
      
      // Validar que los datos del reporte no estén vacíos
      if (reportData.isEmpty) {
        print('❌ Error: Los datos del reporte están vacíos');
        throw Exception('Los datos del reporte están vacíos');
      }
      
      print('📄 Datos del reporte recibidos: ${reportData.keys.toList()}');
      
      // Crear el documento PDF
      final pdf = pw.Document();
      
      // Usar fuentes por defecto del paquete PDF (compatibles con Unicode)
      final font = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();
      
      // Agregar la página del reporte
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return _buildReportContent(reportData, font, fontBold);
          },
        ),
      );
      
      print('📄 Generando bytes del PDF...');
      // Generar los bytes del PDF
      final pdfBytes = await pdf.save();
      
      if (pdfBytes.isEmpty) {
        print('❌ Error: Los bytes del PDF están vacíos');
        throw Exception('Error al generar el PDF: bytes vacíos');
      }
      
      // Manejar descarga según la plataforma
      if (kIsWeb) {
        // Para web: descargar directamente en el navegador
        print('🌐 Plataforma web detectada - usando descarga del navegador');
        final fileName = _generateFileName(reportData);
        final cleanFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        return await web_helper.PDFWebHelper.downloadPDF(pdfBytes, cleanFileName);
      } else {
        // Para móvil: guardar archivo y usar share_plus
        // Este código solo se ejecuta cuando NO estamos en web
        return await mobile_handler.PDFMobileHandler.handleDownload(pdfBytes, reportData);
      }
    } catch (e, stackTrace) {
      print('❌ Error generando PDF: $e');
      print('❌ Tipo de error: ${e.runtimeType}');
      print('❌ Stack trace completo: $stackTrace');
      
      // Intentar obtener más información del error
      if (e is Exception) {
        print('❌ Mensaje de excepción: ${e.toString()}');
      }
      
      return false;
    }
  }
  
  /// Construye el contenido del reporte PDF
  static pw.Widget _buildReportContent(Map<String, dynamic> reportData, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Encabezado
        _buildHeader(font, fontBold),
        
        pw.SizedBox(height: 30),
        
        // Información del reporte
        _buildReportInfo(reportData, font, fontBold),
        
        pw.SizedBox(height: 20),
        
        // Detalles del análisis
        _buildAnalysisDetails(reportData, font, fontBold),
        
        pw.SizedBox(height: 30),
        
        // Pie de página
        _buildFooter(font),
      ],
    );
  }
  
  /// Obtiene un valor seguro del reporte
  static String _getSafeString(dynamic value, {String defaultValue = 'N/A'}) {
    if (value == null) return defaultValue;
    try {
      return value.toString();
    } catch (e) {
      return defaultValue;
    }
  }
  
  /// Construye el encabezado del PDF
  static pw.Widget _buildHeader(pw.Font font, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            _appName,
            style: pw.TextStyle(
              fontSize: 24,
              color: PdfColors.white,
              font: fontBold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Reporte de Análisis de Colonoscopia',
            style: pw.TextStyle(
              fontSize: 16,
              color: PdfColors.white,
              font: font,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Construye la información básica del reporte
  static pw.Widget _buildReportInfo(Map<String, dynamic> reportData, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Información del Reporte',
            style: pw.TextStyle(
              fontSize: 18,
              color: PdfColors.blue800,
              font: fontBold,
            ),
          ),
          pw.SizedBox(height: 15),
          _buildInfoRow('ID del Reporte:', _getSafeString(reportData['id']), font, fontBold),
          _buildInfoRow('Fecha:', _getSafeString(reportData['date']), font, fontBold),
          _buildInfoRow('Estado:', _getSafeString(reportData['status']), font, fontBold),
          _buildInfoRow('Título:', _getSafeString(reportData['title']), font, fontBold),
        ],
      ),
    );
  }
  
  /// Construye los detalles del análisis
  static pw.Widget _buildAnalysisDetails(Map<String, dynamic> reportData, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resultados del Análisis',
            style: pw.TextStyle(
              fontSize: 18,
              color: PdfColors.blue800,
              font: fontBold,
            ),
          ),
          pw.SizedBox(height: 15),
          _buildInfoRow('Resultado:', _getSafeString(reportData['result'] ?? reportData['Resultado']), font, fontBold),
          // Verificar ambos nombres posibles para stage
          if (reportData['stage'] != null || reportData['Stage'] != null)
            _buildInfoRow('Etapa:', _getSafeString(reportData['stage'] ?? reportData['Stage']), font, fontBold),
          // Verificar ambos nombres posibles para confidence
          if (reportData['confidence'] != null || reportData['Confidence'] != null)
            _buildInfoRow('Confianza:', '${(_getConfidenceValue(reportData['confidence'] ?? reportData['Confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%', font, fontBold),
          // Verificar ambos nombres posibles para riskLevel
          if (reportData['riskLevel'] != null || reportData['RiskLevel'] != null || reportData['risk_level'] != null)
            _buildInfoRow('Nivel de Riesgo:', _getSafeString(reportData['riskLevel'] ?? reportData['RiskLevel'] ?? reportData['risk_level']), font, fontBold),
        ],
      ),
    );
  }
  
  /// Construye una fila de información
  static pw.Widget _buildInfoRow(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                font: fontBold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                font: font,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Construye el pie de página
  static pw.Widget _buildFooter(pw.Font font) {
    final now = DateTime.now();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Este reporte fue generado automáticamente por el sistema de análisis de colonoscopia.',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              font: font,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Generado el: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} a las ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              font: font,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Genera el nombre del archivo PDF
  static String _generateFileName(Map<String, dynamic> reportData) {
    final now = DateTime.now();
    final reportId = reportData['id']?.toString() ?? 'reporte';
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'reporte_colonoscopia_${reportId}_$date.pdf';
  }

  /// Obtiene el valor de confianza de forma segura
  static double _getConfidenceValue(dynamic confidence) {
    if (confidence == null) return 0.0;
    if (confidence is double) return confidence;
    if (confidence is int) return confidence.toDouble();
    if (confidence is String) {
      return double.tryParse(confidence) ?? 0.0;
    }
    return 0.0;
  }

}
