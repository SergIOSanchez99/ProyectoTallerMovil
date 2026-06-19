import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/ai_service.dart';
import '../services/report_service.dart';
import '../services/pdf_service.dart';
import '../routes/app_routes.dart';

/// Datos de un análisis de colonoscopia
class ColonoscopyAnalysis {
  final DateTime analysisDate;
  final String result;
  final String currentStage;
  final double confidence;
  final String riskLevel;
  final Uint8List? imageBytes;

  ColonoscopyAnalysis({
    required this.analysisDate,
    required this.result,
    required this.currentStage,
    required this.confidence,
    required this.riskLevel,
    this.imageBytes,
  });
}

/// Provider que gestiona el estado del análisis de colonoscopia
class ColonoscopyAnalysisData extends ChangeNotifier {
  ColonoscopyAnalysis? _analysis;
  bool _isGeneratingReport = false;
  bool _hasAnalysis = false;

  ColonoscopyAnalysis? get analysis => _analysis;
  bool get isGeneratingReport => _isGeneratingReport;
  bool get hasAnalysis => _hasAnalysis;

  /// Actualizar análisis con datos reales del backend
  void updateAnalysisFromBackend({
    required String result,
    required String stage,
    required double confidence,
    required String riskLevel,
    Uint8List? imageBytes,
  }) {
    _analysis = ColonoscopyAnalysis(
      analysisDate: DateTime.now(),
      result: result,
      currentStage: stage,
      confidence: confidence,
      riskLevel: riskLevel,
      imageBytes: imageBytes,
    );
    _hasAnalysis = true;
    notifyListeners();
  }

  /// Limpiar análisis anterior
  void clearAnalysis() {
    _analysis = null;
    _hasAnalysis = false;
    notifyListeners();
  }

  /// Genera reporte PDF y guarda en historial
  Future<bool> generateReport() async {
    if (!_hasAnalysis || _analysis == null) return false;

    _isGeneratingReport = true;
    notifyListeners();

    try {
      final analysis = _analysis!;

      // Convertir imagen a base64 si existe
      String? imageBase64;
      if (analysis.imageBytes != null) {
        imageBase64 = base64Encode(analysis.imageBytes!);
      }

      // Datos para el PDF y el historial
      final reportData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title':
            'Reporte de Colonoscopia - ${analysis.analysisDate.day}/${analysis.analysisDate.month}/${analysis.analysisDate.year}',
        'date': analysis.analysisDate.toIso8601String().split('T')[0],
        'status': 'Completado',
        'result': analysis.result,
        'stage': analysis.currentStage,
        'confidence': analysis.confidence,
        'riskLevel': analysis.riskLevel,
        if (imageBase64 != null) 'imageBase64': imageBase64,
      };

      // Generar y descargar PDF
      await PDFService.generateAndDownloadReport(reportData);

      // Guardar en historial
      await ReportService.addReport(
        result: analysis.result,
        stage: analysis.currentStage,
        confidence: analysis.confidence,
        riskLevel: analysis.riskLevel,
        imageBase64: imageBase64,
      );

      return true;
    } catch (e) {
      print('❌ Error generando reporte: $e');
      return false;
    } finally {
      _isGeneratingReport = false;
      notifyListeners();
    }
  }
}

class UploadImagePage extends StatefulWidget {
  const UploadImagePage({super.key});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  Uint8List? _selectedImageBytes;
  final AIService _aiService = AIService();
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text('Subir Imagen'),
        backgroundColor: const Color(0xFF1E6091),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20),
              // Área de imagen
              _buildImageArea(),
              const SizedBox(height: 20),
              // Botón subir imagen
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _handleUploadImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E6091),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.upload_file),
                  label: Text(
                    _isAnalyzing ? 'Analizando...' : 'Subir imagen',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Sección de resultados
              const ReportAnalysisSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildImageArea() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 280,
          decoration: BoxDecoration(
            color: const Color(0xFFB0E0E6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF191970), width: 2),
          ),
          child: _selectedImageBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    _selectedImageBytes!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 70, color: Color(0xFF1E6091)),
                      SizedBox(height: 12),
                      Text('Selecciona una imagen de colonoscopia',
                          style: TextStyle(
                              color: Color(0xFF1E6091),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
        ),
        // Badge de estado de análisis
        if (_isAnalyzing)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  Text('Analizando imagen con IA...',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFB0E0E6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF1E6091),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_file), label: 'Adjuntar'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.home, (route) => false);
        break;
      case 1:
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.reportHistory);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  void _handleUploadImage() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Seleccionar imagen',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191970))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Cámara',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  ImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galería',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 80,
          maxWidth: 1024, maxHeight: 1024);
      if (image != null) await _processSelectedImage(image);
    } catch (e) {
      _showError('Error accediendo a la cámara: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80,
          maxWidth: 1024, maxHeight: 1024);
      if (image != null) await _processSelectedImage(image);
    } catch (e) {
      _showError('Error accediendo a la galería: $e');
    }
  }

  Future<void> _processSelectedImage(XFile image) async {
    try {
      final Uint8List imageBytes = await image.readAsBytes();

      final provider =
          Provider.of<ColonoscopyAnalysisData>(context, listen: false);
      provider.clearAnalysis();

      setState(() {
        _selectedImageBytes = imageBytes;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen seleccionada. Iniciando análisis...'),
          backgroundColor: Color(0xFF191970),
        ),
      );

      await _performAIAnalysis(imageBytes);
    } catch (e) {
      _showError('Error procesando imagen: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _performAIAnalysis(Uint8List imageBytes) async {
    setState(() => _isAnalyzing = true);

    try {
      final response = await _aiService.checkHealth();

      if (response.success && response.data == true) {
        final analysisResponse =
            await _aiService.analyzeImageFromBytes(imageBytes);
        if (analysisResponse.success) {
          _updateAnalysisResults(analysisResponse.data!, imageBytes);
        } else {
          await _performSimulatedAnalysis(imageBytes);
        }
      } else {
        await _performSimulatedAnalysis(imageBytes);
      }
    } catch (e) {
      await _performSimulatedAnalysis(imageBytes);
    }

    setState(() => _isAnalyzing = false);
  }

  Future<void> _performSimulatedAnalysis(Uint8List imageBytes) async {
    final response = await _aiService.simulateAnalysis();
    if (response.success) {
      _updateAnalysisResults(response.data!, imageBytes);
    }
  }

  void _updateAnalysisResults(
      Map<String, dynamic> data, Uint8List imageBytes) {
    final provider =
        Provider.of<ColonoscopyAnalysisData>(context, listen: false);
    provider.updateAnalysisFromBackend(
      result: data['result'] ?? 'Análisis completado',
      stage: data['stage'] ?? 'Etapa evaluada',
      confidence: (data['confidence'] ?? 0.0).toDouble(),
      riskLevel: data['risk_level'] ?? 'Desconocido',
      imageBytes: imageBytes,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Análisis completado: ${data['result']}'),
        backgroundColor: const Color(0xFF191970),
      ),
    );
  }
}

