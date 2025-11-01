import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/validators.dart';
import '../utils/extensions.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightBlue,
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.spacingXXL),
              // Icono
              const Icon(
                Icons.lock_reset,
                size: 80,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              // Título
              const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeXXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              const Text(
                'Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingXL),
              // Formulario
              CustomCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Email',
                        controller: _emailController,
                        hint: 'Ingrese su email',
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: AppDimensions.spacingXL),
                      CustomButton(
                        text: 'Enviar Enlace',
                        onPressed: _handleSendResetLink,
                        isLoading: _isLoading,
                        icon: Icons.send,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Enlace de vuelta al login
              GestureDetector(
                onTap: () => context.pop(),
                child: const Text(
                  'Volver al inicio de sesión',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    color: AppColors.secondaryBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simular envío de email
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    context.showSuccessSnackBar('Enlace de recuperación enviado a tu email');
    
    // Volver al login
    context.pop();
  }
}
