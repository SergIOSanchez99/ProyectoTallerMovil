import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../utils/extensions.dart';
import '../services/report_service.dart';
import '../services/pdf_service.dart';

class ReportHistoryPage extends StatefulWidget {
  const ReportHistoryPage({super.key});

  @override
  State<ReportHistoryPage> createState() => _ReportHistoryPageState();
}

class _ReportHistoryPageState extends State<ReportHistoryPage> {
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (_reports.isEmpty) {
      try {
        await ReportService.loadReports();
      } catch (e) {
        print('⚠️ Error cargando desde archivo: $e');
      }
    }
    setState(() {
      _reports = ReportService.getAllReports();
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
        return AppColors.success;
      case 'en proceso':
        return AppColors.warning;
      case 'error':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
        return Icons.check_circle;
      case 'en proceso':
        return Icons.hourglass_empty;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getRiskColor(String? riskLevel) {
    switch ((riskLevel ?? '').toLowerCase()) {
      case 'alto':
        return Colors.red;
      case 'medio-alto':
        return Colors.deepOrange;
      case 'medio':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Uint8List? _decodeImage(Map<String, dynamic> report) {
    try {
      final base64Str = report['imageBase64'] as String?;
      if (base64Str != null && base64Str.isNotEmpty) {
        return base64Decode(base64Str);
      }
    } catch (_) {}
    return null;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightBlue,
      appBar: AppBar(
        title: const Text('Historial de Reportes'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: _reports.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                itemCount: _reports.length,
                itemBuilder: (context, index) =>
                    _buildReportCard(_reports[index]),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No hay reportes disponibles',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Sube una imagen y genera tu primer reporte',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final imageBytes = _decodeImage(report);
    final riskColor = _getRiskColor(report['riskLevel'] as String?);
    final statusColor = _getStatusColor(report['status'] as String? ?? '');

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showReportDetails(report),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Miniatura de imagen o ícono de estado
              _buildThumbnail(imageBytes, statusColor,
                  report['status'] as String? ?? ''),
              const SizedBox(width: 12),
              // Información del reporte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['title'] as String? ?? 'Sin título',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fecha: ${report['date'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Resultado con color de riesgo
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report['result'] as String? ?? 'N/A',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              color: riskColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (report['riskLevel'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: riskColor, width: 0.8),
                            ),
                            child: Text(
                              report['riskLevel'] as String,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: riskColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    if (report['confidence'] != null) ...[
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (report['confidence'] as num).toDouble(),
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(riskColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(
      Uint8List? imageBytes, Color statusColor, String status) {
    if (imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          imageBytes,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: statusColor,
      radius: 28,
      child: Icon(_getStatusIcon(status), color: AppColors.white),
    );
  }

  // ─── Detalle del reporte ──────────────────────────────────────────────────

  void _showReportDetails(Map<String, dynamic> report) {
    final imageBytes = _decodeImage(report);
    final riskColor = _getRiskColor(report['riskLevel'] as String?);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report['title'] as String? ?? 'Reporte'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen completa si existe
              if (imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    imageBytes,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildDetailRow('ID:', report['id']?.toString() ?? 'N/A'),
              _buildDetailRow('Fecha:', report['date']?.toString() ?? 'N/A'),
              _buildDetailRow('Estado:', report['status']?.toString() ?? 'N/A'),
              _buildDetailRow(
                  'Resultado:', report['result']?.toString() ?? 'N/A',
                  valueColor: riskColor),
              if (report['stage'] != null)
                _buildDetailRow('Etapa:', report['stage'].toString()),
              if (report['confidence'] != null)
                _buildDetailRow('Confianza:',
                    '${((report['confidence'] as num) * 100).toStringAsFixed(1)}%'),
              if (report['riskLevel'] != null)
                _buildDetailRow('Riesgo:', report['riskLevel'].toString(),
                    valueColor: riskColor),
              if (report['patientName'] != null)
                _buildDetailRow('Paciente:', report['patientName'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _downloadReportAsPDF(report);
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Descargar PDF'),
          ),
          IconButton(
            onPressed: () async {
              await ReportService.deleteReport(
                  report['id']?.toString() ?? '');
              if (context.mounted) {
                Navigator.of(context).pop();
                _loadReports();
                context.showInfoSnackBar('Reporte eliminado');
              }
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Eliminar reporte',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: valueColor,
                  fontWeight: valueColor != null
                      ? FontWeight.w600
                      : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadReportAsPDF(Map<String, dynamic> report) async {
    try {
      context.showInfoSnackBar('Generando PDF...');
      final success = await PDFService.generateAndDownloadReport(report);
      if (success) {
        context.showInfoSnackBar('PDF descargado exitosamente');
      } else {
        context.showErrorSnackBar('Error al generar el PDF');
      }
    } catch (e) {
      context.showErrorSnackBar('Error: $e');
    }
  }
}
