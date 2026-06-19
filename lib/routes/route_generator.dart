import 'package:flutter/material.dart';
import '../pages/initial_upload_page.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/home_page.dart';
import '../pages/search_page.dart';
import '../pages/upload_image_page.dart';
import '../pages/profile_page.dart';
import '../pages/report_history_page.dart';
import '../pages/generate_reports_page.dart';
import '../pages/segmentation_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/settings_page.dart';
import '../pages/about_page.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.initial:
        return MaterialPageRoute(
          builder: (_) => const InitialUploadPage(),
          settings: settings,
        );
        
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
        
      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );
        
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
          settings: settings,
        );
        
      case AppRoutes.search:
        return MaterialPageRoute(
          builder: (_) => const SearchPage(),
          settings: settings,
        );
        
      case AppRoutes.uploadImage:
        return MaterialPageRoute(
          builder: (_) => const UploadImagePage(),
          settings: settings,
        );
        
      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => const ProfilePage(),
          settings: settings,
        );
        
      case AppRoutes.reportHistory:
        return MaterialPageRoute(
          builder: (_) => const ReportHistoryPage(),
          settings: settings,
        );
        
      case AppRoutes.generateReports:
        return MaterialPageRoute(
          builder: (_) => const GenerateReportsPage(),
          settings: settings,
        );
        
      case AppRoutes.segmentation:
        return MaterialPageRoute(
          builder: (_) => const SegmentationPage(),
          settings: settings,
        );
        
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordPage(),
          settings: settings,
        );
        
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
          settings: settings,
        );
        
      case AppRoutes.about:
        return MaterialPageRoute(
          builder: (_) => const AboutPage(),
          settings: settings,
        );
        
      default:
        return _errorRoute();
    }
  }
  
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Página no encontrada'),
        ),
      ),
    );
  }
}
