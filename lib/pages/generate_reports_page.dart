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
  List<Map<String, dynamic>> _previousReports = [];
  bool _isLoadingReports = false;
  
  // Gestión de pacientes
  final PatientService _patientService = PatientService();
  List<Map<String, dynamic>> _patients = [];
  Map<String, dynamic>? _selectedPatient;
  bool _isLoadingPatients = false;
  bool _isCreatingPatient = false;
  final _searchPatientController = TextEditingController();

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
    final patientId = _selectedPatient!['identification'] ?? 
                     _selectedPatient!['identificacion'] ?? 
                     'N/A';
    final patientAge = _selectedPatient!['age'];
    
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
                Row(
                  children: [
                    Text(
                      'ID: $patientId',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (patientAge != null) ...[
                      const Text(
                        ' | ',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Edad: $patientAge años',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
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
                    label: 'Nombre Completo',
                    controller: nameController,
                    hint: 'Ingrese el nombre completo',
                    validator: (value) => Validators.validateRequired(value, 'Nombre completo'),
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                  CustomTextField(
                    label: 'Identificación',
                    controller: idController,
                    hint: 'Ingrese el número de identificación',
                    validator: (value) => Validators.validateRequired(value, 'Identificación'),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                  CustomTextField(
                    label: 'Edad (Opcional)',
                    controller: ageController,
                    hint: 'Ingrese la edad',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final age = int.tryParse(value);
                        if (age == null || age < 0 || age > 150) {
                          return 'Ingrese una edad válida (0-150)';
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
        await _loadPatients();
        if (mounted) {
          context.showSuccessSnackBar('Paciente registrado exitosamente');
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
                        description: 'Análisis básico de la imagen',
                        icon: Icons.description,
                        reportType: 'básico',
                        isSelected: _selectedReportType == 'básico',
                      ),
                      const Divider(),
                      _buildReportOption(
                        title: 'Reporte Detallado',
                        description: 'Análisis completo con recomendaciones',
                        icon: Icons.analytics,
                        reportType: 'detallado',
                        isSelected: _selectedReportType == 'detallado',
                      ),
                      const Divider(),
                      _buildReportOption(
                        title: 'Reporte Comparativo',
                        description: 'Comparación con estudios anteriores',
                        icon: Icons.compare,
                        reportType: 'comparativo',
                        isSelected: _selectedReportType == 'comparativo',
                      ),
                      // Mostrar selector de reporte previo si es comparativo
                      if (_selectedReportType == 'comparativo') ...[
                        const SizedBox(height: AppDimensions.spacingL),
                        const Divider(),
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
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryBlue),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _selectedPreviousReport,
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
                child: Text('Seleccione un reporte previo'),
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
                        ),
                        Text(
                          'Fecha: ${report['date'] ?? 'N/A'} | Resultado: ${report['result'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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
    if (_selectedReportType == 'comparativo' && _selectedPreviousReport == null) {
      context.showErrorSnackBar('Por favor seleccione un reporte previo para comparar');
      return;
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
      final patientId = _selectedPatient!['identification'] ?? 
                       _selectedPatient!['identificacion'] ?? 
                       'N/A';
      final patientAge = _selectedPatient!['age']?.toString() ?? '';

      // Preparar datos del reporte
      final reportData = _buildReportData();

      // Generar PDF según el tipo de reporte
      final success = await PDFService.generateAndDownloadReport(
        reportData,
        reportType: _selectedReportType!,
        patientName: patientName,
        patientId: patientId,
        patientAge: patientAge,
        studyDate: _dateController.text,
        doctorName: _doctorController.text,
        observations: _observationsController.text.isNotEmpty 
            ? _observationsController.text 
            : null,
        previousReport: _selectedPreviousReport,
      );

      if (success) {
        // Guardar el reporte en el historial
        await ReportService.addReport(
          result: reportData['result'] ?? 'N/A',
          stage: reportData['stage'] ?? 'N/A',
          confidence: reportData['confidence'] ?? 0.0,
          riskLevel: reportData['riskLevel'] ?? 'N/A',
        );

        if (mounted) {
          context.showSuccessSnackBar('Reporte generado y descargado correctamente');
          // Limpiar formulario
          _dateController.clear();
          _doctorController.clear();
          _observationsController.clear();
          setState(() {
            _selectedReportType = null;
            _selectedPreviousReport = null;
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

  Map<String, dynamic> _buildReportData() {
    // Si es comparativo y hay reporte previo, usar esos datos
    if (_selectedReportType == 'comparativo' && _selectedPreviousReport != null) {
      return Map<String, dynamic>.from(_selectedPreviousReport!);
    }

    // Si no hay reporte previo seleccionado, crear datos básicos
    // En un caso real, estos datos vendrían de un análisis reciente
    return {
      'id': 'report_${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Reporte de Colonoscopia - ${_dateController.text}',
      'date': _dateController.text,
      'status': 'Completado',
      'result': 'Análisis pendiente',
      'stage': 'Pendiente de análisis',
      'confidence': 0.0,
      'riskLevel': 'Desconocido',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
