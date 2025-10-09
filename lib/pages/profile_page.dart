import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../utils/extensions.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightBlue,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            children: [
              // Información del usuario
              CustomCard(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryBlue,
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingL),
                    const Text(
                      'Usuario Demo',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeXXL,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    const Text(
                      'usuario@demo.com',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              // Opciones del perfil
              CustomCard(
                child: Column(
                  children: [
                    _buildProfileOption(
                      icon: Icons.settings,
                      title: 'Configuración',
                      onTap: () {
                        context.showInfoSnackBar('Configuración próximamente');
                      },
                    ),
                    const Divider(),
                    _buildProfileOption(
                      icon: Icons.history,
                      title: 'Historial',
                      onTap: () {
                        context.showInfoSnackBar('Historial próximamente');
                      },
                    ),
                    const Divider(),
                    _buildProfileOption(
                      icon: Icons.help,
                      title: 'Ayuda',
                      onTap: () {
                        context.showInfoSnackBar('Ayuda próximamente');
                      },
                    ),
                    const Divider(),
                    _buildProfileOption(
                      icon: Icons.info,
                      title: 'Acerca de',
                      onTap: () {
                        context.showInfoSnackBar('Acerca de próximamente');
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Botón de cerrar sesión
              CustomButton(
                text: 'Cerrar Sesión',
                onPressed: () => _handleLogout(context),
                backgroundColor: AppColors.error,
                icon: Icons.logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeL,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navegar a login
              context.pushReplacementNamed('/login');
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}









