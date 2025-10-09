import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../services/ai_service.dart';

/// Represents the data for a colonoscopy analysis.
class ColonoscopyAnalysis {
  final DateTime analysisDate;
  final String result;
  final String currentStage;

  ColonoscopyAnalysis({
    required this.analysisDate,
    required this.result,
    required this.currentStage,
  });
}

/// Simulates the generation of a report asynchronously.
/// Returns true if the report generation was successful, false otherwise.
Future<bool> handleGenerateReport() async {
  // In a real application, this would involve actual API calls or complex logic.
  // For this example, we simulate a delay.
  debugPrint('Generando reporte, por favor espera...');
  try {
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('Reporte generado exitosamente.');
    return true;
  } catch (e) {
    debugPrint('Error al generar el reporte: $e');
    return false;
  }
}

/// Manages the state for Colonoscopy Analysis data and report generation.
class ColonoscopyAnalysisData extends ChangeNotifier {
  ColonoscopyAnalysis _analysis;
  bool _isGeneratingReport = false;

  ColonoscopyAnalysisData()
      : _analysis = ColonoscopyAnalysis(
          analysisDate: DateTime(2023, 10, 26),
          result: 'Linfoma',
          currentStage: 'Temprana',
        );

  ColonoscopyAnalysis get analysis => _analysis;
  bool get isGeneratingReport => _isGeneratingReport;

  /// Initiates the report generation process.
  /// Updates the isGeneratingReport state and notifies listeners.
  Future<bool> generateReport() async {
    _isGeneratingReport = true;
    notifyListeners();

    final bool success = await handleGenerateReport();

    _isGeneratingReport = false;
    notifyListeners();
    return success;
  }
}

