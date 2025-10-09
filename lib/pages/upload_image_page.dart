import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../utils/extensions.dart';

class UploadImagePage extends StatefulWidget {
  const UploadImagePage({super.key});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightBlue,
      appBar: AppBar(
        title: const Text('Subir Imagen'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            children: [
              // Área de subida de imagen
              Expanded(
                child: CustomCard(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 80,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      const Text(
                        'Arrastra y suelta tu imagen aquí',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeXL,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      const Text(
                        'o',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeL,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      CustomButton(
                        text: 'Seleccionar Imagen',
                        onPressed: _handleSelectImage,
                        icon: Icons.image,
                        isLoading: _isUploading,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      const Text(
                        'Formatos soportados: JPG, PNG, GIF',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              // Botón de procesar
              CustomButton(
                text: 'Procesar Imagen',
                onPressed: _handleProcessImage,
                isLoading: _isUploading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSelectImage() async {
    setState(() {
      _isUploading = true;
    });

    // Simular selección de imagen
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isUploading = false;
    });

    context.showSuccessSnackBar('Imagen seleccionada correctamente');
  }

  void _handleProcessImage() async {
    setState(() {
      _isUploading = true;
    });

    // Simular procesamiento
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isUploading = false;
    });

    context.showSuccessSnackBar('Imagen procesada correctamente');
    
    // Navegar a resultados
    context.pop();
  }
}
