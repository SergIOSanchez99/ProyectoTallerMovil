import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../utils/extensions.dart';
import '../services/report_service.dart';
import '../services/pdf_service.dart';
import '../services/patient_service.dart';

class ReportHistoryPage extends StatefulWidget {
  const ReportHistoryPage({super.key});

  @override
  State<ReportHistoryPage> createState() => _ReportHistoryPageState();
}

class _ReportHistoryPageState extends State<ReportHistoryPage> {
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _patientReports = []; // Reportes asociados a pacientes
  List<Map<String, dynamic>> _imageAnalyses = []; // Imágenes analizadas sin paciente
  Map<int, String> _patientNamesCache = {}; // Cache de nombres de pacientes por ID
  Map<int, String> _patientDniCache = {}; // Cache de DNI de pacientes por ID
  final PatientService _patientService = PatientService();

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
      
      // Separar reportes: con paciente vs sin paciente
      final patientReportsList = <Map<String, dynamic>>[];
      final imageAnalysesList = <Map<String, dynamic>>[];
      final patientIds = <int>{};
      
      for (var report in loadedReports) {
        // Si tiene patientId y no es null, es un reporte de paciente
        if (report['patientId'] != null) {
          patientReportsList.add(report);
          final patientId = report['patientId'];
          if (patientId is int) {
            patientIds.add(patientId);
          } else if (patientId is String) {
            final id = int.tryParse(patientId);
            if (id != null) patientIds.add(id);
          }
        } else {
          // Si no tiene patientId, es una imagen analizada sin paciente
          imageAnalysesList.add(report);
        }
      }
      
      // Cargar nombres y DNI de pacientes
      final patientNamesCache = <int, String>{};
      final patientDniCache = <int, String>{};
      for (var patientId in patientIds) {
        try {
          final response = await _patientService.getPatientById(patientId);
          if (response.success && response.data != null) {
            final patientName = response.data!['fullName'] ?? 
                               response.data!['nombre_completo'] ?? 
                               response.data!['full_name'] ?? 
                               'Paciente #$patientId';
            final patientDni = response.data!['identification'] ?? 
                              response.data!['identificacion'] ?? 
                              '';
            patientNamesCache[patientId] = patientName;
            if (patientDni.isNotEmpty) {
              patientDniCache[patientId] = patientDni;
            }
          }
        } catch (e) {
          print('⚠️ Error obteniendo datos del paciente $patientId: $e');
        }
      }
      
      setState(() {
        _reports = loadedReports;
        _patientReports = patientReportsList;
        _imageAnalyses = imageAnalysesList;
        _patientNamesCache = patientNamesCache;
        _patientDniCache = patientDniCache;
      });
      
