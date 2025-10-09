import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../utils/extensions.dart';
import '../routes/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightBlue,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppDimensions.spacingXXL),
            // Área de contenido principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                child: Column(
                  children: [
                    // Tarjeta blanca central con las opciones
                    CustomCard(
                      child: Column(
                        children: [
                          // Fila superior: Adjuntar imagen y Historial de reportes
                          Row(
                            children: [
                              Expanded(
                                child: ActionCard(
                                  icon: Icons.attach_file,
                                  title: AppStrings.attachImage,
                                  onTap: _handleAttachImage,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spacingM),
                              Expanded(
                                child: ActionCard(
                                  icon: Icons.history,
                                  title: AppStrings.reportHistory,
                                  onTap: _handleReportHistory,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingL),
                          // Fila inferior: Generar reportes (centrado)
                          Row(
                            children: [
                              const Spacer(),
                              SizedBox(
                                width: context.screenWidth * 0.35,
                                child: ActionCard(
                                  icon: Icons.attach_file,
                                  title: AppStrings.generateReports,
                                  onTap: _handleGenerateReports,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Barra de navegación inferior
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
              decoration: const BoxDecoration(
                color: AppColors.lightBlue,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, AppStrings.homeNav, 0),
                  _buildNavItem(Icons.attach_file, AppStrings.attachNav, 1),
                  _buildNavItem(Icons.history, AppStrings.historyNav, 2),
                  _buildNavItem(Icons.person, AppStrings.profileNav, 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        _handleNavigation(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppDimensions.iconSizeM,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAttachImage() {
    context.pushNamed(AppRoutes.uploadImage);
  }

  void _handleReportHistory() {
    context.pushNamed(AppRoutes.reportHistory);
  }

  void _handleGenerateReports() {
    context.pushNamed(AppRoutes.generateReports);
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Ya estamos en inicio
        break;
      case 1:
        _handleAttachImage();
        break;
      case 2:
        _handleReportHistory();
        break;
      case 3:
        context.pushNamed(AppRoutes.profile);
        break;
    }
  }
}
