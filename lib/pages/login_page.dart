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
import 'home_page.dart';

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
        child: Padding(
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

    // Simular delay de autenticación
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    // Navegar a la pantalla principal
    context.pushReplacementNamed(AppRoutes.home);
  }

  void _handleForgotPassword() {
    context.showInfoSnackBar(AppStrings.forgotPasswordComingSoon);
  }
}









