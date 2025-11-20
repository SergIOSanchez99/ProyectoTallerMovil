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
      print('📊 Contenido del reporte:');
      print('   - result: ${reportData['result']}');
      print('   - stage: ${reportData['stage']}');
      print('   - confidence: ${reportData['confidence']}');
      print('   - riskLevel: ${reportData['riskLevel'] ?? reportData['risk_level']}');
      
      // Normalizar datos antes de generar el PDF para asegurar compatibilidad
      if (reportData['risk_level'] != null && reportData['riskLevel'] == null) {
        reportData['riskLevel'] = reportData['risk_level'];
      }
      
      // Asegurar que los campos críticos estén presentes
      reportData['result'] = reportData['result'] ?? reportData['Resultado'] ?? reportData['diagnosis'] ?? 'No disponible';
      reportData['stage'] = reportData['stage'] ?? reportData['Stage'] ?? reportData['currentStage'] ?? 'N/A';
      reportData['confidence'] = reportData['confidence'] ?? reportData['Confidence'] ?? 0.0;
      reportData['riskLevel'] = reportData['riskLevel'] ?? reportData['RiskLevel'] ?? reportData['risk_level'] ?? 'N/A';
      
      print('📊 Datos normalizados para PDF:');
      print('   - result: ${reportData['result']}');
      print('   - stage: ${reportData['stage']}');
      print('   - confidence: ${reportData['confidence']}');
      print('   - riskLevel: ${reportData['riskLevel']}');
      
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
          // Para comparativo, necesitamos generar el análisis comparativo
          if (previousReport != null) {
            // Generar análisis comparativo usando el servicio médico
            try {
              // Importar dinámicamente el servicio (por ahora lo haremos inline en el método)
              final comparativeAnalysis = _generateComparativeAnalysis(reportData, previousReport);
              reportData['comparativeAnalysis'] = comparativeAnalysis;
            } catch (e) {
              print('Error generando análisis comparativo: $e');
            }
          }
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
            _buildInfoRow('DNI:', patientId, font, fontBold),
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
          _buildInfoRow('ID del Reporte:', _getSafeString(reportData['id'] ?? reportData['backendId']), font, fontBold),
          _buildInfoRow('Fecha del Estudio:', studyDate ?? _getSafeString(reportData['date'] ?? reportData['study_date']), font, fontBold),
          _buildInfoRow('Estado:', _getSafeString(reportData['status']), font, fontBold),
          if (doctorName != null && doctorName.isNotEmpty)
            _buildInfoRow('Médico Responsable:', doctorName, font, fontBold),
          if (reportData['doctor_name'] != null && doctorName == null)
            _buildInfoRow('Médico Responsable:', _getSafeString(reportData['doctor_name']), font, fontBold),
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
              // Siempre mostrar el resultado (es el campo más importante)
              _buildInfoRow('Resultado:', _getSafeString(
                reportData['result'] ?? 
                reportData['Resultado'] ?? 
                reportData['diagnosis'] ?? 
                'No disponible'
              ), font, fontBold),
              // Siempre mostrar etapa (puede ser 'N/A' si no está disponible)
              _buildInfoRow('Etapa:', _getSafeString(
                reportData['stage'] ?? 
                reportData['Stage'] ?? 
                reportData['currentStage'] ??
                'N/A'
              ), font, fontBold),
              // Siempre mostrar confianza (mostrar 0% si no está disponible)
              _buildInfoRow('Confianza del Análisis:', '${(_getConfidenceValue(reportData['confidence'] ?? reportData['Confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%', font, fontBold),
              // Siempre mostrar nivel de riesgo (mostrar 'N/A' si no está disponible)
              _buildInfoRow('Nivel de Riesgo:', _getSafeString(
                reportData['riskLevel'] ?? 
                reportData['RiskLevel'] ?? 
                reportData['risk_level'] ??
                'N/A'
              ), font, fontBold),
        ],
      ),
    );
  }

  /// Construye detalles básicos del análisis (solo información esencial)
  static pw.Widget _buildBasicAnalysisDetails(Map<String, dynamic> reportData, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
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
              // Siempre mostrar el resultado (es el campo más importante)
              _buildInfoRow('Resultado:', _getSafeString(
                reportData['result'] ?? 
                reportData['Resultado'] ?? 
                reportData['diagnosis'] ?? 
                'No disponible'
              ), font, fontBold),
              // Siempre mostrar etapa (puede ser 'N/A' si no está disponible)
              _buildInfoRow('Etapa:', _getSafeString(
                reportData['stage'] ?? 
                reportData['Stage'] ?? 
                reportData['currentStage'] ??
                'N/A'
              ), font, fontBold),
              // Siempre mostrar confianza (mostrar 0% si no está disponible)
              _buildInfoRow('Confianza del Análisis:', '${(_getConfidenceValue(reportData['confidence'] ?? reportData['Confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%', font, fontBold),
              // Siempre mostrar nivel de riesgo (mostrar 'N/A' si no está disponible)
              _buildInfoRow('Nivel de Riesgo:', _getSafeString(
                reportData['riskLevel'] ?? 
                reportData['RiskLevel'] ?? 
                reportData['risk_level'] ??
                'N/A'
              ), font, fontBold),
            ],
          ),
        ),
        // Recomendaciones básicas si están disponibles
        if (reportData['recommendation'] != null) ...[
          pw.SizedBox(height: 15),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.orange300),
              borderRadius: pw.BorderRadius.circular(10),
              color: PdfColors.orange50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Recomendaciones',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.orange900,
                    font: fontBold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  _getSafeString(reportData['recommendation']),
                  style: pw.TextStyle(
                    fontSize: 11,
                    font: font,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Construye detalles detallados del análisis (con toda la información)
  static pw.Widget _buildDetailedAnalysisDetails(Map<String, dynamic> reportData, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Resultados del análisis
        pw.Container(
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
              // Siempre mostrar el resultado (es el campo más importante)
              _buildInfoRow('Resultado:', _getSafeString(
                reportData['result'] ?? 
                reportData['Resultado'] ?? 
                reportData['diagnosis'] ?? 
                'No disponible'
              ), font, fontBold),
              // Siempre mostrar etapa (puede ser 'N/A' si no está disponible)
              _buildInfoRow('Etapa:', _getSafeString(
                reportData['stage'] ?? 
                reportData['Stage'] ?? 
                reportData['currentStage'] ??
                'N/A'
              ), font, fontBold),
              // Siempre mostrar confianza (mostrar 0% si no está disponible)
              _buildInfoRow('Confianza del Análisis:', '${(_getConfidenceValue(reportData['confidence'] ?? reportData['Confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%', font, fontBold),
              // Siempre mostrar nivel de riesgo (mostrar 'N/A' si no está disponible)
              _buildInfoRow('Nivel de Riesgo:', _getSafeString(
                reportData['riskLevel'] ?? 
                reportData['RiskLevel'] ?? 
                reportData['risk_level'] ??
                'N/A'
              ), font, fontBold),
            ],
          ),
        ),
        pw.SizedBox(height: 15),
        // Interpretación clínica
        if (reportData['clinicalInterpretation'] != null)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue300),
              borderRadius: pw.BorderRadius.circular(10),
              color: PdfColors.blue50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Interpretación Clínica',
                  style: pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.blue800,
                    font: fontBold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  _getSafeString(reportData['clinicalInterpretation']),
                  style: pw.TextStyle(
                    fontSize: 11,
                    font: font,
                  ),
                ),
              ],
            ),
          ),
        pw.SizedBox(height: 15),
        // Recomendaciones
        if (reportData['recommendation'] != null)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.orange300),
              borderRadius: pw.BorderRadius.circular(10),
              color: PdfColors.orange50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Recomendaciones Médicas',
                  style: pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.orange900,
                    font: fontBold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  _getSafeString(reportData['recommendation']),
                  style: pw.TextStyle(
                    fontSize: 11,
                    font: font,
                  ),
                ),
              ],
            ),
          ),
        pw.SizedBox(height: 15),
        // Plan de seguimiento
        if (reportData['followUpPlan'] != null)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green300),
              borderRadius: pw.BorderRadius.circular(10),
              color: PdfColors.green50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Plan de Seguimiento',
                  style: pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.green900,
                    font: fontBold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  _getSafeString(reportData['followUpPlan']),
                  style: pw.TextStyle(
                    fontSize: 11,
                    font: font,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Construye detalles comparativos del análisis
  static pw.Widget _buildComparativeAnalysisDetails(
    Map<String, dynamic> currentReport,
    Map<String, dynamic> previousReport,
    pw.Font font,
    pw.Font fontBold,
  ) {
    // Generar análisis comparativo usando el servicio médico
    String? comparativeAnalysis;
    try {
      // Importar el servicio de recomendaciones médicas
      // Nota: Esto requiere importar el servicio, pero por ahora lo haremos inline
      comparativeAnalysis = _generateComparativeAnalysis(currentReport, previousReport);
    } catch (e) {
      comparativeAnalysis = null;
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Tabla comparativa lado a lado
        pw.Container(
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
              // Tabla comparativa
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Análisis Actual
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.blue300),
                        borderRadius: pw.BorderRadius.circular(8),
                        color: PdfColors.blue50,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Análisis Actual',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.blue800,
                              font: fontBold,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          _buildInfoRow('Fecha:', _getSafeString(currentReport['date']), font, fontBold),
                          _buildInfoRow('Resultado:', _getSafeString(currentReport['result'] ?? currentReport['Resultado']), font, fontBold),
                          if (currentReport['stage'] != null || currentReport['Stage'] != null)
                            _buildInfoRow('Etapa:', _getSafeString(currentReport['stage'] ?? currentReport['Stage']), font, fontBold),
                          if (currentReport['confidence'] != null)
                            _buildInfoRow('Confianza:', '${(_getConfidenceValue(currentReport['confidence']) * 100).toStringAsFixed(1)}%', font, fontBold),
                          if (currentReport['riskLevel'] != null || currentReport['risk_level'] != null)
                            _buildInfoRow('Riesgo:', _getSafeString(currentReport['riskLevel'] ?? currentReport['risk_level']), font, fontBold),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // Análisis Previo
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: pw.BorderRadius.circular(8),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Análisis Previo',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.grey800,
                              font: fontBold,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          _buildInfoRow('Fecha:', _getSafeString(previousReport['date']), font, fontBold),
                          _buildInfoRow('Resultado:', _getSafeString(previousReport['result'] ?? previousReport['Resultado']), font, fontBold),
                          if (previousReport['stage'] != null || previousReport['Stage'] != null)
                            _buildInfoRow('Etapa:', _getSafeString(previousReport['stage'] ?? previousReport['Stage']), font, fontBold),
                          if (previousReport['confidence'] != null)
                            _buildInfoRow('Confianza:', '${(_getConfidenceValue(previousReport['confidence']) * 100).toStringAsFixed(1)}%', font, fontBold),
                          if (previousReport['riskLevel'] != null || previousReport['risk_level'] != null)
                            _buildInfoRow('Riesgo:', _getSafeString(previousReport['riskLevel'] ?? previousReport['risk_level']), font, fontBold),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Análisis comparativo detallado
        if (comparativeAnalysis != null && comparativeAnalysis.isNotEmpty) ...[
          pw.SizedBox(height: 15),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.purple300),
              borderRadius: pw.BorderRadius.circular(10),
              color: PdfColors.purple50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Análisis de Evolución',
                  style: pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.purple900,
                    font: fontBold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  comparativeAnalysis,
                  style: pw.TextStyle(
                    fontSize: 11,
                    font: font,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  /// Genera análisis comparativo (versión simplificada inline)
  static String _generateComparativeAnalysis(
    Map<String, dynamic> currentReport,
    Map<String, dynamic> previousReport,
  ) {
    final currentResult = (currentReport['result'] ?? '').toString().toLowerCase();
    final previousResult = (previousReport['result'] ?? '').toString().toLowerCase();
    final currentRisk = (currentReport['riskLevel'] ?? currentReport['risk_level'] ?? '').toString().toLowerCase();
    final previousRisk = (previousReport['riskLevel'] ?? previousReport['risk_level'] ?? '').toString().toLowerCase();
    
    String analysis = '';
    
    // Comparación de resultados
    if (currentResult == previousResult) {
      analysis += 'El resultado se mantiene estable: ${currentReport['result']}\n';
    } else {
      analysis += 'Cambio detectado en el resultado:\n';
      analysis += '• Previo: ${previousReport['result']}\n';
      analysis += '• Actual: ${currentReport['result']}\n';
      
      if (_isWorse(currentResult, previousResult)) {
        analysis += '⚠️ EVIDENCIA DE PROGRESIÓN. Se requiere evaluación médica inmediata.\n';
      } else if (_isBetter(currentResult, previousResult)) {
        analysis += '✅ EVIDENCIA DE MEJORÍA. Continuar con seguimiento.\n';
      }
    }
    
    // Comparación de riesgo
    if (currentRisk != previousRisk) {
      analysis += '\nCambio en el nivel de riesgo:\n';
      analysis += '• Previo: ${previousReport['riskLevel'] ?? previousReport['risk_level']}\n';
      analysis += '• Actual: ${currentReport['riskLevel'] ?? currentReport['risk_level']}\n';
      
      if (_isRiskHigher(currentRisk, previousRisk)) {
        analysis += '⚠️ AUMENTO DEL RIESGO DETECTADO.\n';
      } else {
        analysis += '✅ REDUCCIÓN DEL RIESGO.\n';
      }
    }
    
    return analysis;
  }
  
  static bool _isWorse(String current, String previous) {
    final worseKeywords = ['cáncer', 'tumor', 'maligno'];
    final betterKeywords = ['normal', 'benigno'];
    return worseKeywords.any((k) => current.contains(k)) && 
           betterKeywords.any((k) => previous.contains(k));
  }
  
  static bool _isBetter(String current, String previous) {
    final betterKeywords = ['normal', 'benigno'];
    final worseKeywords = ['cáncer', 'tumor', 'maligno'];
    return betterKeywords.any((k) => current.contains(k)) && 
           worseKeywords.any((k) => previous.contains(k));
  }
  
  static bool _isRiskHigher(String current, String previous) {
    final riskOrder = {'bajo': 1, 'medio': 2, 'alto': 3};
    final currentLevel = riskOrder[current] ?? 2;
    final previousLevel = riskOrder[previous] ?? 2;
    return currentLevel > previousLevel;
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
