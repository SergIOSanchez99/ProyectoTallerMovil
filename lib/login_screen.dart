import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Título del login
                    const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0066CC), // Azul vibrante
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Campo de usuario
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Usuario',
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
                      child: TextField(
                        controller: _usuarioController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
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
                      child: TextField(
                        controller: _contrasenaController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Botón de ingresar
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          // Aquí puedes agregar la lógica de login
                          _handleLogin();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366), // Azul oscuro
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Ingresar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Enlace de contraseña olvidada
                    GestureDetector(
                      onTap: () {
                        // Aquí puedes agregar la lógica para recuperar contraseña
                        _handleForgotPassword();
                      },
                      child: const Text(
                        '¿Olvidó su contraseña?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0066CC), // Azul vibrante
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    // Lógica para el login
    final usuario = _usuarioController.text;
    final contrasena = _contrasenaController.text;
    
    if (usuario.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, complete todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Aquí puedes agregar la validación real del usuario
    // Navegar a la pantalla principal
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _handleForgotPassword() {
    // Lógica para recuperar contraseña
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de recuperar contraseña próximamente'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
