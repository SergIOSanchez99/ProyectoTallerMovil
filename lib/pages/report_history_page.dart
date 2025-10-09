import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../utils/extensions.dart';
import '../services/report_service.dart';

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
    // Recargar reportes cada vez que se accede a la página
    _loadReports();
  }

  Future<void> _loadReports() async {
    print('🔄 Cargando reportes en la página de historial...');
    
    // Solo cargar desde archivo la primera vez
    if (_reports.isEmpty) {
      try {
        await ReportService.loadReports();
      } catch (e) {
        print('⚠️ Error cargando desde archivo: $e');
      }
    }
    
    // Obtener todos los reportes (incluyendo los de ejemplo si no hay ninguno)
    setState(() {
      _reports = ReportService.getAllReports();
    });
    
    print('📊 Reportes cargados en UI: ${_reports.length}');
    for (int i = 0; i < _reports.length; i++) {
      print('📋 UI Reporte $i: ${_reports[i]['title']} - ${_reports[i]['result']}');
    }
  }

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
            tooltip: 'Actualizar reportes',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: _reports.isEmpty
              ? const Center(
                  child: Text(
                    'No hay reportes disponibles',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return CustomCard(
                      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(report['status']),
                          child: Icon(
                            _getStatusIcon(report['status']),
                            color: AppColors.white,
                          ),
                        ),
                        title: Text(
                          report['title'],
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeL,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha: ${report['date']}',
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeM,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Estado: ${report['status']}',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeM,
                                color: _getStatusColor(report['status']),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Resultado: ${report['result']}',
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeM,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _showReportDetails(report);
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

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

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report['title']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID:', report['id']),
              _buildDetailRow('Fecha:', report['date']),
              _buildDetailRow('Estado:', report['status']),
              _buildDetailRow('Resultado:', report['result']),
              if (report['stage'] != null) _buildDetailRow('Etapa:', report['stage']),
              if (report['confidence'] != null) _buildDetailRow('Confianza:', '${(report['confidence'] * 100).toStringAsFixed(1)}%'),
              if (report['riskLevel'] != null) _buildDetailRow('Nivel de Riesgo:', report['riskLevel']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.showInfoSnackBar('Descargando reporte...');
            },
            child: const Text('Descargar'),
          ),
          IconButton(
            onPressed: () async {
              await ReportService.deleteReport(report['id']);
              Navigator.of(context).pop();
              _loadReports(); // Recargar la lista
              context.showInfoSnackBar('Reporte eliminado');
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Eliminar reporte',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}











