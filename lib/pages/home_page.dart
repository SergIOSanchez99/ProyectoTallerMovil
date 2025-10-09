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
              decoration: const BoxDecoration(
                color: Color(0xFFB0E0E6), // Azul claro
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: 0, // Índice para "Inicio"
                onTap: _handleNavigation,
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
          ],
        ),
      ),
    );
  }


  void _handleAttachImage() {
    Navigator.pushNamed(context, AppRoutes.uploadImage);
  }

  void _handleReportHistory() {
    Navigator.pushNamed(context, AppRoutes.reportHistory);
  }

  void _handleGenerateReports() {
    Navigator.pushNamed(context, AppRoutes.generateReports);
  }

  void _handleNavigation(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
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
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }
}
