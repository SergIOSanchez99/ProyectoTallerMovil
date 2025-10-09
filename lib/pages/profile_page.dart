import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/extensions.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../model/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = AuthService();
      final response = await authService.getCurrentUser();
      
      setState(() {
        if (response.success && response.data != null) {
          _currentUser = response.data;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error cargando datos del usuario: $e');
    }
  }

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
        child: SingleChildScrollView(
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
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else if (_currentUser != null) ...[
                      Text(
                        _currentUser!.name,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeXXL,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      Text(
                        _currentUser!.email,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeL,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      CustomButton(
                        text: 'Editar Perfil',
                        onPressed: _showEditProfileDialog,
                        backgroundColor: AppColors.primaryBlue,
                        icon: Icons.edit,
                      ),
                    ] else ...[
                      const Text(
                        'Error al cargar datos',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeL,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      CustomButton(
                        text: 'Reintentar',
                        onPressed: _loadUserData,
                        backgroundColor: AppColors.primaryBlue,
                        icon: Icons.refresh,
                      ),
                    ],
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
              const SizedBox(height: AppDimensions.spacingXL),
              // Botón de cerrar sesión
              CustomButton(
                text: 'Cerrar Sesión',
                onPressed: () => _handleLogout(context),
                backgroundColor: AppColors.error,
                icon: Icons.logout,
              ),
              const SizedBox(height: AppDimensions.spacingL),
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

  void _showEditProfileDialog() {
    if (_currentUser == null) return;
    
    final nameController = TextEditingController(text: _currentUser!.name);
    final emailController = TextEditingController(text: _currentUser!.email);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                label: 'Nombre',
                prefixIcon: const Icon(Icons.person, color: AppColors.primaryBlue),
                enabled: false, // Por ahora solo permitimos editar email
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: emailController,
                label: 'Correo electrónico',
                prefixIcon: const Icon(Icons.email, color: AppColors.primaryBlue),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateProfile(emailController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(String newEmail) async {
    if (newEmail.isEmpty || newEmail == _currentUser!.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay cambios para guardar'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Validar formato de email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(newEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formato de email inválido'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // Aquí normalmente harías una llamada al backend para actualizar el perfil
      // Por ahora simulamos la actualización
      setState(() {
        _currentUser = User(
          id: _currentUser!.id,
          email: newEmail,
          name: _currentUser!.name,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar perfil: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}









