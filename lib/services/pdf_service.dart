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
  static const String _appName = 'Detectives - Colonoscopia';
  
  /// Genera un PDF del reporte de colonoscopia y lo descarga automáticamente
  static Future<bool> generateAndDownloadReport(
    Map<String, dynamic> reportData, {
    String? reportType,
    String? patientName,
    String? patientId,
    String? patientAge,
    String? studyDate,
    String? doctorName,
    String? observations,
    Map<String, dynamic>? previousReport,
  }) async {
    try {
      print('📄 Iniciando generación de PDF...');
      print('📋 Tipo de reporte: ${reportType ?? 'estándar'}');
      
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
      
      // Construir contenido según el tipo de reporte
      pw.Widget reportContent;
      switch (reportType) {
        case 'básico':
          reportContent = _buildBasicReportContent(
            reportData,
            font,
            fontBold,
            patientName: patientName,
            patientId: patientId,
            patientAge: patientAge,
            studyDate: studyDate,
            doctorName: doctorName,
          );
          break;
        case 'detallado':
          reportContent = _buildDetailedReportContent(
            reportData,
            font,
            fontBold,
            patientName: patientName,
            patientId: patientId,
            patientAge: patientAge,
            studyDate: studyDate,
            doctorName: doctorName,
            observations: observations,
          );
          break;
        case 'comparativo':
          reportContent = _buildComparativeReportContent(
            reportData,
            font,
            fontBold,
            patientName: patientName,
            patientId: patientId,
            patientAge: patientAge,
            studyDate: studyDate,
            doctorName: doctorName,
            previousReport: previousReport,
            observations: observations,
          );
          break;
        default:
          reportContent = _buildReportContent(
            reportData,
            font,
            fontBold,
            patientName: patientName,
            patientId: patientId,
            patientAge: patientAge,
            studyDate: studyDate,
            doctorName: doctorName,
          );
      }
      
      // Agregar la página del reporte
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return reportContent;
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
  
  /// Construye el contenido del reporte PDF estándar
  static pw.Widget _buildReportContent(
    Map<String, dynamic> reportData,
    pw.Font font,
    pw.Font fontBold, {
    String? patientName,
    String? patientId,
    String? patientAge,
    String? studyDate,
    String? doctorName,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Encabezado
        _buildHeader(font, fontBold),
        
        pw.SizedBox(height: 30),
        
        // Información del paciente
        if (patientName != null || patientId != null || patientAge != null)
          _buildPatientInfo(
            patientName: patientName,
            patientId: patientId,
            patientAge: patientAge,
            font: font,
            fontBold: fontBold,
          ),
        
        if (patientName != null || patientId != null || patientAge != null) pw.SizedBox(height: 20),
        
        // Información del reporte
        _buildReportInfo(reportData, font, fontBold, studyDate: studyDate, doctorName: doctorName),
        
        pw.SizedBox(height: 20),
        
        // Detalles del análisis
        _buildAnalysisDetails(reportData, font, fontBold),
        
        pw.SizedBox(height: 30),
        
        // Pie de página
        _buildFooter(font),
      ],
    );
  }

  /// Construye contenido de reporte básico
  static pw.Widget _buildBasicReportContent(
    Map<String, dynamic> reportData,
    pw.Font font,
    pw.Font fontBold, {
    String? patientName,
    String? patientId,
    String? patientAge,
    String? studyDate,
    String? doctorName,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader(font, fontBold, reportType: 'Básico'),
        pw.SizedBox(height: 30),
        if (patientName != null || patientId != null || patientAge != null)
          _buildPatientInfo(
            patientName: patientName,
            patientId: patientId,
            patientAge: patientAge,
            font: font,
            fontBold: fontBold,
          ),
        if (patientName != null || patientId != null || patientAge != null) pw.SizedBox(height: 20),
        _buildReportInfo(reportData, font, fontBold, studyDate: studyDate, doctorName: doctorName),
        pw.SizedBox(height: 20),
        _buildBasicAnalysisDetails(reportData, font, fontBold),
        pw.SizedBox(height: 30),
        _buildFooter(font),
      ],
    );
  }

  /// Construye contenido de reporte detallado
  static pw.Widget _buildDetailedReportContent(
    Map<String, dynamic> reportData,
    pw.Font font,
    pw.Font fontBold, {
    String? patientName,
    String? patientId,
    String? patientAge,
    String? studyDate,
    String? doctorName,
    String? observations,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader(font, fontBold, reportType: 'Detallado'),
        pw.SizedBox(height: 30),
        if (patientName != null || patientId != null || patientAge != null)
          _buildPatientInfo(
            patientName: patientName,
            patientId: patientId,
            patientAge: patientAge,
            font: font,
            fontBold: fontBold,
          ),
        if (patientName != null || patientId != null || patientAge != null) pw.SizedBox(height: 20),
        _buildReportInfo(reportData, font, fontBold, studyDate: studyDate, doctorName: doctorName),
        pw.SizedBox(height: 20),
        _buildDetailedAnalysisDetails(reportData, font, fontBold),
        if (observations != null && observations.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          _buildObservationsSection(observations, font, fontBold),
        ],
        pw.SizedBox(height: 30),
        _buildFooter(font),
      ],
    );
  }

  /// Construye contenido de reporte comparativo
  static pw.Widget _buildComparativeReportContent(
    Map<String, dynamic> reportData,
    pw.Font font,
    pw.Font fontBold, {
    String? patientName,
    String? patientId,
    String? patientAge,
    String? studyDate,
    String? doctorName,
    Map<String, dynamic>? previousReport,
    String? observations,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader(font, fontBold, reportType: 'Comparativo'),
        pw.SizedBox(height: 30),
        if (patientName != null || patientId != null || patientAge != null)
          _buildPatientInfo(
            patientName: patientName,
            patientId: patientId,
            patientAge: patientAge,
            font: font,
            fontBold: fontBold,
          ),
        if (patientName != null || patientId != null || patientAge != null) pw.SizedBox(height: 20),
        _buildReportInfo(reportData, font, fontBold, studyDate: studyDate, doctorName: doctorName),
        pw.SizedBox(height: 20),
        if (previousReport != null)
          _buildComparativeAnalysisDetails(
            reportData,
            previousReport,
            font,
            fontBold,
          )
        else
          _buildAnalysisDetails(reportData, font, fontBold),
        if (observations != null && observations.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          _buildObservationsSection(observations, font, fontBold),
        ],
        pw.SizedBox(height: 30),
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
  static pw.Widget _buildHeader(pw.Font font, pw.Font fontBold, {String? reportType}) {
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
            reportType != null
                ? 'Reporte de Análisis de Colonoscopia - $reportType'
                : 'Reporte de Análisis de Colonoscopia',
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

  /// Construye la información del paciente
  static pw.Widget _buildPatientInfo({
    String? patientName,
    String? patientId,
    String? patientAge,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
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
            'Información del Paciente',
            style: pw.TextStyle(
              fontSize: 18,
              color: PdfColors.blue800,
              font: fontBold,
            ),
          ),
          pw.SizedBox(height: 15),
          if (patientName != null)
            _buildInfoRow('Nombre:', patientName, font, fontBold),
          if (patientId != null)
            _buildInfoRow('ID del Paciente:', patientId, font, fontBold),
          if (patientAge != null)
            _buildInfoRow('Edad:', '${patientAge} años', font, fontBold),
        ],
      ),
    );
  }
  
  /// Construye la información básica del reporte
  static pw.Widget _buildReportInfo(
    Map<String, dynamic> reportData,
    pw.Font font,
    pw.Font fontBold, {
    String? studyDate,
    String? doctorName,
  }) {
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
          _buildInfoRow('Fecha:', studyDate ?? _getSafeString(reportData['date']), font, fontBold),
          _buildInfoRow('Estado:', _getSafeString(reportData['status']), font, fontBold),
          if (doctorName != null)
            _buildInfoRow('Médico Responsable:', doctorName, font, fontBold),
          if (reportData['title'] != null)
            _buildInfoRow('Título:', _getSafeString(reportData['title']), font, fontBold),
        ],
      ),
    );
  }
  
  /// Construye los detalles del análisis (estándar)
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
          if (reportData['stage'] != null || reportData['Stage'] != null)
            _buildInfoRow('Etapa:', _getSafeString(reportData['stage'] ?? reportData['Stage']), font, fontBold),
          if (reportData['confidence'] != null || reportData['Confidence'] != null)
            _buildInfoRow('Confianza:', '${(_getConfidenceValue(reportData['confidence'] ?? reportData['Confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%', font, fontBold),
          if (reportData['riskLevel'] != null || reportData['RiskLevel'] != null || reportData['risk_level'] != null)
            _buildInfoRow('Nivel de Riesgo:', _getSafeString(reportData['riskLevel'] ?? reportData['RiskLevel'] ?? reportData['risk_level']), font, fontBold),
        ],
      ),
    );
  }

  /// Construye detalles básicos del análisis (solo información esencial)
  static pw.Widget _buildBasicAnalysisDetails(Map<String, dynamic> reportData, pw.Font font, pw.Font fontBold) {
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
          if (reportData['riskLevel'] != null || reportData['RiskLevel'] != null || reportData['risk_level'] != null)
            _buildInfoRow('Nivel de Riesgo:', _getSafeString(reportData['riskLevel'] ?? reportData['RiskLevel'] ?? reportData['risk_level']), font, fontBold),
        ],
      ),
    );
  }

  /// Construye detalles detallados del análisis (con toda la información)
  static pw.Widget _buildDetailedAnalysisDetails(Map<String, dynamic> reportData, pw.Font font, pw.Font fontBold) {
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
            'Resultados Detallados del Análisis',
            style: pw.TextStyle(
              fontSize: 18,
              color: PdfColors.blue800,
              font: fontBold,
            ),
          ),
          pw.SizedBox(height: 15),
          _buildInfoRow('Resultado:', _getSafeString(reportData['result'] ?? reportData['Resultado']), font, fontBold),
          if (reportData['stage'] != null || reportData['Stage'] != null)
            _buildInfoRow('Etapa:', _getSafeString(reportData['stage'] ?? reportData['Stage']), font, fontBold),
          if (reportData['confidence'] != null || reportData['Confidence'] != null)
            _buildInfoRow('Confianza:', '${(_getConfidenceValue(reportData['confidence'] ?? reportData['Confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%', font, fontBold),
          if (reportData['riskLevel'] != null || reportData['RiskLevel'] != null || reportData['risk_level'] != null)
            _buildInfoRow('Nivel de Riesgo:', _getSafeString(reportData['riskLevel'] ?? reportData['RiskLevel'] ?? reportData['risk_level']), font, fontBold),
          if (reportData['recommendation'] != null)
            _buildInfoRow('Recomendación:', _getSafeString(reportData['recommendation']), font, fontBold),
        ],
      ),
    );
  }

  /// Construye detalles comparativos del análisis
  static pw.Widget _buildComparativeAnalysisDetails(
    Map<String, dynamic> currentReport,
    Map<String, dynamic> previousReport,
    pw.Font font,
    pw.Font fontBold,
  ) {
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
            'Comparación de Análisis',
            style: pw.TextStyle(
              fontSize: 18,
              color: PdfColors.blue800,
              font: fontBold,
            ),
          ),
          pw.SizedBox(height: 20),
          // Reporte actual
          pw.Text(
            'Análisis Actual',
            style: pw.TextStyle(
              fontSize: 16,
              color: PdfColors.blue700,
              font: fontBold,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Fecha:', _getSafeString(currentReport['date']), font, fontBold),
          _buildInfoRow('Resultado:', _getSafeString(currentReport['result'] ?? currentReport['Resultado']), font, fontBold),
          if (currentReport['stage'] != null)
            _buildInfoRow('Etapa:', _getSafeString(currentReport['stage']), font, fontBold),
          if (currentReport['confidence'] != null)
            _buildInfoRow('Confianza:', '${(_getConfidenceValue(currentReport['confidence']) * 100).toStringAsFixed(1)}%', font, fontBold),
          if (currentReport['riskLevel'] != null)
            _buildInfoRow('Nivel de Riesgo:', _getSafeString(currentReport['riskLevel']), font, fontBold),
          pw.SizedBox(height: 20),
          // Reporte previo
          pw.Text(
            'Análisis Previo',
            style: pw.TextStyle(
              fontSize: 16,
              color: PdfColors.blue700,
              font: fontBold,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Fecha:', _getSafeString(previousReport['date']), font, fontBold),
          _buildInfoRow('Resultado:', _getSafeString(previousReport['result'] ?? previousReport['Resultado']), font, fontBold),
          if (previousReport['stage'] != null)
            _buildInfoRow('Etapa:', _getSafeString(previousReport['stage']), font, fontBold),
          if (previousReport['confidence'] != null)
            _buildInfoRow('Confianza:', '${(_getConfidenceValue(previousReport['confidence']) * 100).toStringAsFixed(1)}%', font, fontBold),
          if (previousReport['riskLevel'] != null)
            _buildInfoRow('Nivel de Riesgo:', _getSafeString(previousReport['riskLevel']), font, fontBold),
        ],
      ),
    );
  }

  /// Construye sección de observaciones
  static pw.Widget _buildObservationsSection(String observations, pw.Font font, pw.Font fontBold) {
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
            'Observaciones',
            style: pw.TextStyle(
              fontSize: 18,
              color: PdfColors.blue800,
              font: fontBold,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            observations,
            style: pw.TextStyle(
              fontSize: 12,
              font: font,
            ),
          ),
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
