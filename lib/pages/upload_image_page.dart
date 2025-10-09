import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                  child: _selectedImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            _selectedImageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 80,
                                  color: Colors.red,
                                ),
                              );
                            },
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
                const ReportAnalysisSection(),
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
                      Navigator.pop(context); // Pop the bottom sheet
                      _pickImage(); // Then execute the provided onTap callback
                    },
                  ),
                  ImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galería',
                    onTap: () {
                      Navigator.pop(context); // Pop the bottom sheet
                      _pickImage(); // Then execute the provided onTap callback
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

  // Simulates image picking by setting a placeholder network image URL.
  Future<void> _pickImage() async {
    setState(() {
      _selectedImageUrl = 'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imagen seleccionada correctamente'),
        backgroundColor: Color(0xFF191970),
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
      onTap: onTap, // onTap already handles popping the sheet and then performing action
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