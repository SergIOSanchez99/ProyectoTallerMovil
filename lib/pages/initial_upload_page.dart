import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class InitialUploadPage extends StatelessWidget {
  const InitialUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Fondo azul muy claro
      appBar: AppBar(
        title: const Text('Inicio'),
        backgroundColor: const Color(0xFF1E6091), // Usar el color azul oscuro de tu app
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de bienvenida
                const Icon(
                  Icons.medical_services,
                  size: 100,
                  color: Color(0xFF1E6091),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Bienvenido',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E6091),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sistema de Análisis de Colonoscopia',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF191970),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                // Botón principal para subir imagen
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.uploadImage);
                    },
                    icon: const Icon(Icons.upload_file, color: Colors.white, size: 28),
                    label: const Text(
                      'Subir Imagen',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6091), // Color azul oscuro
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Texto informativo
                const Text(
                  'Selecciona una imagen para comenzar el análisis',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF191970),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                // Botón de logout
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                  child: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1E6091),
                      decoration: TextDecoration.underline,
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
}
