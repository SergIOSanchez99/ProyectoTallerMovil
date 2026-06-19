import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/segmentation_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../routes/app_routes.dart';

class SegmentationPage extends StatefulWidget {
  const SegmentationPage({super.key});

  @override
  State<SegmentationPage> createState() => _SegmentationPageState();
}

class _SegmentationPageState extends State<SegmentationPage> {
  Uint8List? _originalImageBytes;
  Uint8List? _segmentedImageBytes;
  final SegmentationService _segmentationService = SegmentationService();
  final ImagePicker _picker = ImagePicker();
  bool _isSegmenting = false;
  double _alpha = 0.5;
  Map<String, dynamic>? _statistics;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text('Segmentación de Imagen'),
        backgroundColor: const Color(0xFF1E6091),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Botón para seleccionar imagen
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSegmenting ? null : _handleSelectImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E6091),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.image),
                  label: const Text(
                    'Seleccionar Imagen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Control de transparencia (solo visible si hay imagen segmentada)
              if (_segmentedImageBytes != null) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transparencia del Overlay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _alpha,
                                min: 0.0,
                                max: 1.0,
                                divisions: 10,
                                label: '${(_alpha * 100).toStringAsFixed(0)}%',
                                onChanged: (value) {
                                  setState(() {
                                    _alpha = value;
                                  });
                                  // Re-segmentar con nuevo alpha
                                  if (_originalImageBytes != null) {
                                    _performSegmentation();
                                  }
                                },
                              ),
                            ),
                            Text(
                              '${(_alpha * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Imagen original
              if (_originalImageBytes != null) ...[
                const Text(
                  'Imagen Original',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF191970),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      _originalImageBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Imagen segmentada
              if (_segmentedImageBytes != null) ...[
                const Text(
                  'Imagen Segmentada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF191970),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      _segmentedImageBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Leyenda de colores
                _buildLegend(),
                const SizedBox(height: 20),

                // Estadísticas
                if (_statistics != null) _buildStatistics(),
              ],

              // Indicador de carga
              if (_isSegmenting) ...[
                const SizedBox(height: 20),
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1E6091),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Segmentando imagen...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],

              // Mensaje de error
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Mensaje inicial si no hay imagen
              if (_originalImageBytes == null && !_isSegmenting) ...[
                const SizedBox(height: 40),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.biotech,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Segmentación de Imágenes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Selecciona una imagen para realizar la segmentación y visualizar:\n'
                          '• Tejidos sanos (verde)\n'
                          '• Tejidos cancerosos (rojo)\n'
                          '• Background (negro)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      // Barra de navegación inferior
      bottomNavigationBar: Container(
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
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.biotech),
              label: 'Segmentar',
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
    );
  }

  Widget _buildLegend() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leyenda',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              const Color(0xFF000000),
              'Background',
              'Fondo de la imagen',
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              const Color(0xFF00FF00),
              'Tejido Sano',
              'Áreas de tejido saludable',
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              const Color(0xFFFF0000),
              'Tejido Canceroso',
              'Áreas con posible cáncer',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String title, String description) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    final stats = _statistics!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas de Segmentación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Tejido Sano',
              '${stats['healthy_percentage']?.toStringAsFixed(1) ?? '0.0'}%',
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Tejido Canceroso',
              '${stats['cancerous_percentage']?.toStringAsFixed(1) ?? '0.0'}%',
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Background',
              '${stats['background_percentage']?.toStringAsFixed(1) ?? '0.0'}%',
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
        break;
      case 1:
        // Ya estamos en segmentación
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.reportHistory);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  Future<void> _handleSelectImage() async {
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
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Cámara',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  _buildImageSourceOption(
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

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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

  Future<void> _processSelectedImage(XFile image) async {
    try {
      final Uint8List imageBytes = await image.readAsBytes();

      setState(() {
        _originalImageBytes = imageBytes;
        _segmentedImageBytes = null;
        _statistics = null;
        _errorMessage = null;
      });

      // Realizar segmentación automáticamente
      await _performSegmentation();
    } catch (e) {
      _showError('Error procesando imagen: $e');
    }
  }

  Future<void> _performSegmentation() async {
    if (_originalImageBytes == null) return;

    setState(() {
      _isSegmenting = true;
      _errorMessage = null;
    });

    try {
      final response = await _segmentationService.segmentImageFromBytes(
        _originalImageBytes!,
        alpha: _alpha,
      );

      if (response.success && response.data != null) {
        final data = response.data!;

        // Decodificar imagen segmentada
        final segmentedBase64 = data['segmented_image'] as String?;
        if (segmentedBase64 != null) {
          final segmentedBytes =
              _segmentationService.decodeBase64Image(segmentedBase64);

          if (segmentedBytes != null) {
            setState(() {
              _segmentedImageBytes = segmentedBytes;
              _statistics = data['statistics'] as Map<String, dynamic>?;
              _errorMessage = null;
            });
          } else {
            _showError('Error decodificando imagen segmentada');
          }
        } else {
          _showError('No se recibió imagen segmentada del servidor');
        }
      } else {
        _showError(response.message ?? 'Error en la segmentación');
      }
    } catch (e) {
      _showError('Error realizando segmentación: $e');
    } finally {
      setState(() {
        _isSegmenting = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
