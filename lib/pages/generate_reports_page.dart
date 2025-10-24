import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/extensions.dart';

class GenerateReportsPage extends StatefulWidget {
  const GenerateReportsPage({super.key});

  @override
  State<GenerateReportsPage> createState() => _GenerateReportsPageState();
}

class _GenerateReportsPageState extends State<GenerateReportsPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientIdController = TextEditingController();
  final _dateController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientIdController.dispose();
    _dateController.dispose();
    super.dispose();
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
                      CustomTextField(
                        label: 'Nombre del Paciente',
                        controller: _patientNameController,
                        hint: 'Ingrese el nombre completo',
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      CustomTextField(
                        label: 'ID del Paciente',
                        controller: _patientIdController,
                        hint: 'Ingrese el ID del paciente',
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      CustomTextField(
                        label: 'Fecha del Estudio',
                        controller: _dateController,
                        hint: 'DD/MM/AAAA',
                        onTap: () => _selectDate(),
                      ),
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
                        onTap: () => _generateReport('básico'),
                      ),
                      const Divider(),
                      _buildReportOption(
                        title: 'Reporte Detallado',
                        description: 'Análisis completo con recomendaciones',
                        icon: Icons.analytics,
                        onTap: () => _generateReport('detallado'),
                      ),
                      const Divider(),
                      _buildReportOption(
                        title: 'Reporte Comparativo',
                        description: 'Comparación con estudios anteriores',
                        icon: Icons.compare,
                        onTap: () => _generateReport('comparativo'),
                      ),
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
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeM,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary),
      onTap: onTap,
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

  void _generateReport(String type) {
    // Lógica para seleccionar tipo de reporte
    context.showInfoSnackBar('Tipo de reporte seleccionado: $type');
  }

  void _handleGenerateReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    // Simular generación de reporte
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isGenerating = false;
    });

    context.showSuccessSnackBar('Reporte generado correctamente');
    
    // Navegar de vuelta
    context.pop();
  }
}
