import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'view/login_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Segmentación y Clasificación de Cáncer de Colon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'System',
      ),
      home: const LoginView(),
    );
  }
}
