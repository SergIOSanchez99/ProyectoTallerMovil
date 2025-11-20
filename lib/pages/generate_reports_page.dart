import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/extensions.dart';
import '../utils/validators.dart';
import '../services/report_service.dart';
import '../services/pdf_service.dart';
import '../services/patient_service.dart';
import '../services/study_service.dart';
import '../services/medical_recommendations_service.dart';
import '../services/auth_service.dart';
import '../services/image_storage_service.dart';
import 'package:provider/provider.dart';
import 'upload_image_page.dart';

class GenerateReportsPage extends StatefulWidget {
  const GenerateReportsPage({super.key});

  @override
  State<GenerateReportsPage> createState() => _GenerateReportsPageState();
}

class _GenerateReportsPageState extends State<GenerateReportsPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _doctorController = TextEditingController();
  final _observationsController = TextEditingController();
  bool _isGenerating = false;
  String? _selectedReportType;
  Map<String, dynamic>? _selectedPreviousReport; // Para reportes comparativos
  Map<String, dynamic>? _selectedAnalysisReport; // Para reportes básico y detallado
  List<Map<String, dynamic>> _previousReports = [];
  bool _isLoadingReports = false;
  
  // Gestión de pacientes
  final PatientService _patientService = PatientService();
  final StudyService _studyService = StudyService();
  List<Map<String, dynamic>> _patients = [];
  Map<String, dynamic>? _selectedPatient;
  bool _isLoadingPatients = false;
  bool _isCreatingPatient = false;
  final _searchPatientController = TextEditingController();
  
  // Análisis más reciente (para asociar con paciente nuevo)
  Map<String, dynamic>? _latestAnalysis;

  @override
  void initState() {
    super.initState();
    _loadPreviousReports();
    _loadPatients();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _doctorController.dispose();
    _observationsController.dispose();
    _searchPatientController.dispose();
    super.dispose();
  }

  Future<void> _loadPreviousReports() async {
    setState(() {
      _isLoadingReports = true;
    });
    
    try {
      await ReportService.loadReports();
      final reports = ReportService.getAllReports();
      setState(() {
        _previousReports = reports;
        _isLoadingReports = false;
      });
      
      // Recargar el análisis más reciente después de cargar reportes
      _loadLatestAnalysis();
    } catch (e) {
      print('Error cargando reportes previos: $e');
      setState(() {
        _isLoadingReports = false;
      });
    }
  }

  Future<void> _loadPatients({String? search}) async {
    setState(() {
      _isLoadingPatients = true;
    });
    
    try {
      final response = await _patientService.getAllPatients(search: search);
      if (response.success && response.data != null) {
        setState(() {
          _patients = response.data!;
          _isLoadingPatients = false;
        });
      } else {
        setState(() {
          _isLoadingPatients = false;
        });
        if (mounted) {
          context.showErrorSnackBar(response.message ?? 'Error al cargar pacientes');
        }
      }
    } catch (e) {
      print('Error cargando pacientes: $e');
      setState(() {
        _isLoadingPatients = false;
      });
    }
  }

  Future<void> _searchPatient(String query) async {
    if (query.isEmpty) {
      await _loadPatients();
    } else {
      await _loadPatients(search: query);
    }
  }
  
  /// Cargar el análisis más reciente del provider (si existe)
  void _loadLatestAnalysis() {
    try {
      final provider = Provider.of<ColonoscopyAnalysisData>(context, listen: false);
      if (provider.hasAnalysis && provider.analysis != null) {
        final analysis = provider.analysis!;
        _latestAnalysis = {
          'result': analysis.result,
          'stage': analysis.currentStage,
          'confidence': 0.85, // Valor por defecto si no está disponible
          'riskLevel': _determineRiskLevel(analysis.result),
          'analysisDate': analysis.analysisDate.toIso8601String(),
        };
        print('✅ Análisis más reciente cargado del provider: ${_latestAnalysis!['result']}');
      } else {
        // Si no hay en el provider, intentar obtener del historial más reciente
        if (_previousReports.isNotEmpty) {
          final sortedReports = List<Map<String, dynamic>>.from(_previousReports)
            ..sort((a, b) {
              final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
              final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
              return dateB.compareTo(dateA);
            });
          
          final mostRecent = sortedReports.firstWhere(
            (r) => r['result'] != null && 
                   r['result'].toString().isNotEmpty && 
                   r['result'] != 'Análisis pendiente',
            orElse: () => {},
          );
          
          if (mostRecent.isNotEmpty) {
            _latestAnalysis = {
              'result': mostRecent['result'] ?? 'N/A',
              'stage': mostRecent['stage'] ?? 'N/A',
              'confidence': _getConfidenceValue(mostRecent['confidence'] ?? 0.0),
              'riskLevel': mostRecent['riskLevel'] ?? mostRecent['risk_level'] ?? 'N/A',
              'analysisDate': mostRecent['createdAt'] ?? DateTime.now().toIso8601String(),
            };
            print('✅ Análisis más reciente cargado del historial: ${_latestAnalysis!['result']}');
          }
        }
      }
    } catch (e) {
      print('⚠️ No se pudo cargar análisis: $e');
    }
  }
  
  /// Determina el nivel de riesgo basado en el resultado
  String _determineRiskLevel(String result) {
    final resultLower = result.toLowerCase();
    if (resultLower.contains('cáncer') || resultLower.contains('tumor') || resultLower.contains('maligno')) {
      return 'Alto';
    } else if (resultLower.contains('pólipo') || resultLower.contains('polipo') || resultLower.contains('anomalía')) {
      return 'Medio';
    } else {
      return 'Bajo';
    }
  }

  void _selectPatient(Map<String, dynamic> patient) {
    setState(() {
      _selectedPatient = patient;
    });
  }

  void _clearPatientSelection() {
    setState(() {
      _selectedPatient = null;
      _dateController.clear();
      _doctorController.clear();
      _observationsController.clear();
    });
  }

  Widget _buildSelectedPatientCard() {
    if (_selectedPatient == null) return const SizedBox.shrink();
    
    final patientName = _selectedPatient!['fullName'] ?? 
                       _selectedPatient!['nombre_completo'] ?? 
                       _selectedPatient!['full_name'] ?? 
                       'Sin nombre';
    final patientDni = _selectedPatient!['identification'] ?? 
                      _selectedPatient!['identificacion'] ?? 
                      'N/A';
    final patientAge = _selectedPatient!['age'];
    
    // Obtener datos del análisis seleccionado si existe
    Map<String, dynamic>? analysisData;
    if (_selectedAnalysisReport != null) {
      analysisData = _selectedAnalysisReport;
    }
    
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeXL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Wrap(
                  spacing: AppDimensions.spacingS,
                  runSpacing: AppDimensions.spacingXS,
                  children: [
                    Text(
                      'DNI: $patientDni',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (patientAge != null)
                      Text(
                        'Edad: $patientAge años',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                // Mostrar resultados del análisis seleccionado si existe
                if (analysisData != null) ...[
                  const SizedBox(height: AppDimensions.spacingM),
                  const Divider(height: 1),
                  const SizedBox(height: AppDimensions.spacingS),
                  const Text(
                    'Resultados del Análisis Seleccionado:',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  _buildAnalysisInfoRow(
                    'Resultado:',
                    analysisData['result'] ?? 'N/A',
                    AppColors.textPrimary,
                  ),
                  if (analysisData['stage'] != null)
                    _buildAnalysisInfoRow(
                      'Etapa:',
                      analysisData['stage'] ?? 'N/A',
                      AppColors.textSecondary,
                    ),
                  if (analysisData['confidence'] != null)
                    _buildAnalysisInfoRow(
                      'Confianza:',
                      '${(_getConfidenceValue(analysisData['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                      AppColors.textSecondary,
                    ),
                  if (analysisData['riskLevel'] != null || analysisData['risk_level'] != null)
                    _buildAnalysisInfoRow(
                      'Nivel de Riesgo:',
                      analysisData['riskLevel'] ?? analysisData['risk_level'] ?? 'N/A',
                      _getRiskLevelColor(analysisData['riskLevel'] ?? analysisData['risk_level'] ?? 'N/A'),
                    ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: _clearPatientSelection,
            icon: const Icon(
              Icons.close,
              color: AppColors.error,
            ),
            tooltip: 'Limpiar selección',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeS,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeS,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'alto':
        return AppColors.error;
      case 'medio':
        return AppColors.warning;
      case 'bajo':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _showCreatePatientDialog() async {
    // Controladores para el diálogo
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final ageController = TextEditingController();
    final dateController = TextEditingController();
    final doctorController = TextEditingController();
    final observationsController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: AppColors.primaryBlue),
              SizedBox(width: AppDimensions.spacingM),
              Text('Registrar Nuevo Paciente'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Datos del Paciente',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  CustomTextField(
                    label: 'Nombres y apellidos',
                    controller: nameController,
                    hint: 'Ingrese el nombre completo',
                    validator: (value) => Validators.validateRequired(value, 'Nombre completo'),
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                  CustomTextField(
                    label: 'Identificación (DNI)',
                    controller: idController,
                    hint: 'Ingrese el número de identificación',
                    validator: (value) => Validators.validateRequired(value, 'Identificación'),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                  CustomTextField(
                    label: 'Edad',
                    controller: ageController,
                    hint: 'Ingrese la edad',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final age = int.tryParse(value);
                        if (age == null || age < 0 || age > 100) {
                          return 'Ingrese una edad válida';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingXL),
                  const Divider(),
                  const SizedBox(height: AppDimensions.spacingXL),
                  const Text(
                    'Datos del Estudio',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  CustomTextField(
                    label: 'Fecha del Estudio',
                    controller: dateController,
                    hint: 'DD/MM/AAAA',
                    readOnly: true,
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      
                      if (picked != null) {
                        selectedDate = picked;
                        dateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                      }
                    },
                    validator: (value) => Validators.validateRequired(value, 'Fecha del estudio'),
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                  CustomTextField(
                    label: 'Médico Responsable',
                    controller: doctorController,
                    hint: 'Ingrese el nombre del médico',
                    validator: (value) => Validators.validateRequired(value, 'Médico responsable'),
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                  CustomTextField(
                    label: 'Observaciones (Opcional)',
                    controller: observationsController,
                    hint: 'Ingrese observaciones adicionales',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isCreatingPatient ? null : () async {
                if (formKey.currentState!.validate()) {
                  await _createNewPatient(
                    name: nameController.text.trim(),
                    id: idController.text.trim(),
                    age: ageController.text.trim(),
                    date: dateController.text.trim(),
                    doctor: doctorController.text.trim(),
                    observations: observationsController.text.trim(),
                  );
                  if (mounted && _selectedPatient != null) {
                    Navigator.of(dialogContext).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
              ),
              child: _isCreatingPatient
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Registrar'),
            ),
          ],
        );
      },
    );

    // Limpiar controladores
    nameController.dispose();
    idController.dispose();
    ageController.dispose();
    dateController.dispose();
    doctorController.dispose();
    observationsController.dispose();
  }

  Future<void> _createNewPatient({
    required String name,
    required String id,
    String age = '',
    String date = '',
    String doctor = '',
    String observations = '',
  }) async {
    if (name.isEmpty) {
      if (mounted) {
        context.showErrorSnackBar('Por favor ingrese el nombre del paciente');
      }
      return;
    }

    if (id.isEmpty) {
      if (mounted) {
        context.showErrorSnackBar('Por favor ingrese la identificación del paciente');
      }
      return;
    }

    // Validar edad si se proporciona
    int? ageInt;
    if (age.isNotEmpty) {
      ageInt = int.tryParse(age);
      if (ageInt == null || ageInt < 0 || ageInt > 150) {
        if (mounted) {
          context.showErrorSnackBar('Por favor ingrese una edad válida (0-150)');
        }
        return;
      }
    }

    setState(() {
      _isCreatingPatient = true;
    });

    try {
      print('🔄 Creando paciente nuevo...');
      print('📋 Nombre: $name');
      print('📋 ID: $id');
      if (ageInt != null) {
        print('📋 Edad: $ageInt');
      }
      
      final response = await _patientService.createPatient(
        fullName: name,
        identification: id,
        age: ageInt,
      );

      print('📥 Respuesta del servidor: success=${response.success}');
      print('📥 Mensaje: ${response.message}');
      if (response.data != null) {
        print('📥 Datos recibidos: ${response.data!.keys.toList()}');
      }

      if (response.success && response.data != null) {
        final patientId = response.data!['id'];
        
        setState(() {
          _selectedPatient = response.data;
          _isCreatingPatient = false;
          // Llenar los campos del formulario principal con los datos del estudio
          if (date.isNotEmpty) {
            _dateController.text = date;
          }
          if (doctor.isNotEmpty) {
            _doctorController.text = doctor;
          }
          if (observations.isNotEmpty) {
            _observationsController.text = observations;
          }
          // Guardar la edad en el objeto del paciente si se proporcionó
          if (age.isNotEmpty) {
            final ageInt = int.tryParse(age);
            if (ageInt != null) {
              _selectedPatient!['age'] = ageInt;
            }
          }
        });
        
        // Asociar el análisis más reciente con el paciente recién creado
        await _associateAnalysisWithPatient(patientId, date, doctor, observations);
        
        await _loadPatients();
        if (mounted) {
          context.showSuccessSnackBar('Paciente registrado exitosamente. Análisis asociado correctamente.');
        }
      } else {
        setState(() {
          _isCreatingPatient = false;
        });
        if (mounted) {
          final errorMsg = response.message ?? 'Error al crear paciente';
          print('❌ Error: $errorMsg');
          context.showErrorSnackBar(errorMsg);
        }
      }
    } catch (e, stackTrace) {
      print('❌ Excepción al crear paciente: $e');
      print('❌ Stack trace: $stackTrace');
      setState(() {
        _isCreatingPatient = false;
      });
      if (mounted) {
        context.showErrorSnackBar('Error al crear paciente: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightBlue,
      appBar: AppBar(
        title: const Text('Generar Reportes'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                // Formulario de datos del paciente
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos del Paciente',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeXXL,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      // Selector de paciente existente
                      _buildPatientSelector(),
                      const SizedBox(height: AppDimensions.spacingL),
                      // Mostrar información del paciente seleccionado
                      if (_selectedPatient != null) ...[
                        _buildSelectedPatientCard(),
                        const SizedBox(height: AppDimensions.spacingL),
                      ],
                      // Mostrar campos de estudio solo si hay un paciente seleccionado
                      if (_selectedPatient != null) ...[
                        const SizedBox(height: AppDimensions.spacingXL),
                        const Divider(),
                        const SizedBox(height: AppDimensions.spacingL),
                        const Text(
                          'Datos del Estudio',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeXXL,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingL),
                        CustomTextField(
                          label: 'Fecha del Estudio',
                          controller: _dateController,
                          hint: 'DD/MM/AAAA',
                          readOnly: true,
                          onTap: () => _selectDate(),
                          validator: (value) => Validators.validateRequired(value, 'Fecha del estudio'),
                        ),
                        const SizedBox(height: AppDimensions.spacingL),
                        CustomTextField(
                          label: 'Médico Responsable',
                          controller: _doctorController,
                          hint: 'Ingrese el nombre del médico',
                          validator: (value) => Validators.validateRequired(value, 'Médico responsable'),
                        ),
                        const SizedBox(height: AppDimensions.spacingL),
                        CustomTextField(
                          label: 'Observaciones (Opcional)',
                          controller: _observationsController,
                          hint: 'Ingrese observaciones adicionales',
                          maxLines: 3,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingL),
                // Opciones de reporte
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Tipo de Reporte',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeXXL,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildReportOption(
                        title: 'Reporte Básico',
                        description: 'Información esencial: resultado, etapa, nivel de riesgo y recomendaciones básicas. Ideal para consultas rápidas.',
                        icon: Icons.description,
                        reportType: 'básico',
                        isSelected: _selectedReportType == 'básico',
                      ),
                      const Divider(),
                      _buildReportOption(
                        title: 'Reporte Detallado',
                        description: 'Análisis completo con interpretación clínica, recomendaciones médicas y plan de seguimiento. Recomendado para evaluación oncológica.',
                        icon: Icons.analytics,
                        reportType: 'detallado',
                        isSelected: _selectedReportType == 'detallado',
                      ),
                      const Divider(),
                      _buildReportOption(
                        title: 'Reporte Comparativo',
                        description: 'Comparación detallada entre el análisis actual y uno previo. Incluye análisis de evolución y cambios en el riesgo. Esencial para seguimiento oncológico.',
                        icon: Icons.compare,
                        reportType: 'comparativo',
                        isSelected: _selectedReportType == 'comparativo',
                      ),
                      // Mostrar selector de análisis para reportes básico y detallado
                      if (_selectedReportType == 'básico' || _selectedReportType == 'detallado') ...[
                        const SizedBox(height: AppDimensions.spacingM),
                        const Divider(height: 1),
                        _buildAnalysisReportSelector(),
                      ],
                      // Mostrar selector de reporte previo si es comparativo
                      if (_selectedReportType == 'comparativo') ...[
                        const SizedBox(height: AppDimensions.spacingM),
                        const Divider(height: 1),
                        _buildPreviousReportSelector(),
                      ],
                    ],
                  ),
                ),
                      ],
                    ),
                  ),
                ),
                // Botón de generar (fuera del scroll)
                CustomButton(
                  text: 'Generar Reporte',
                  onPressed: _handleGenerateReport,
                  isLoading: _isGenerating,
                  icon: Icons.file_download,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption({
    required String title,
    required String description,
    required IconData icon,
    required String reportType,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.success : AppColors.primaryBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: FontWeight.bold,
          color: isSelected ? AppColors.success : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeM,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.success)
          : const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary),
      onTap: () {
        setState(() {
          _selectedReportType = reportType;
          if (reportType != 'comparativo') {
            _selectedPreviousReport = null;
          }
        });
      },
    );
  }

  Widget _buildPatientSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seleccionar Paciente Existente',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        // Campo de búsqueda
        CustomTextField(
          label: 'Buscar Paciente',
          controller: _searchPatientController,
          hint: 'Buscar por nombre o identificación',
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
          onChanged: (value) {
            // Debounce para evitar demasiadas llamadas
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_searchPatientController.text == value) {
                _searchPatient(value);
              }
            });
          },
        ),
        const SizedBox(height: AppDimensions.spacingM),
        // Botón para crear nuevo paciente (siempre visible)
        CustomButton(
          text: 'Registrar Nuevo Paciente',
          onPressed: _showCreatePatientDialog,
          isLoading: false,
          icon: Icons.person_add,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        // Lista de pacientes
        if (_isLoadingPatients)
          const Padding(
            padding: EdgeInsets.all(AppDimensions.spacingL),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_patients.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Text(
              'No hay pacientes registrados. Use el botón de arriba para crear uno nuevo.',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final patient = _patients[index];
                final isSelected = _selectedPatient != null && 
                    _selectedPatient!['id'] == patient['id'];
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected 
                        ? AppColors.success 
                        : AppColors.primaryBlue.withOpacity(0.2),
                    child: Icon(
                      isSelected ? Icons.check : Icons.person,
                      color: isSelected ? AppColors.white : AppColors.primaryBlue,
                    ),
                  ),
                  title: Text(
                    patient['fullName'] ?? patient['nombre_completo'] ?? patient['full_name'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.success : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'ID: ${patient['identification'] ?? patient['identificacion'] ?? 'N/A'}${patient['age'] != null ? ' | Edad: ${patient['age']} años' : ''}',
                    style: const TextStyle(fontSize: AppDimensions.fontSizeS),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _selectPatient(patient),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAnalysisReportSelector() {
    if (_isLoadingReports) {
      return const Padding(
        padding: EdgeInsets.all(AppDimensions.spacingL),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_previousReports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Text(
          'No hay análisis disponibles en el historial. Por favor suba una imagen y analícela primero.',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Filtrar solo reportes con análisis válidos
    final validReports = _previousReports.where((report) {
      final result = report['result'];
      return result != null && 
             result.toString().isNotEmpty && 
             result != 'Análisis pendiente' &&
             result != 'N/A' &&
             result != 'No hay análisis disponible';
    }).toList();

    if (validReports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Text(
          'No hay análisis válidos disponibles. Por favor suba una imagen y analícela primero.',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Seleccionar Análisis del Historial',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          'Seleccione el análisis que desea usar para generar el reporte',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Container(
          constraints: const BoxConstraints(
            maxHeight: 180,
            minHeight: 48,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryBlue),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _selectedAnalysisReport,
              isExpanded: true,
              menuMaxHeight: 300,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
              ),
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: AppDimensions.spacingXS),
                child: Text(
                  'Seleccione un análisis del historial',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              items: validReports.map((report) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: report,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: AppDimensions.spacingXS),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          report['title'] ?? 'Análisis sin título',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Resultado: ${report['result'] ?? 'N/A'} | Etapa: ${report['stage'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (report['date'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Fecha: ${report['date']}',
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeS,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              selectedItemBuilder: (BuildContext context) {
                return validReports.map<Widget>((report) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
                    child: Text(
                      report['title'] ?? 'Análisis sin título',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList();
              },
              onChanged: (value) {
                setState(() {
                  _selectedAnalysisReport = value;
                });
              },
            ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviousReportSelector() {
    if (_isLoadingReports) {
      return const Padding(
        padding: EdgeInsets.all(AppDimensions.spacingL),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_previousReports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Text(
          'No hay reportes previos disponibles para comparar',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Seleccionar Reporte Previo para Comparar',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Container(
          constraints: const BoxConstraints(
            maxHeight: 200,
            minHeight: 48,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryBlue),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _selectedPreviousReport,
              isExpanded: true,
              menuMaxHeight: 300,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
              ),
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
                child: Text(
                  'Seleccione un reporte previo',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              items: _previousReports.map((report) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: report,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          report['title'] ?? 'Sin título',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fecha: ${report['date'] ?? 'N/A'} | Resultado: ${report['result'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              selectedItemBuilder: (BuildContext context) {
                return _previousReports.map<Widget>((report) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
                    child: Text(
                      report['title'] ?? 'Sin título',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList();
              },
              onChanged: (value) {
                setState(() {
                  _selectedPreviousReport = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      _dateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  void _handleGenerateReport() async {
    // Validar que haya un paciente seleccionado
    if (_selectedPatient == null) {
      context.showErrorSnackBar('Por favor seleccione o registre un paciente');
      return;
    }

    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      context.showErrorSnackBar('Por favor complete todos los campos requeridos');
      return;
    }

    // Validar que se haya seleccionado un tipo de reporte
    if (_selectedReportType == null) {
      context.showErrorSnackBar('Por favor seleccione un tipo de reporte');
      return;
    }

    // Validar reporte previo si es comparativo
    if (_selectedReportType == 'comparativo') {
      if (_selectedPreviousReport == null) {
      context.showErrorSnackBar('Por favor seleccione un reporte previo para comparar');
      return;
      }
      // Validar que haya un reporte actual para comparar
      final currentReport = await _getMostRecentReportForPatient();
      if (currentReport == null) {
        context.showErrorSnackBar('No hay análisis reciente disponible para comparar. Por favor realice un análisis de imagen primero.');
        return;
      }
    }
    
    // Validar que haya un análisis disponible para reportes básico y detallado
    if (_selectedReportType != 'comparativo') {
      // Si hay un análisis seleccionado del historial, validar que tenga datos válidos
      if (_selectedAnalysisReport != null) {
        final result = _selectedAnalysisReport!['result'];
        if (result == null || 
            result.toString().isEmpty ||
            result.toString() == 'Análisis pendiente' ||
            result.toString() == 'N/A' ||
            result.toString() == 'No hay análisis disponible') {
          context.showErrorSnackBar('El análisis seleccionado no tiene datos válidos. Por favor seleccione otro análisis.');
          return;
        }
        // Si hay análisis seleccionado válido, continuar
      } else {
        // Si no hay análisis seleccionado, buscar análisis del paciente o historial (fallback)
        var currentReport = await _getMostRecentReportForPatient();
        
        // Si no hay análisis asociado al paciente, buscar en el provider o historial general
        if (currentReport == null || 
            (currentReport['result'] == null || 
             currentReport['result'].toString().isEmpty ||
             currentReport['result'].toString() == 'Análisis pendiente' ||
             currentReport['result'].toString() == 'No hay análisis disponible')) {
          
          // Intentar obtener del provider
          try {
            final provider = Provider.of<ColonoscopyAnalysisData>(context, listen: false);
            if (provider.hasAnalysis && provider.analysis != null) {
              final analysis = provider.analysis!;
              currentReport = {
                'result': analysis.result,
                'stage': analysis.currentStage,
                'confidence': 0.85,
                'riskLevel': _determineRiskLevel(analysis.result),
              };
              print('✅ Análisis encontrado en el provider');
            }
          } catch (e) {
            print('⚠️ No se pudo obtener análisis del provider: $e');
          }
          
          // Si aún no hay, buscar en el historial general
          if (currentReport == null || 
              (currentReport['result'] == null || 
               currentReport['result'].toString().isEmpty ||
               currentReport['result'].toString() == 'Análisis pendiente' ||
               currentReport['result'].toString() == 'No hay análisis disponible')) {
            
            if (_previousReports.isNotEmpty) {
              final sortedReports = List<Map<String, dynamic>>.from(_previousReports)
                ..sort((a, b) {
                  final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
                  final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
                  return dateB.compareTo(dateA);
                });
              
              for (var report in sortedReports) {
                final result = report['result'];
                if (result != null && 
                    result.toString().isNotEmpty && 
                    result != 'Análisis pendiente' &&
                    result != 'N/A' &&
                    result != 'No hay análisis disponible') {
                  currentReport = Map<String, dynamic>.from(report);
                  print('✅ Análisis encontrado en el historial general');
                  break;
                }
              }
            }
          }
          
          // Si aún no hay análisis válido, mostrar error sugiriendo seleccionar del historial
          if (currentReport == null || 
              (currentReport['result'] == null || 
               currentReport['result'].toString().isEmpty ||
               currentReport['result'].toString() == 'Análisis pendiente' ||
               currentReport['result'].toString() == 'No hay análisis disponible')) {
            context.showErrorSnackBar('No hay análisis disponible. Por favor seleccione un análisis del historial o realice un análisis de imagen antes de generar el reporte.');
            return;
          }
        }
      }
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Obtener datos del paciente seleccionado
      final patientName = _selectedPatient!['fullName'] ?? 
                         _selectedPatient!['nombre_completo'] ?? 
                         _selectedPatient!['full_name'] ?? 
                         'Sin nombre';
      final patientDni = _selectedPatient!['identification'] ?? 
                        _selectedPatient!['identificacion'] ?? 
                        'N/A';
      final patientAge = _selectedPatient!['age']?.toString() ?? '';

      // Preparar datos del reporte (ahora es async)
      final reportData = await _buildReportData();

      // Generar PDF según el tipo de reporte
      final success = await PDFService.generateAndDownloadReport(
        reportData,
        reportType: _selectedReportType!,
        patientName: patientName,
        patientId: patientDni, // Pasar DNI en lugar del ID
        patientAge: patientAge,
        studyDate: _dateController.text,
        doctorName: _doctorController.text,
        observations: _observationsController.text.isNotEmpty 
            ? _observationsController.text 
            : null,
        previousReport: _selectedPreviousReport,
      );

      if (success) {
        // Obtener ID del paciente
        final patientIdInt = _selectedPatient!['id'];
        final patientId = patientIdInt != null ? (patientIdInt is int ? patientIdInt : int.tryParse(patientIdInt.toString())) : null;
        
        // Obtener ID del usuario actual
        int? userId;
        try {
          final authService = AuthService();
          final userResponse = await authService.getCurrentUser();
          if (userResponse.success && userResponse.data != null) {
            final userIdStr = userResponse.data!.id;
            userId = int.tryParse(userIdStr);
            print('✅ Usuario actual obtenido: ID $userId');
          } else {
            print('⚠️ No se pudo obtener usuario actual: ${userResponse.error}');
          }
        } catch (e) {
          print('⚠️ Error obteniendo usuario actual: $e');
        }
        
        // Convertir fecha del estudio al formato correcto
        String? formattedDate;
        if (_dateController.text.isNotEmpty) {
          try {
            // Formato DD/MM/YYYY a YYYY-MM-DD
            final parts = _dateController.text.split('/');
            if (parts.length == 3) {
              formattedDate = '${parts[2]}-${parts[1]}-${parts[0]}';
            }
          } catch (e) {
            formattedDate = DateTime.now().toIso8601String().split('T')[0];
          }
        } else {
          formattedDate = DateTime.now().toIso8601String().split('T')[0];
        }
        
        // Obtener ruta de la imagen del análisis seleccionado (solo referencia, NO cargar la imagen)
        // Solo guardamos la referencia si existe, pero NO cargamos ni procesamos la imagen
        String? imagePath = reportData['imagePath'] ?? reportData['image_path'];
        String? relativeImagePath;
        
        // Solo procesar la ruta si existe, pero NO cargar la imagen
        if (imagePath != null && imagePath.isNotEmpty) {
          try {
            // Si es una ruta relativa, mantenerla como está (no convertir a absoluta ni cargar)
            if (!imagePath.startsWith('/')) {
              relativeImagePath = imagePath; // Ya es relativa, solo guardar referencia
            } else {
              // Si es absoluta, convertir a relativa para almacenar (pero NO cargar la imagen)
              relativeImagePath = await ImageStorageService.getRelativePath(imagePath);
            }
          } catch (e) {
            print('⚠️ Error procesando ruta de imagen (solo referencia, sin cargar): $e');
            relativeImagePath = imagePath; // Usar la ruta original si falla
          }
        }
        
        // Guardar el reporte en el historial con TODOS los datos (paciente, análisis, doctor, observaciones)
        // NO cargamos la imagen, solo guardamos la referencia si existe
        // ReportService.addReport() ya maneja el guardado en el backend, no necesitamos llamar createStudy aquí
        await ReportService.addReport(
          result: reportData['result'] ?? 'N/A',
          stage: reportData['stage'] ?? 'N/A',
          confidence: _getConfidenceValue(reportData['confidence'] ?? 0.0),
          riskLevel: reportData['riskLevel'] ?? reportData['risk_level'] ?? 'N/A',
          patientId: patientId,
          userId: userId,
          imagePath: relativeImagePath, // Solo referencia, NO carga la imagen
          studyDate: formattedDate,
          doctorName: _doctorController.text.isNotEmpty ? _doctorController.text : null,
          observations: _observationsController.text.isNotEmpty ? _observationsController.text : null,
        );
        
        print('✅ Reporte guardado en el historial con todos los datos del paciente y análisis');

        if (mounted) {
          context.showSuccessSnackBar('Reporte generado y descargado correctamente');
          // Limpiar formulario
          _dateController.clear();
          _doctorController.clear();
          _observationsController.clear();
          setState(() {
            _selectedReportType = null;
            _selectedPreviousReport = null;
            _selectedAnalysisReport = null;
          });
        }
      } else {
        if (mounted) {
          context.showErrorSnackBar('Error al generar el reporte. Por favor intente nuevamente.');
        }
      }
    } catch (e) {
      print('Error generando reporte: $e');
      if (mounted) {
        context.showErrorSnackBar('Error al generar el reporte: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _buildReportData() async {
    // Si es comparativo y hay reporte previo, usar el reporte actual más reciente del paciente
    if (_selectedReportType == 'comparativo' && _selectedPreviousReport != null) {
      // Para comparativo, necesitamos el reporte ACTUAL (más reciente del paciente)
      final currentReport = await _getMostRecentReportForPatient();
      if (currentReport != null) {
        return Map<String, dynamic>.from(currentReport);
      }
      // Si no hay reporte actual, usar el previo como base
      return Map<String, dynamic>.from(_selectedPreviousReport!);
    }

    // Si es básico o detallado y hay un análisis seleccionado del historial, usarlo
    if ((_selectedReportType == 'básico' || _selectedReportType == 'detallado') && 
        _selectedAnalysisReport != null) {
      print('✅ Usando análisis seleccionado del historial');
      print('📋 Análisis seleccionado completo: ${_selectedAnalysisReport!.keys.toList()}');
      print('📋 Valores: result=${_selectedAnalysisReport!['result']}, stage=${_selectedAnalysisReport!['stage']}, confidence=${_selectedAnalysisReport!['confidence']}, riskLevel=${_selectedAnalysisReport!['riskLevel'] ?? _selectedAnalysisReport!['risk_level']}');
      
      final reportData = Map<String, dynamic>.from(_selectedAnalysisReport!);
      
      // Normalizar nombres de campos (backend puede usar risk_level, frontend usa riskLevel)
      if (reportData['risk_level'] != null && reportData['riskLevel'] == null) {
        reportData['riskLevel'] = reportData['risk_level'];
      }
      
      // Asegurar que todos los campos necesarios estén presentes
      reportData['result'] = reportData['result'] ?? 'N/A';
      reportData['stage'] = reportData['stage'] ?? 'N/A';
      reportData['confidence'] = _getConfidenceValue(reportData['confidence'] ?? 0.0);
      reportData['riskLevel'] = reportData['riskLevel'] ?? reportData['risk_level'] ?? 'N/A';
      
      // Agregar información adicional para el reporte
      reportData['title'] = 'Reporte de Colonoscopia - ${_dateController.text}';
      reportData['date'] = _dateController.text;
      reportData['status'] = 'Completado';
      
      // Generar recomendaciones médicas con los datos del análisis seleccionado
      final result = reportData['result'] ?? 'N/A';
      final stage = reportData['stage'] ?? 'N/A';
      final riskLevel = reportData['riskLevel'] ?? 'N/A';
      final confidence = _getConfidenceValue(reportData['confidence'] ?? 0.0);
      
      print('📊 Datos del análisis seleccionado normalizados:');
      print('   - Resultado: $result');
      print('   - Etapa: $stage');
      print('   - Confianza: $confidence');
      print('   - Nivel de riesgo: $riskLevel');
      print('📋 reportData final antes de generar PDF:');
      print('   - reportData keys: ${reportData.keys.toList()}');
      print('   - reportData[result]: ${reportData['result']}');
      print('   - reportData[stage]: ${reportData['stage']}');
      print('   - reportData[confidence]: ${reportData['confidence']}');
      print('   - reportData[riskLevel]: ${reportData['riskLevel']}');
      
      // Generar recomendaciones si tenemos datos válidos
      if (result != 'N/A' && result != 'Análisis pendiente' && result != 'No hay análisis disponible') {
        reportData['recommendation'] = MedicalRecommendationsService.generateRecommendations(
          result: result,
          stage: stage,
          riskLevel: riskLevel,
          confidence: confidence,
        );
        
        reportData['clinicalInterpretation'] = MedicalRecommendationsService.generateClinicalInterpretation(
          result: result,
          stage: stage,
          riskLevel: riskLevel,
          confidence: confidence,
        );
        
        reportData['followUpPlan'] = MedicalRecommendationsService.generateFollowUpPlan(
          result: result,
          riskLevel: riskLevel,
        );
      }
      
      return reportData;
    }

    // Obtener el análisis más reciente del paciente seleccionado (fallback)
    final mostRecentReport = await _getMostRecentReportForPatient();
    
    if (mostRecentReport != null) {
      // Usar datos reales del análisis más reciente
      final reportData = Map<String, dynamic>.from(mostRecentReport);
      
      // Normalizar nombres de campos (backend puede usar risk_level, frontend usa riskLevel)
      if (reportData['risk_level'] != null && reportData['riskLevel'] == null) {
        reportData['riskLevel'] = reportData['risk_level'];
      }
      
      // Asegurar que tenemos los datos del análisis
      // Si no están en el reporte, intentar obtenerlos del historial o del provider
      if ((reportData['result'] == null || 
           reportData['result'].toString().isEmpty || 
           reportData['result'] == 'N/A' ||
           reportData['result'] == 'Análisis pendiente')) {
        
        // Primero intentar obtener del provider
        try {
          final provider = Provider.of<ColonoscopyAnalysisData>(context, listen: false);
          if (provider.hasAnalysis && provider.analysis != null) {
            final analysis = provider.analysis!;
            // Buscar el reporte más reciente del historial para obtener confidence y riskLevel reales
            Map<String, dynamic>? latestReport;
            if (_previousReports.isNotEmpty) {
              final sortedReports = List<Map<String, dynamic>>.from(_previousReports)
                ..sort((a, b) {
                  final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
                  final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
                  return dateB.compareTo(dateA);
                });
              
              for (var report in sortedReports) {
                if (report['result'] == analysis.result) {
                  latestReport = report;
                  break;
                }
              }
            }
            
            reportData['result'] = analysis.result;
            reportData['stage'] = analysis.currentStage;
            reportData['confidence'] = latestReport != null 
                ? _getConfidenceValue(latestReport['confidence'] ?? 0.85)
                : 0.85; // Valor por defecto si no se encuentra
            reportData['riskLevel'] = latestReport != null 
                ? (latestReport['riskLevel'] ?? latestReport['risk_level'] ?? _determineRiskLevel(analysis.result))
                : _determineRiskLevel(analysis.result);
            print('✅ Datos del análisis obtenidos del provider: ${reportData['result']}');
            print('   - Confianza: ${reportData['confidence']}');
            print('   - Nivel de riesgo: ${reportData['riskLevel']}');
          }
        } catch (e) {
          print('⚠️ No se pudo obtener análisis del provider: $e');
        }
        
        // Si aún no hay datos válidos, buscar en el historial
        if ((reportData['result'] == null || 
             reportData['result'].toString().isEmpty || 
             reportData['result'] == 'N/A' ||
             reportData['result'] == 'Análisis pendiente') &&
            _previousReports.isNotEmpty) {
          // Buscar el análisis más reciente con datos válidos
          final sortedReports = List<Map<String, dynamic>>.from(_previousReports)
            ..sort((a, b) {
              final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
              final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
              return dateB.compareTo(dateA);
            });
          
          for (var report in sortedReports) {
            final result = report['result'];
            if (result != null && 
                result.toString().isNotEmpty && 
                result != 'Análisis pendiente' &&
                result != 'N/A' &&
                result != 'No hay análisis disponible') {
              // Usar este reporte como fuente de datos
              reportData['result'] = report['result'];
              reportData['stage'] = report['stage'] ?? reportData['stage'];
              reportData['confidence'] = _getConfidenceValue(report['confidence'] ?? reportData['confidence'] ?? 0.0);
              reportData['riskLevel'] = report['riskLevel'] ?? report['risk_level'] ?? reportData['riskLevel'];
              print('✅ Datos del análisis obtenidos del historial: ${reportData['result']}');
              break;
            }
          }
        }
      }
      
      // Agregar información adicional para el reporte
      reportData['title'] = 'Reporte de Colonoscopia - ${_dateController.text}';
      reportData['date'] = _dateController.text;
      reportData['status'] = 'Completado';
      
      // Normalizar riskLevel si viene del backend
      if (reportData['risk_level'] != null && reportData['riskLevel'] == null) {
        reportData['riskLevel'] = reportData['risk_level'];
      }
      
      // Generar recomendaciones médicas con los datos correctos
      final result = reportData['result'] ?? 'N/A';
      final stage = reportData['stage'] ?? 'N/A';
      final riskLevel = reportData['riskLevel'] ?? reportData['risk_level'] ?? 'N/A';
      final confidence = _getConfidenceValue(reportData['confidence'] ?? 0.0);
      
      // Debug: imprimir datos que se usarán para el reporte
      print('📊 Datos del análisis para el reporte:');
      print('   - Resultado: $result');
      print('   - Etapa: $stage');
      print('   - Confianza: $confidence');
      print('   - Nivel de riesgo: $riskLevel');
      print('📋 reportData completo antes de generar PDF:');
      print('   - reportData keys: ${reportData.keys.toList()}');
      print('   - reportData[result]: ${reportData['result']}');
      print('   - reportData[stage]: ${reportData['stage']}');
      print('   - reportData[confidence]: ${reportData['confidence']}');
      print('   - reportData[riskLevel]: ${reportData['riskLevel']}');
      
      // Asegurar que los datos estén presentes (no null ni vacíos)
      if (reportData['result'] == null || reportData['result'].toString().isEmpty) {
        print('⚠️ ADVERTENCIA: reportData[result] está vacío o es null');
        // Intentar obtener del provider como último recurso
        try {
          final provider = Provider.of<ColonoscopyAnalysisData>(context, listen: false);
          if (provider.hasAnalysis && provider.analysis != null) {
            reportData['result'] = provider.analysis!.result;
            reportData['stage'] = provider.analysis!.currentStage;
            print('✅ Datos obtenidos del provider como último recurso: ${reportData['result']}');
          }
        } catch (e) {
          print('❌ Error obteniendo datos del provider: $e');
        }
      }
      
      // Solo generar recomendaciones si tenemos datos válidos
      if (result != 'N/A' && result != 'Análisis pendiente' && result != 'No hay análisis disponible') {
        reportData['recommendation'] = MedicalRecommendationsService.generateRecommendations(
          result: result,
          stage: stage,
          riskLevel: riskLevel,
          confidence: confidence,
        );
        
        reportData['clinicalInterpretation'] = MedicalRecommendationsService.generateClinicalInterpretation(
          result: result,
          stage: stage,
          riskLevel: riskLevel,
          confidence: confidence,
        );
        
        reportData['followUpPlan'] = MedicalRecommendationsService.generateFollowUpPlan(
          result: result,
          riskLevel: riskLevel,
        );
      }
      
      return reportData;
    }

    // Si no hay análisis previo, intentar obtener del provider o historial general
    print('⚠️ No se encontró análisis asociado al paciente, buscando en provider/historial...');
    
    // Intentar obtener del provider
    try {
      final provider = Provider.of<ColonoscopyAnalysisData>(context, listen: false);
      if (provider.hasAnalysis && provider.analysis != null) {
        final analysis = provider.analysis!;
        
        // Buscar confidence y riskLevel del historial más reciente
        double confidence = 0.85;
        String riskLevel = _determineRiskLevel(analysis.result);
        
        if (_previousReports.isNotEmpty) {
          final sortedReports = List<Map<String, dynamic>>.from(_previousReports)
            ..sort((a, b) {
              final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
              final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
              return dateB.compareTo(dateA);
            });
          
          for (var report in sortedReports) {
            if (report['result'] == analysis.result) {
              confidence = _getConfidenceValue(report['confidence'] ?? 0.85);
              riskLevel = report['riskLevel'] ?? report['risk_level'] ?? riskLevel;
              break;
            }
          }
        }
        
        print('✅ Análisis encontrado en provider: ${analysis.result}');
    return {
      'id': 'report_${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Reporte de Colonoscopia - ${_dateController.text}',
      'date': _dateController.text,
      'status': 'Completado',
          'result': analysis.result,
          'stage': analysis.currentStage,
          'confidence': confidence,
          'riskLevel': riskLevel,
          'createdAt': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      print('⚠️ Error obteniendo análisis del provider: $e');
    }
    
    // Si aún no hay, buscar en historial general
    if (_previousReports.isNotEmpty) {
      final sortedReports = List<Map<String, dynamic>>.from(_previousReports)
        ..sort((a, b) {
          final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
      
      for (var report in sortedReports) {
        final result = report['result'];
        if (result != null && 
            result.toString().isNotEmpty && 
            result != 'Análisis pendiente' &&
            result != 'N/A' &&
            result != 'No hay análisis disponible') {
          print('✅ Análisis encontrado en historial general: $result');
          return {
            'id': report['id'] ?? 'report_${DateTime.now().millisecondsSinceEpoch}',
            'title': 'Reporte de Colonoscopia - ${_dateController.text}',
            'date': _dateController.text,
            'status': 'Completado',
            'result': report['result'],
            'stage': report['stage'] ?? 'N/A',
            'confidence': _getConfidenceValue(report['confidence'] ?? 0.0),
            'riskLevel': report['riskLevel'] ?? report['risk_level'] ?? 'N/A',
            'createdAt': report['createdAt'] ?? DateTime.now().toIso8601String(),
          };
        }
      }
    }
    
    // Si no hay análisis disponible, crear un reporte básico con advertencia
    print('❌ No se encontró ningún análisis disponible');
    return {
      'id': 'report_${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Reporte de Colonoscopia - ${_dateController.text}',
      'date': _dateController.text,
      'status': 'Pendiente',
      'result': 'No hay análisis disponible',
      'stage': 'Se requiere análisis de imagen previo',
      'confidence': 0.0,
      'riskLevel': 'No determinado',
      'createdAt': DateTime.now().toIso8601String(),
      'warning': 'Este reporte se generó sin un análisis de imagen previo. Se recomienda realizar un análisis antes de generar el reporte.',
    };
  }
  
  /// Obtiene el reporte más reciente del paciente seleccionado
  Future<Map<String, dynamic>?> _getMostRecentReportForPatient() async {
    if (_selectedPatient == null) return null;
    
    final patientId = _selectedPatient!['id'];
    
    if (patientId == null) {
      print('⚠️ No se encontró ID del paciente');
      return null;
    }
    
    try {
      // Buscar estudios del paciente en el backend
      print('🔍 Buscando estudios del paciente ID: $patientId');
      final response = await _studyService.getAllStudies(patientId: patientId);
      
      if (response.success && response.data != null && response.data!.isNotEmpty) {
        // Ordenar por fecha (más reciente primero)
        final studies = response.data!;
        studies.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at'] ?? a['createdAt'] ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['created_at'] ?? b['createdAt'] ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
        
        // Convertir estudio del backend al formato de reporte
        final mostRecentStudy = studies.first;
        final createdAt = mostRecentStudy['created_at'] ?? mostRecentStudy['createdAt'] ?? DateTime.now().toIso8601String();
        final dateStr = createdAt.toString().split('T')[0];
        final dateParts = dateStr.split('-');
        final day = int.tryParse(dateParts[2]) ?? DateTime.now().day;
        final month = int.tryParse(dateParts[1]) ?? DateTime.now().month;
        final year = int.tryParse(dateParts[0]) ?? DateTime.now().year;
        
        // Normalizar datos del backend al formato del frontend
        final normalizedStudy = {
          'id': 'backend_${mostRecentStudy['id']}',
          'backendId': mostRecentStudy['id'],
          'title': 'Reporte de Colonoscopia - $day/$month/$year',
          'date': dateStr,
          'status': 'Completado',
          'result': mostRecentStudy['result'] ?? 'N/A',
          'stage': mostRecentStudy['stage'] ?? 'N/A',
          'confidence': mostRecentStudy['confidence'] != null 
              ? (mostRecentStudy['confidence'] is double 
                  ? mostRecentStudy['confidence'] 
                  : double.tryParse(mostRecentStudy['confidence'].toString()) ?? 0.0) 
              : 0.0,
          'riskLevel': mostRecentStudy['risk_level'] ?? mostRecentStudy['riskLevel'] ?? 'N/A',
          'risk_level': mostRecentStudy['risk_level'] ?? mostRecentStudy['riskLevel'] ?? 'N/A', // Mantener ambos para compatibilidad
          'createdAt': createdAt,
          'backendCreatedAt': createdAt,
        };
        
        print('✅ Estudio obtenido del backend:');
        print('   - Resultado: ${normalizedStudy['result']}');
        print('   - Etapa: ${normalizedStudy['stage']}');
        print('   - Confianza: ${normalizedStudy['confidence']}');
        print('   - Nivel de riesgo: ${normalizedStudy['riskLevel']}');
        
        return normalizedStudy;
      }
      
      // Si no hay estudios en el backend, buscar en el historial local
      print('⚠️ No se encontraron estudios en el backend, buscando en historial local...');
      if (_previousReports.isEmpty) return null;
      
      // Ordenar por fecha (más reciente primero)
      final sortedReports = List<Map<String, dynamic>>.from(_previousReports)
        ..sort((a, b) {
          final dateA = DateTime.tryParse(a['createdAt'] ?? a['date'] ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['createdAt'] ?? b['date'] ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
      
      // Retornar el más reciente que tenga datos válidos
      for (var report in sortedReports) {
        final result = report['result'];
        if (result != null && result.toString().isNotEmpty && result != 'Análisis pendiente') {
          return report;
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error obteniendo estudios del paciente: $e');
      return null;
    }
  }
  
  /// Asocia el análisis más reciente con el paciente recién creado
  Future<void> _associateAnalysisWithPatient(
    int patientId,
    String studyDate,
    String doctorName,
    String observations,
  ) async {
    try {
      // Obtener el análisis más reciente del provider o del historial
      Map<String, dynamic>? analysisData;
      
      // Intentar obtener del provider primero
      try {
        final provider = Provider.of<ColonoscopyAnalysisData>(context, listen: false);
        if (provider.hasAnalysis && provider.analysis != null) {
          final analysis = provider.analysis!;
          analysisData = {
            'result': analysis.result,
            'stage': analysis.currentStage,
            'confidence': 0.85,
            'riskLevel': _determineRiskLevel(analysis.result),
          };
          print('✅ Análisis obtenido del provider');
        }
      } catch (e) {
        print('⚠️ No se pudo obtener análisis del provider: $e');
      }
      
      // Si no hay en el provider, obtener el más reciente del historial
      if (analysisData == null && _previousReports.isNotEmpty) {
        final sortedReports = List<Map<String, dynamic>>.from(_previousReports)
          ..sort((a, b) {
            final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
            final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
            return dateB.compareTo(dateA);
          });
        
        final mostRecent = sortedReports.firstWhere(
          (r) => r['result'] != null && 
                 r['result'].toString().isNotEmpty && 
                 r['result'] != 'Análisis pendiente',
          orElse: () => {},
        );
        
        if (mostRecent.isNotEmpty) {
          analysisData = {
            'result': mostRecent['result'] ?? 'N/A',
            'stage': mostRecent['stage'] ?? 'N/A',
            'confidence': _getConfidenceValue(mostRecent['confidence'] ?? 0.0),
            'riskLevel': mostRecent['riskLevel'] ?? mostRecent['risk_level'] ?? 'N/A',
          };
          print('✅ Análisis obtenido del historial local');
        }
      }
      
      // NOTA: El guardado del reporte ya se hace en _handleGenerateReport() mediante ReportService.addReport()
      // que internamente llama a createStudy en el backend. No necesitamos duplicar aquí.
    } catch (e, stackTrace) {
      print('❌ Error asociando análisis con paciente: $e');
      print('❌ Stack trace: $stackTrace');
      // No mostrar error al usuario, solo log
    }
  }
  
  /// Obtiene el valor de confianza de forma segura
  double _getConfidenceValue(dynamic confidence) {
    if (confidence == null) return 0.0;
    if (confidence is double) return confidence;
    if (confidence is int) return confidence.toDouble();
    if (confidence is String) return double.tryParse(confidence) ?? 0.0;
    return 0.0;
  }
}
