import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PDFService {
  static const String _appName = 'Taller Móvil - Colonoscopia';
  
  /// Genera un PDF del reporte de colonoscopia y lo descarga automáticamente
  static Future<bool> generateAndDownloadReport(Map<String, dynamic> reportData) async {
    try {
      print('📄 Iniciando generación de PDF...');
      
      // Crear el documento PDF
      final pdf = pw.Document();
      
      // Usar fuentes por defecto del paquete PDF (compatibles con Unicode)
      final font = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();
      
      // Agregar la página del reporte
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildReportContent(reportData, font, fontBold);
          },
        ),
      );
      
      print('📄 Generando bytes del PDF...');
      // Generar los bytes del PDF
      final pdfBytes = await pdf.save();
      
      print('📁 Obteniendo directorio de documentos...');
      // Obtener el directorio de documentos
      final directory = await getApplicationDocumentsDirectory();
      
      // Crear el nombre del archivo
      final fileName = _generateFileName(reportData);
      final filePath = '${directory.path}/$fileName';
      
      print('💾 Guardando archivo en: $filePath');
      // Escribir el archivo
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      
      print('📤 Compartiendo archivo...');
      // Compartir/descargar el archivo
      await Share.shareXFiles([XFile(filePath)], text: 'Reporte de Colonoscopia');
      
      print('✅ PDF generado y compartido exitosamente');
      return true;
    } catch (e) {
      print('❌ Error generando PDF: $e');
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
          _buildInfoRow('ID del Reporte:', reportData['id']?.toString() ?? 'N/A', font, fontBold),
          _buildInfoRow('Fecha:', reportData['date']?.toString() ?? 'N/A', font, fontBold),
          _buildInfoRow('Estado:', reportData['status']?.toString() ?? 'N/A', font, fontBold),
          _buildInfoRow('Título:', reportData['title']?.toString() ?? 'N/A', font, fontBold),
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
          _buildInfoRow('Resultado:', reportData['result']?.toString() ?? 'N/A', font, fontBold),
          if (reportData['stage'] != null)
            _buildInfoRow('Etapa:', reportData['stage']?.toString() ?? 'N/A', font, fontBold),
          if (reportData['confidence'] != null)
            _buildInfoRow('Confianza:', '${(reportData['confidence'] * 100).toStringAsFixed(1)}%', font, fontBold),
          if (reportData['riskLevel'] != null)
            _buildInfoRow('Nivel de Riesgo:', reportData['riskLevel']?.toString() ?? 'N/A', font, fontBold),
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
}
