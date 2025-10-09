import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../utils/extensions.dart';

class ReportHistoryPage extends StatefulWidget {
  const ReportHistoryPage({super.key});

  @override
  State<ReportHistoryPage> createState() => _ReportHistoryPageState();
}

class _ReportHistoryPageState extends State<ReportHistoryPage> {
  final List<Map<String, dynamic>> _reports = [
    {
      'id': '1',
      'title': 'Reporte de Colon - 15/03/2024',
      'date': '2024-03-15',
      'status': 'Completado',
      'result': 'Normal',
    },
    {
      'id': '2',
      'title': 'Reporte de Colon - 10/03/2024',
      'date': '2024-03-10',
      'status': 'Completado',
      'result': 'Anomalía detectada',
    },
    {
      'id': '3',
      'title': 'Reporte de Colon - 05/03/2024',
      'date': '2024-03-05',
      'status': 'En proceso',
      'result': 'Procesando...',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightBlue,
      appBar: AppBar(
        title: const Text('Historial de Reportes'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${report['id']}'),
            Text('Fecha: ${report['date']}'),
            Text('Estado: ${report['status']}'),
            Text('Resultado: ${report['result']}'),
          ],
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
        ],
      ),
    );
  }
}









