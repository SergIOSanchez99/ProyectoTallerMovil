import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

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
      appBar: AppBar(
        title: const Text('Inicio'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'logout') {
                await _handleLogout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppDimensions.spacingL),
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
                          // Fila inferior: Generar reportes y Realizar Segmentación
                          Row(
                            children: [
                              Expanded(
                                child: ActionCard(
                                  icon: Icons.description,
                                  title: AppStrings.generateReports,
                                  onTap: _handleGenerateReports,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spacingM),
                              Expanded(
                                child: ActionCard(
                                  icon: Icons.biotech,
                                  title: AppStrings.performSegmentation,
                                  onTap: _handlePerformSegmentation,
                                ),
                              ),
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

  void _handlePerformSegmentation() {
    Navigator.pushNamed(context, AppRoutes.segmentation);
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

  Future<void> _handleLogout() async {
    // Mostrar diálogo de confirmación
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      // Cerrar sesión
      final authService = AuthService();
      final response = await authService.logout();
      
      // Navegar a la página de login
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
      
      // Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Sesión cerrada exitosamente'),
          backgroundColor: response.success ? AppColors.success : Colors.red,
        ),
      );
    }
  }
}