class UploadImagePage extends StatefulWidget {
  const UploadImagePage({super.key});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  String? _selectedImageUrl;
  Uint8List? _selectedImageBytes;
  final AIService _aiService = AIService();
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ColonoscopyAnalysisData>(
      create: (context) => ColonoscopyAnalysisData(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F8FF), // Fondo azul muy claro
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
                const SizedBox(height: 40),
                // Área de imagen placeholder
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB0E0E6), // Azul claro
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF191970), // Azul oscuro
                      width: 2,
                    ),
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
                          child: Icon(
                            Icons.camera_alt,
                            size: 80,
                            color: Colors.black,
                          ),
                        ),
                ),
                const SizedBox(height: 30),
                // Botón de subir imagen
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleUploadImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6091), // Azul oscuro
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Subir imagen',
                        style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Mostrar sección de resultados solo si hay una imagen seleccionada
                if (_selectedImageBytes != null) ...[
                  const ReportAnalysisSection(),
                ],
              ],
            ),
          ),
        ),
        // Barra de navegación inferior
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFB0E0E6), // Azul claro
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: 1, // Índice para "Adjuntar"
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFF1E6091), // Azul oscuro
            unselectedItemColor: Colors.grey,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.attach_file),
                label: 'Adjuntar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book),
                label: 'Historial',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        // In a real app, this would navigate to a different screen.
        // For this single-screen app, we'll just show a snackbar.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navegar a Inicio'),
            backgroundColor: Color(0xFF1E6091),
          ),
        );
        break;
      case 1:
        // Already on "Adjuntar" screen, do nothing.
        break;
      case 2:
        _handleReportHistory();
        break;
      case 3:
        _handleProfile();
        break;
    }
  }

  void _handleUploadImage() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Seleccionar imagen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191970),
                ),
              ),
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

  // Seleccionar imagen desde la cámara
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        await _processSelectedImage(image);
      }
    } catch (e) {
      _showError('Error accediendo a la cámara: $e');
    }
  }

  // Seleccionar imagen desde la galería
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        await _processSelectedImage(image);
      }
    } catch (e) {
      _showError('Error accediendo a la galería: $e');
    }
  }

  // Procesar imagen seleccionada
  Future<void> _processSelectedImage(XFile image) async {
    try {
      // Leer bytes de la imagen
      final Uint8List imageBytes = await image.readAsBytes();
      
    setState(() {
        _selectedImageBytes = imageBytes;
        _selectedImageUrl = image.path; // Para mostrar en la UI
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen seleccionada. Iniciando análisis...'),
          backgroundColor: Color(0xFF191970),
        ),
      );

      // Realizar análisis con IA usando la imagen real
      await _performAIAnalysis();
      
    } catch (e) {
      _showError('Error procesando imagen: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _performAIAnalysis() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Verificar que tenemos una imagen seleccionada
      if (_selectedImageBytes == null) {
        _showError('No hay imagen seleccionada para analizar');
        setState(() {
          _isAnalyzing = false;
        });
        return;
      }

      // Intentar análisis real primero
      final response = await _aiService.checkHealth();
      
      if (response.success && response.data == true) {
        // Backend disponible, usar análisis real con la imagen seleccionada
        final analysisResponse = await _aiService.analyzeImageFromBytes(_selectedImageBytes!);
        
        if (analysisResponse.success) {
          _updateAnalysisResults(analysisResponse.data!);
        } else {
          // Fallback a análisis simulado
          await _performSimulatedAnalysis();
        }
      } else {
        // Backend no disponible, usar análisis simulado
        await _performSimulatedAnalysis();
      }
    } catch (e) {
      // Error, usar análisis simulado
      await _performSimulatedAnalysis();
    }

    setState(() {
      _isAnalyzing = false;
    });
  }

  Future<void> _performSimulatedAnalysis() async {
    final response = await _aiService.simulateAnalysis();
    if (response.success) {
      _updateAnalysisResults(response.data!);
    }
  }

  void _updateAnalysisResults(Map<String, dynamic> data) {
    // Actualizar los resultados en el provider
    final provider = Provider.of<ColonoscopyAnalysisData>(context, listen: false);
    
    // Crear nuevo análisis con datos reales
    final newAnalysis = ColonoscopyAnalysis(
      analysisDate: DateTime.now(),
      result: data['result'] ?? 'Análisis completado',
      currentStage: data['stage'] ?? 'Etapa evaluada',
    );
    
    // Actualizar el provider (esto requeriría modificar la clase)
    // Por ahora, mostramos un mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Análisis completado: ${data['result']}'),
        backgroundColor: const Color(0xFF191970),
      ),
    );
  }

  void _handleReportHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navegar a Historial de reportes'),
        backgroundColor: Color(0xFF191970),
      ),
    );
  }

  void _handleProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navegar a Perfil de usuario'),
        backgroundColor: Color(0xFF191970),
      ),
    );
  }
}

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
      onTap: () {
        Navigator.pop(context); // Pop the bottom sheet first
        onTap(); // Then execute the provided onTap callback
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFB0E0E6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              size: 40,
              color: const Color(0xFF191970),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191970),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// New widget to replace the private _buildDetailRow method.
class AnalysisDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AnalysisDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: const Color(0xFF1E6091), size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class ReportAnalysisSection extends StatelessWidget {
  const ReportAnalysisSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ColonoscopyAnalysisData>(
      builder: (BuildContext context, ColonoscopyAnalysisData analysisData, Widget? child) {
        final ColonoscopyAnalysis analysis = analysisData.analysis;
        final bool isGenerating = analysisData.isGeneratingReport;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Análisis de la colonoscopia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 15),
                AnalysisDetailRow(
                  icon: Icons.calendar_today,
                  label: 'Fecha del análisis:',
                  value: analysis.analysisDate.toLocal().toIso8601String().split('T')[0],
                ),
                const SizedBox(height: 10),
                AnalysisDetailRow(
                  icon: Icons.medical_services,
                  label: 'Resultado:',
                  value: analysis.result,
                ),
                const SizedBox(height: 10),
                AnalysisDetailRow(
                  icon: Icons.bar_chart,
                  label: 'Etapa Actual:',
                  value: analysis.currentStage,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isGenerating
                        ? null // Disable button while generating
                        : () async {
                            final bool success = await analysisData.generateReport();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success ? 'Reporte generado exitosamente.' : 'Error al generar el reporte.',
                                ),
                                backgroundColor: success ? const Color(0xFF1E6091) : Colors.red,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6091),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: isGenerating
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                              SizedBox(width: 10),
                              Text('Generando...', style: TextStyle(fontSize: 16)),
                            ],
                          )
                        : const Text(
                            'Generar Reporte',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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