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
    // Recargar reportes cada vez que se accede a la página
    _loadReports();
  }
  
  @override
  void didUpdateWidget(ReportHistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recargar reportes cuando el widget se actualiza
    _loadReports();
  }

  Future<void> _loadReports() async {
    print('🔄 Cargando reportes en la página de historial...');
    
    try {
      // Siempre recargar desde el almacenamiento para obtener los últimos reportes
      await ReportService.loadReports();
      
      // Obtener todos los reportes
      final loadedReports = ReportService.getAllReports();
      
      setState(() {
        _reports = loadedReports;
      });
      
      print('📊 Reportes cargados en UI: ${_reports.length}');
      for (int i = 0; i < _reports.length; i++) {
        print('📋 UI Reporte $i: ${_reports[i]['title']} - ${_reports[i]['result']}');
      }
    } catch (e) {
      print('⚠️ Error cargando reportes: $e');
      // Si hay error, al menos mostrar los reportes en memoria
      setState(() {
        _reports = ReportService.getAllReports();
      });
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
              if (report['confidence'] != null) _buildDetailRow('Confianza:', '${_formatConfidence(report['confidence'])}%'),
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
            onPressed: () async {
              Navigator.of(context).pop();
              await _downloadReportAsPDF(report);
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

  /// Formatea el valor de confianza de forma segura
  String _formatConfidence(dynamic confidence) {
    try {
      if (confidence == null) return '0.0';
      double confValue;
      if (confidence is double) {
        confValue = confidence;
      } else if (confidence is int) {
        confValue = confidence.toDouble();
      } else if (confidence is String) {
        confValue = double.tryParse(confidence) ?? 0.0;
      } else {
        confValue = 0.0;
      }
      return (confValue * 100).toStringAsFixed(1);
    } catch (e) {
      print('Error formateando confianza: $e');
      return '0.0';
    }
  }

  /// Descarga el reporte como PDF
  Future<void> _downloadReportAsPDF(Map<String, dynamic> report) async {
    try {
      print('🔄 Iniciando descarga de PDF para reporte: ${report['id']}');
      print('📋 Datos del reporte: ${report.keys.toList()}');
      
      // Validar que el reporte tenga los datos necesarios
      if (report.isEmpty) {
        print('❌ Error: El reporte está vacío');
        if (mounted) {
          context.showErrorSnackBar('Error: El reporte no tiene datos');
        }
        return;
      }
      
      // Mostrar indicador de carga
      if (mounted) {
        context.showInfoSnackBar('Generando PDF...');
      }
      
      // Generar y descargar el PDF
      print('📄 Llamando a PDFService.generateAndDownloadReport...');
      final success = await PDFService.generateAndDownloadReport(report);
      print('📄 Resultado de generateAndDownloadReport: $success');
      
      if (mounted) {
        if (success) {
          context.showSuccessSnackBar('PDF generado exitosamente. Se abrió el menú para guardar o compartir.');
        } else {
          // Mostrar mensaje de error más detallado
          final errorMsg = 'Error al generar el PDF. Por favor, revisa los logs de la consola para más detalles.';
          context.showErrorSnackBar(errorMsg);
          print('❌ La generación del PDF falló. Revisa los logs anteriores para más detalles.');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error en descarga de PDF: $e');
      print('❌ Tipo de error: ${e.runtimeType}');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        // Mostrar mensaje de error más descriptivo
        String errorMessage = 'Error al generar el PDF';
        String errorString = e.toString().toLowerCase();
        
        if (errorString.contains('permission') || errorString.contains('permiso')) {
          errorMessage = 'Error: Permisos insuficientes. Verifica los permisos de almacenamiento en la configuración de la app.';
        } else if (errorString.contains('path') || errorString.contains('ruta')) {
          errorMessage = 'Error: No se pudo acceder al directorio. Verifica los permisos de almacenamiento.';
        } else if (errorString.contains('file') || errorString.contains('archivo')) {
          errorMessage = 'Error: Problema al crear el archivo PDF. Revisa los logs para más detalles.';
        } else if (errorString.contains('share') || errorString.contains('compartir')) {
          errorMessage = 'Error: No se pudo compartir el archivo. El PDF se generó pero no se pudo abrir el menú de compartir.';
        } else {
          errorMessage = 'Error al generar el PDF: ${e.toString()}. Revisa los logs para más detalles.';
        }
        
        // Mostrar el mensaje de error
        context.showErrorSnackBar(errorMessage);
        
        // También imprimir información adicional
        print('📋 Información del error mostrada al usuario: $errorMessage');
      }
    }
  }
}