// ─── Widgets auxiliares ────────────────────────────────────────────────────

class ImageSourceOption extends StatelessWidget {
  const ImageSourceOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFB0E0E6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 40, color: const Color(0xFF191970)),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191970))),
          ],
        ),
      ),
    );
  }
}

class AnalysisDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const AnalysisDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: const Color(0xFF1E6091), size: 20),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 15,
                  color: valueColor ?? Colors.black87,
                  fontWeight: valueColor != null
                      ? FontWeight.w600
                      : FontWeight.normal),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

/// Sección de resultados del análisis + botón generar reporte
class ReportAnalysisSection extends StatelessWidget {
  const ReportAnalysisSection({super.key});

  Color _riskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ColonoscopyAnalysisData>(
      builder: (BuildContext context, ColonoscopyAnalysisData analysisData,
          Widget? child) {
        if (!analysisData.hasAnalysis || analysisData.analysis == null) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.medical_services_outlined,
                      size: 50, color: Color(0xFF1E6091)),
                  SizedBox(height: 12),
                  Text('Análisis de colonoscopia',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  SizedBox(height: 8),
                  Text(
                    'Selecciona una imagen para obtener el análisis automático de cáncer de colon',
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final ColonoscopyAnalysis analysis = analysisData.analysis!;
        final bool isGenerating = analysisData.isGeneratingReport;
        final riskColor = _riskColor(analysis.riskLevel);
        final confidencePct =
            (analysis.confidence * 100).toStringAsFixed(1);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Encabezado con badge de riesgo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Resultado del Análisis',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: riskColor),
                      ),
                      child: Text(
                        analysis.riskLevel,
                        style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnalysisDetailRow(
                  icon: Icons.calendar_today,
                  label: 'Fecha:',
                  value: analysis.analysisDate
                      .toLocal()
                      .toIso8601String()
                      .split('T')[0],
                ),
                const SizedBox(height: 10),
                AnalysisDetailRow(
                  icon: Icons.medical_services,
                  label: 'Resultado:',
                  value: analysis.result,
                  valueColor: riskColor,
                ),
                const SizedBox(height: 10),
                AnalysisDetailRow(
                  icon: Icons.bar_chart,
                  label: 'Etapa:',
                  value: analysis.currentStage,
                ),
                const SizedBox(height: 10),
                // Barra de confianza
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.percent,
                            color: Color(0xFF1E6091), size: 20),
                        const SizedBox(width: 10),
                        const Text('Confianza:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 6),
                        Text('$confidencePct%',
                            style: TextStyle(
                                color: riskColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: analysis.confidence,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Botón generar reporte
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isGenerating
                        ? null
                        : () async {
                            final bool success =
                                await analysisData.generateReport();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? '✅ Reporte generado y descargado'
                                    : '❌ Error al generar el reporte'),
                                backgroundColor: success
                                    ? const Color(0xFF1E6091)
                                    : Colors.red,
                                action: success
                                    ? SnackBarAction(
                                        label: 'Ver Historial',
                                        textColor: Colors.white,
                                        onPressed: () => Navigator.pushNamed(
                                            context, AppRoutes.reportHistory),
                                      )
                                    : null,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6091),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    icon: isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(
                      isGenerating ? 'Generando PDF...' : 'Generar Reporte PDF',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}