      print('📊 Reportes cargados en UI: ${_reports.length}');
      print('👤 Reportes con paciente: ${_patientReports.length}');
      print('🖼️ Imágenes analizadas sin paciente: ${_imageAnalyses.length}');
    } catch (e) {
      print('⚠️ Error cargando reportes: $e');
      // Si hay error, al menos mostrar los reportes en memoria
      final allReports = ReportService.getAllReports();
      final patientReportsList = <Map<String, dynamic>>[];
      final imageAnalysesList = <Map<String, dynamic>>[];
      
      for (var report in allReports) {
        if (report['patientId'] != null) {
          patientReportsList.add(report);
        } else {
          imageAnalysesList.add(report);
        }
      }
      
      setState(() {
        _reports = allReports;
        _patientReports = patientReportsList;
        _imageAnalyses = imageAnalysesList;
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
        child: _reports.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Text(
                    'No hay reportes disponibles',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección: Resultados de Pacientes
                    if (_patientReports.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: 'Resultados de Pacientes',
                        icon: Icons.person,
                        count: _patientReports.length,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      ..._patientReports.map((report) => _buildReportCard(report, isPatientReport: true)),
                      const SizedBox(height: AppDimensions.spacingXL),
                    ],
                    
                    // Sección: Imágenes Cargadas
                    if (_imageAnalyses.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: 'Imágenes Cargadas',
                        icon: Icons.image,
                        count: _imageAnalyses.length,
                        color: AppColors.info,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      ..._imageAnalyses.map((report) => _buildReportCard(report, isPatientReport: false)),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  /// Construye el encabezado de una sección
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppDimensions.spacingM),
          Text(
            title,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeXL,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingXS,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: AppDimensions.fontSizeM,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una tarjeta de reporte
  Widget _buildReportCard(Map<String, dynamic> report, {required bool isPatientReport}) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getStatusColor(report['status']),
              child: Icon(
                _getStatusIcon(report['status']),
                color: AppColors.white,
              ),
            ),
            if (isPatientReport)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 12,
                    color: AppColors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                report['title'],
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isPatientReport && report['doctorName'] != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Dr. ${report['doctorName'].toString().split(' ').first}',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Fecha: ${report['date']}',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report['status']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    report['status'],
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: _getStatusColor(report['status']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    'Resultado: ${report['result']}',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (isPatientReport && report['patientId'] != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _getPatientName(report['patientId']),
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'DNI: ${_getPatientDni(report['patientId'])}',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _showReportDetails(report);
        },
      ),
    );
  }

  /// Obtiene el nombre del paciente desde el cache o retorna un valor por defecto
  String _getPatientName(dynamic patientId) {
    if (patientId == null) return 'Sin paciente';
    
    int? id;
    if (patientId is int) {
      id = patientId;
    } else if (patientId is String) {
      id = int.tryParse(patientId);
    }
    
    if (id != null) {
      if (_patientNamesCache.containsKey(id)) {
        return _patientNamesCache[id]!;
      }
      return 'Paciente #$id';
    }
    
    return 'Paciente #$patientId';
  }

  /// Obtiene el DNI del paciente desde el cache o retorna un valor por defecto
  String _getPatientDni(dynamic patientId) {
    if (patientId == null) return 'N/A';
    
    int? id;
    if (patientId is int) {
      id = patientId;
    } else if (patientId is String) {
      id = int.tryParse(patientId);
    }
    
    if (id != null && _patientDniCache.containsKey(id)) {
      return _patientDniCache[id]!;
    }
    
    return 'N/A';
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
      
      // Obtener datos del paciente si el reporte tiene patientId
      String? patientName;
      String? patientDni;
      String? patientAge;
      
      if (report['patientId'] != null) {
        try {
          final patientIdValue = report['patientId'];
          int? id;
          if (patientIdValue is int) {
            id = patientIdValue;
          } else if (patientIdValue is String) {
            id = int.tryParse(patientIdValue);
          }
          
          if (id != null) {
            // Obtener nombre y DNI del paciente desde el cache o del backend
            final patientIdInt = id; // Guardar referencia no nullable
            if (patientIdInt != null) {
              if (_patientNamesCache.containsKey(patientIdInt)) {
                patientName = _patientNamesCache[patientIdInt];
                patientDni = _patientDniCache[patientIdInt];
              } else {
                final response = await _patientService.getPatientById(patientIdInt);
                if (response.success && response.data != null) {
                  patientName = response.data!['fullName'] ?? 
                               response.data!['nombre_completo'] ?? 
                               response.data!['full_name'];
                  patientDni = response.data!['identification'] ?? 
                              response.data!['identificacion'] ?? 
                              '';
                  patientAge = response.data!['age']?.toString();
                  
                  // Actualizar cache
                  if (mounted) {
                    setState(() {
                      _patientNamesCache[patientIdInt] = patientName ?? 'Paciente #$patientIdInt';
                      if (patientDni != null && patientDni.isNotEmpty) {
                        _patientDniCache[patientIdInt] = patientDni;
                      }
                    });
                  }
                }
              }
              
              // Si no tenemos la edad, intentar obtenerla del backend
              if (patientAge == null) {
                final response = await _patientService.getPatientById(patientIdInt);
                if (response.success && response.data != null) {
                  patientAge = response.data!['age']?.toString();
                }
              }
            }
          }
        } catch (e) {
          print('⚠️ Error obteniendo datos del paciente: $e');
        }
      }
      
      // Obtener fecha del estudio
      String? studyDate = report['studyDate'] ?? report['date'];
      if (studyDate != null && studyDate.contains('-')) {
        try {
          final parts = studyDate.split('-');
          if (parts.length == 3) {
            studyDate = '${parts[2]}/${parts[1]}/${parts[0]}';
          }
        } catch (e) {
          print('⚠️ Error formateando fecha: $e');
        }
      }
      
      // Mostrar indicador de carga
      if (mounted) {
        context.showInfoSnackBar('Generando PDF...');
      }
      
      // Generar y descargar el PDF con los datos del paciente
      print('📄 Llamando a PDFService.generateAndDownloadReport...');
      print('👤 Datos del paciente: nombre=$patientName, DNI=$patientDni, edad=$patientAge');
      final success = await PDFService.generateAndDownloadReport(
        report,
        patientName: patientName,
        patientId: patientDni, // Pasar DNI en lugar del ID
        patientAge: patientAge,
        studyDate: studyDate,
        doctorName: report['doctorName'],
        observations: report['observations'],
      );
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











