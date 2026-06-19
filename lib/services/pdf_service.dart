import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Importación condicional: web usa dart:html, nativo usa path_provider + share_plus
import 'pdf_service_web.dart' if (dart.library.io) 'pdf_service_native.dart';

class PDFService {
  static const String _appName = 'ColonSense';

  /// Genera un PDF del reporte de colonoscopia y lo descarga automáticamente
  static Future<bool> generateAndDownloadReport(
      Map<String, dynamic> reportData) async {
    try {
      print('📄 Iniciando generación de PDF...');

      final pdf = pw.Document();
      final font = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();

      // Decodificar imagen si existe
      pw.MemoryImage? reportImage;
      if (reportData['imageBase64'] != null &&
          (reportData['imageBase64'] as String).isNotEmpty) {
        try {
          final bytes = base64Decode(reportData['imageBase64'] as String);
          reportImage = pw.MemoryImage(bytes);
        } catch (e) {
          print('⚠️ No se pudo decodificar la imagen: $e');
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return _buildReportContent(reportData, font, fontBold, reportImage);
          },
        ),
      );

      print('📄 Generando bytes del PDF...');
      final pdfBytes = await pdf.save();
      final fileName = _generateFileName(reportData);

      print('💾 Guardando / descargando PDF...');
      await savePdf(pdfBytes, fileName);

      print('✅ PDF generado exitosamente');
      return true;
    } catch (e) {
      print('❌ Error generando PDF: $e');
      return false;
    }
  }

  static pw.Widget _buildReportContent(
    Map<String, dynamic> reportData,
    pw.Font font,
    pw.Font fontBold,
    pw.MemoryImage? image,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader(font, fontBold),
        pw.SizedBox(height: 20),
        _buildReportInfo(reportData, font, fontBold),
        pw.SizedBox(height: 16),
        _buildAnalysisDetails(reportData, font, fontBold),
        if (image != null) ...[
          pw.SizedBox(height: 16),
          _buildImageSection(image, font, fontBold),
        ],
        pw.SizedBox(height: 16),
        _buildFooter(font),
      ],
    );
  }

  static pw.Widget _buildHeader(pw.Font font, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _appName,
                style: pw.TextStyle(
                    fontSize: 22, color: PdfColors.white, font: fontBold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Reporte de Análisis de Colonoscopia',
                style: pw.TextStyle(
                    fontSize: 13, color: PdfColors.blue100, font: font),
              ),
            ],
          ),
          pw.Text(
            '🔬',
            style: pw.TextStyle(fontSize: 28, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildReportInfo(
      Map<String, dynamic> reportData, pw.Font font, pw.Font fontBold) {
    final patientName = reportData['patientName']?.toString();
    final patientId = reportData['patientId']?.toString();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.blue50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Información del Reporte',
            style: pw.TextStyle(
                fontSize: 15, color: PdfColors.blue800, font: fontBold),
          ),
          pw.Divider(color: PdfColors.blue200),
          pw.SizedBox(height: 6),
          _buildInfoRow('ID del Reporte:',
              reportData['id']?.toString() ?? 'N/A', font, fontBold),
          _buildInfoRow(
              'Fecha:', reportData['date']?.toString() ?? 'N/A', font, fontBold),
          _buildInfoRow('Estado:',
              reportData['status']?.toString() ?? 'N/A', font, fontBold),
          _buildInfoRow('Título:',
              reportData['title']?.toString() ?? 'N/A', font, fontBold),
          if (patientName != null)
            _buildInfoRow('Paciente:', patientName, font, fontBold),
          if (patientId != null)
            _buildInfoRow('ID Paciente:', patientId, font, fontBold),
        ],
      ),
    );
  }

  static pw.Widget _buildAnalysisDetails(
      Map<String, dynamic> reportData, pw.Font font, pw.Font fontBold) {
    final confidence = reportData['confidence'];
    final confidenceText = confidence != null
        ? '${(confidence * 100).toStringAsFixed(1)}%'
        : 'N/A';
    final riskLevel = reportData['riskLevel']?.toString() ?? '';
    final riskColor = _getRiskColor(riskLevel);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resultados del Análisis',
            style: pw.TextStyle(
                fontSize: 15, color: PdfColors.blue800, font: fontBold),
          ),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 6),
          _buildInfoRow('Resultado:',
              reportData['result']?.toString() ?? 'N/A', font, fontBold),
          if (reportData['stage'] != null)
            _buildInfoRow('Etapa:',
                reportData['stage']?.toString() ?? 'N/A', font, fontBold),
          _buildInfoRow('Confianza:', confidenceText, font, fontBold),
          if (riskLevel.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 120,
                    child: pw.Text('Nivel de Riesgo:',
                        style: pw.TextStyle(fontSize: 12, font: fontBold)),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: riskColor,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(riskLevel,
                        style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.white,
                            font: fontBold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildImageSection(
      pw.MemoryImage image, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Imagen Analizada',
            style: pw.TextStyle(
                fontSize: 15, color: PdfColors.blue800, font: fontBold),
          ),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.ClipRRect(
              verticalRadius: 8,
              horizontalRadius: 8,
              child: pw.Image(image, height: 200, fit: pw.BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(
      String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label,
                style: pw.TextStyle(fontSize: 12, font: fontBold)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(fontSize: 12, font: font)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font font) {
    final now = DateTime.now();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Este reporte fue generado automáticamente por $_appName. No reemplaza el diagnóstico médico profesional.',
            style: pw.TextStyle(
                fontSize: 9, color: PdfColors.grey600, font: font),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generado el: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} a las ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            style: pw.TextStyle(
                fontSize: 9, color: PdfColors.grey600, font: font),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static PdfColor _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'alto':
        return PdfColors.red700;
      case 'medio-alto':
        return PdfColors.deepOrange700;
      case 'medio':
        return PdfColors.orange700;
      default:
        return PdfColors.green700;
    }
  }

  static String _generateFileName(Map<String, dynamic> reportData) {
    final now = DateTime.now();
    final reportId = reportData['id']?.toString() ?? 'reporte';
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'ColonSense_${reportId}_$date.pdf';
  }
}
