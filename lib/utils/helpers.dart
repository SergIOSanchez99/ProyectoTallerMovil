import 'package:flutter/material.dart';

class Helpers {
  // Formateo de fechas
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  // Validación de imágenes
  static bool isValidImageUrl(String url) {
    final imageRegex = RegExp(r'\.(jpg|jpeg|png|gif|bmp|webp)$', caseSensitive: false);
    return imageRegex.hasMatch(url);
  }
  
  // Capitalización de texto
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }
  
  // Generación de colores aleatorios
  static Color generateRandomColor() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[DateTime.now().millisecond % colors.length];
  }
  
  // Verificación de conexión (placeholder)
  static Future<bool> hasInternetConnection() async {
    // Aquí implementarías la lógica real de verificación de conexión
    return true;
  }
}









