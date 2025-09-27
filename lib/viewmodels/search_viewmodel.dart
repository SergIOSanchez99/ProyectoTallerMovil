import 'package:flutter/foundation.dart';
import '../model/person.dart';
import '../model/api_response.dart';
import '../services/person_service.dart';

class SearchViewModel extends ChangeNotifier {
  final PersonService _personService = PersonService();

  // Estados
  bool _isLoading = false;
  String? _errorMessage;
  List<Person> _searchResults = [];
  String _searchQuery = '';

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Person> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  bool get hasResults => _searchResults.isNotEmpty;

  // Métodos
  Future<void> searchPersons(String query) async {
    _searchQuery = query;
    _setLoading(true);
    _clearError();

    try {
      final response = await _personService.searchPersons(query);
      
      if (response.success && response.data != null) {
        _searchResults = response.data!;
      } else {
        _setError(response.error ?? 'Error al buscar personas');
        _searchResults = [];
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      _searchResults = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getAllPersons() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _personService.getAllPersons();
      
      if (response.success && response.data != null) {
        _searchResults = response.data!;
      } else {
        _setError(response.error ?? 'Error al obtener personas');
        _searchResults = [];
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      _searchResults = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearSearch() async {
    _searchQuery = '';
    _searchResults = [];
    _clearError();
    notifyListeners();
  }

  Person? getPersonById(String id) {
    try {
      return _searchResults.firstWhere((person) => person.id == id);
    } catch (e) {
      return null;
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
