import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Fondo azul muy claro
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Área de contenido principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Tarjeta blanca central con las opciones
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Fila superior: Adjuntar imagen y Historial de reportes
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  icon: Icons.attach_file,
                                  title: 'Adjuntar imagen',
                                  onTap: () => _handleAttachImage(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildActionCard(
                                  icon: Icons.history,
                                  title: 'Historial de reportes',
                                  onTap: () => _handleReportHistory(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Fila inferior: Generar reportes (centrado)
                          Row(
                            children: [
                              const Spacer(),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.35,
                                child: _buildActionCard(
                                  icon: Icons.attach_file,
                                  title: 'Generar reportes',
                                  onTap: () => _handleGenerateReports(),
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
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: const BoxDecoration(
                color: Color(0xFFE6F3FF), // Azul claro
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, 'Inicio', 0),
                  _buildNavItem(Icons.attach_file, 'Adjuntar', 1),
                  _buildNavItem(Icons.history, 'Historial', 2),
                  _buildNavItem(Icons.person, 'Perfil', 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F3FF), // Azul claro
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.black,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
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
            size: 24,
            color: Colors.black,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAttachImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de adjuntar imagen próximamente'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleReportHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de historial de reportes próximamente'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleGenerateReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de generar reportes próximamente'),
        backgroundColor: Colors.blue,
      ),
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidad de perfil próximamente'),
            backgroundColor: Colors.blue,
          ),
        );
        break;
    }
  }
}
