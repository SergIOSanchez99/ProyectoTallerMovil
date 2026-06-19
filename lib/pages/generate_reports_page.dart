import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/extensions.dart';
import '../services/report_service.dart';
import '../services/pdf_service.dart';
import '../pages/upload_image_page.dart'; // ColonoscopyAnalysisData

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
  String _selectedReportType = 'detallado';
  bool _isGenerating = false;

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientIdController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final analysisData = context.watch<ColonoscopyAnalysisData>();
    final hasAnalysis = analysisData.hasAnalysis;

    return Scaffold(
      backgroundColor: AppColors.veryLightBlue,
      appBar: AppBar(
        title: const Text('Generar Reporte'),
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
                        // Banner de estado del análisis
                        _buildAnalysisBanner(analysisData),
                        const SizedBox(height: AppDimensions.spacingL),

                        // Datos del paciente
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
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Campo requerido'
                                    : null,
                              ),
                              const SizedBox(height: AppDimensions.spacingL),
                              CustomTextField(
                                label: 'ID del Paciente',
                                controller: _patientIdController,
                                hint: 'Ingrese el ID del paciente',
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Campo requerido'
                                    : null,
                              ),
                              const SizedBox(height: AppDimensions.spacingL),
                              CustomTextField(
                                label: 'Fecha del Estudio',
                                controller: _dateController,
                                hint: 'DD/MM/AAAA',
                                onTap: () => _selectDate(),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Selecciona una fecha'
                                    : null,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppDimensions.spacingL),

                        // Tipo de reporte
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
                              const SizedBox(height: AppDimensions.spacingM),
                              _buildReportOption(
                                title: 'Reporte Básico',
                                description: 'Resultado, etapa y fecha',
                                icon: Icons.description,
                                value: 'básico',
                              ),
                              const Divider(),
                              _buildReportOption(
                                title: 'Reporte Detallado',
                                description:
                                    'Análisis completo con imagen y recomendaciones',
                                icon: Icons.analytics,
                                value: 'detallado',
                              ),
                              const Divider(),
                              _buildReportOption(
                                title: 'Reporte Comparativo',
                                description:
                                    'Comparación con estudios anteriores',
                                icon: Icons.compare,
                                value: 'comparativo',
                              ),
                            ],
                          ),
                        ),

                        // Resumen del análisis disponible
                        if (hasAnalysis) ...[
                          const SizedBox(height: AppDimensions.spacingL),
                          _buildAnalysisSummary(analysisData),
                        ],
                      ],
                    ),
                  ),
                ),

                // Botón generar
                CustomButton(
                  text: hasAnalysis
                      ? 'Generar y Descargar PDF'
                      : 'Primero sube una imagen',
                  onPressed: hasAnalysis ? _handleGenerateReport : null,
                  isLoading: _isGenerating,
                  icon: Icons.picture_as_pdf,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Widgets auxiliares ───────────────────────────────────────────────────

  Widget _buildAnalysisBanner(ColonoscopyAnalysisData data) {
    if (data.hasAnalysis) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Análisis disponible: ${data.analysis?.result ?? ''}',
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No hay análisis activo. Ve a "Adjuntar" y sube una imagen primero.',
              style: TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSummary(ColonoscopyAnalysisData data) {
    final analysis = data.analysis!;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del análisis',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _summaryRow('Resultado', analysis.result),
          _summaryRow('Etapa', analysis.currentStage),
          _summaryRow('Riesgo', analysis.riskLevel),
          _summaryRow(
              'Confianza',
              '${(analysis.confidence * 100).toStringAsFixed(1)}%'),
          if (analysis.imageBytes != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                analysis.imageBytes!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    fontSize: AppDimensions.fontSizeM)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppDimensions.fontSizeM)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption({
    required String title,
    required String description,
    required IconData icon,
    required String value,
  }) {
    final selected = _selectedReportType == value;
    return ListTile(
      leading: Icon(icon,
          color:
              selected ? AppColors.primaryBlue : AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? AppColors.primaryBlue : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeM,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.radio_button_checked,
              color: AppColors.primaryBlue)
          : const Icon(Icons.radio_button_unchecked,
              color: AppColors.textSecondary),
      onTap: () => setState(() => _selectedReportType = value),
    );
  }

  // ─── Acciones ─────────────────────────────────────────────────────────────

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dateController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  void _handleGenerateReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);

    try {
      final analysisData =
          Provider.of<ColonoscopyAnalysisData>(context, listen: false);

      if (!analysisData.hasAnalysis) {
        context.showErrorSnackBar('No hay análisis disponible');
        return;
      }

      final analysis = analysisData.analysis!;

      // Convertir imagen a base64 si existe
      String? imageBase64;
      if (analysis.imageBytes != null) {
        imageBase64 = base64Encode(analysis.imageBytes!);
      }

      // Construir datos del reporte
      final reportData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title':
            'Reporte ${_selectedReportType.toUpperCase()} - ${_patientNameController.text.trim()}',
        'date': _dateController.text.trim(),
        'status': 'Completado',
        'result': analysis.result,
        'stage': analysis.currentStage,
        'confidence': analysis.confidence,
        'riskLevel': analysis.riskLevel,
        'patientName': _patientNameController.text.trim(),
        'patientId': _patientIdController.text.trim(),
        if (imageBase64 != null) 'imageBase64': imageBase64,
      };

      // Generar PDF
      final pdfSuccess =
          await PDFService.generateAndDownloadReport(reportData);

      if (pdfSuccess) {
        // Guardar en historial
        await ReportService.addReport(
          result: analysis.result,
          stage: analysis.currentStage,
          confidence: analysis.confidence,
          riskLevel: analysis.riskLevel,
          imageBase64: imageBase64,
          patientName: _patientNameController.text.trim(),
          patientId: _patientIdController.text.trim(),
        );

        context.showSuccessSnackBar(
            '✅ Reporte generado y guardado en historial');
        context.pop();
      } else {
        context.showErrorSnackBar('Error al generar el PDF');
      }
    } catch (e) {
      context.showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }
}
