class AppRoutes {
  // Rutas principales
  static const String splash = '/';
  static const String initial = '/initial';
  static const String login = '/login';
  static const String home = '/home';
  static const String search = '/search';
  static const String uploadImage = '/upload-image';
  static const String segmentation = '/segmentation';
  static const String profile = '/profile';
  static const String reportHistory = '/report-history';
  static const String generateReports = '/generate-reports';
  
  // Rutas de autenticación
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  
  // Rutas de configuración
  static const String settings = '/settings';
  static const String about = '/about';
  
  // Lista de todas las rutas
  static const List<String> allRoutes = [
    splash,
    initial,
    login,
    register,
    home,
    search,
    uploadImage,
    segmentation,
    profile,
    reportHistory,
    generateReports,
    forgotPassword,
    resetPassword,
    settings,
    about,
  ];
}
