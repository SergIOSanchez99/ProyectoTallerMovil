import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_card.dart';
import '../utils/validators.dart';
import '../utils/extensions.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.spacingHuge),
              // Título principal
              const Text(
                AppStrings.appTitle,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeXXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              const Text(
                AppStrings.appSubtitle,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeXXXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingXXXL),
              // Card del login
              CustomCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Título del login
                      const Text(
                        AppStrings.loginTitle,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeHuge,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.spacingXL),
                      // Campo de usuario
                      CustomTextField(
                        label: AppStrings.usernameLabel,
                        controller: _usuarioController,
                        validator: Validators.validateUsername,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      // Campo de contraseña
                      CustomTextField(
                        label: AppStrings.passwordLabel,
                        controller: _contrasenaController,
                        obscureText: true,
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: AppDimensions.spacingXL),
                      // Botón de ingresar
                      CustomButton(
                        text: AppStrings.loginButton,
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      // Enlace de contraseña olvidada
                      GestureDetector(
                        onTap: _handleForgotPassword,
                        child: const Text(
                          AppStrings.forgotPassword,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            color: AppColors.secondaryBlue,
                            decoration: TextDecoration.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      // Enlace de registro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes cuenta? ',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.register);
                            },
                            child: const Text(
                              'Regístrate',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeM,
                                color: AppColors.secondaryBlue,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final response = await authService.login(
        _usuarioController.text.trim(),
        _contrasenaController.text,
      );

      if (response.success && response.data != null) {
        // Login exitoso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Login exitoso'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Navegar a la pantalla principal después de un breve delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        }
      } else {
        // Login fallido - mostrar mensaje de error del backend
        if (mounted) {
          final errorMessage = response.message ?? 'Las credenciales ingresadas no existen. Verifica tu email y contraseña.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Error de conexión u otro error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleForgotPassword() {
    context.showInfoSnackBar(AppStrings.forgotPasswordComingSoon);
  }
}









