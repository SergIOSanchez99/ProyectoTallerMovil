import 'package:flutter/foundation.dart';
import '../model/user.dart';
import '../model/api_response.dart';
import '../services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Estados
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  // Métodos
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(email, password);
      
      if (response.success && response.data != null) {
        _currentUser = response.data;
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? 'Error desconocido');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.forgotPassword(email);
      
      if (response.success) {
        _setLoading(false);
        return true;
      } else {
        _setError(response.error ?? 'Error desconocido');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
      _currentUser = null;
      _clearError();
    } catch (e) {
      _setError('Error al cerrar sesión: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getCurrentUser() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.getCurrentUser();
      
      if (response.success && response.data != null) {
        _currentUser = response.data;
      } else {
        _setError(response.error ?? 'Error al obtener usuario');
      }
    } catch (e) {
      _setError('Error de conexión: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
