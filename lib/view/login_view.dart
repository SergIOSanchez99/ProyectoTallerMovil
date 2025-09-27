import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/login_viewmodel.dart';
import 'search_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F8FF), // Color de fondo azul muy claro
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 80),
                // Título principal
                const Text(
                  'Segmentación y clasificación',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'de Cancer de Colon',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066CC), // Azul vibrante
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                // Card del login
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Título del login
                        const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066CC), // Azul vibrante
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Campo de email
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Correo electrónico',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F3FF), // Azul muy claro
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            style: const TextStyle(fontSize: 16),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El email es requerido';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Formato de email inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Campo de contraseña
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Contraseña',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F3FF), // Azul muy claro
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            style: const TextStyle(fontSize: 16),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La contraseña es requerida';
                              }
                              if (value.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Botón de ingresar
                        Consumer<LoginViewModel>(
                          builder: (context, viewModel, child) {
                            return SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: viewModel.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003366), // Azul oscuro
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: viewModel.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Ingresar',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Enlace de contraseña olvidada
                        Consumer<LoginViewModel>(
                          builder: (context, viewModel, child) {
                            return GestureDetector(
                              onTap: viewModel.isLoading ? null : _handleForgotPassword,
                              child: const Text(
                                '¿Olvidó su contraseña?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF0066CC), // Azul vibrante
                                  decoration: TextDecoration.none,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                        // Mostrar mensaje de error
                        Consumer<LoginViewModel>(
                          builder: (context, viewModel, child) {
                            if (viewModel.errorMessage != null) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  viewModel.errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final viewModel = Provider.of<LoginViewModel>(context, listen: false);
    final success = await viewModel.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      // Navegar a la pantalla de búsqueda
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SearchView()),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingrese su email primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final viewModel = Provider.of<LoginViewModel>(context, listen: false);
    final success = await viewModel.forgotPassword(_emailController.text.trim());

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instrucciones enviadas al email'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
