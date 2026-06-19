import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReportService {
  static const String _reportsKey = 'saved_reports';
  static List<Map<String, dynamic>> _reports = [];
  static bool _isInitialized = false;

  /// Inicializar el servicio y cargar reportes guardados
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadReportsFromStorage();
      _isInitialized = true;
      print('✅ ReportService inicializado con ${_reports.length} reportes');
    } catch (e) {
      print('⚠️ Error inicializando ReportService: $e');
      _initializeSampleReports();
      _isInitialized = true;
    }
  }

  /// Cargar reportes desde SharedPreferences
  static Future<void> _loadReportsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? reportsJson = prefs.getString(_reportsKey);
      
      if (reportsJson != null && reportsJson.isNotEmpty) {
        final List<dynamic> reportsList = json.decode(reportsJson);
        _reports = reportsList.cast<Map<String, dynamic>>();
        print('📂 Reportes cargados desde almacenamiento: ${_reports.length}');
      } else {
        print('📝 No hay reportes guardados, inicializando con ejemplos');
        _initializeSampleReports();
        await _saveReportsToStorage();
      }
    } catch (e) {
      print('⚠️ Error cargando reportes desde almacenamiento: $e');
      _initializeSampleReports();
    }
  }

  /// Guardar reportes en SharedPreferences
  static Future<void> _saveReportsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String reportsJson = json.encode(_reports);
      await prefs.setString(_reportsKey, reportsJson);
      print('💾 Reportes guardados en almacenamiento: ${_reports.length}');
    } catch (e) {
      print('⚠️ Error guardando reportes: $e');
    }
  }

  /// Obtener todos los reportes
  static List<Map<String, dynamic>> getAllReports() {
    return List.from(_reports);
  }

  /// Cargar reportes (método público para la UI)
  static Future<void> loadReports() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Inicializar reportes de ejemplo
  static void _initializeSampleReports() {
    _reports = [
      {
        'id': 'sample_1',
        'title': 'Reporte de Colonoscopia - 15/03/2024',
        'date': '2024-03-15',
        'status': 'Completado',
        'result': 'Normal',
        'stage': 'Sin anomalías detectadas',
        'confidence': 0.95,
        'riskLevel': 'Bajo',
        'createdAt': '2024-03-15T10:00:00Z',
      },
      {
        'id': 'sample_2',
        'title': 'Reporte de Colonoscopia - 10/03/2024',
        'date': '2024-03-10',
        'status': 'Completado',
        'result': 'Anomalía detectada',
        'stage': 'Etapa temprana',
        'confidence': 0.87,
        'riskLevel': 'Medio',
        'createdAt': '2024-03-10T14:30:00Z',
      },
    ];
    print('📝 Reportes de ejemplo inicializados: ${_reports.length}');
  }

  /// Agregar un nuevo reporte
  static Future<void> addReport({
    required String result,
    required String stage,
    required double confidence,
    required String riskLevel,
    String? imageBase64,
    String? patientName,
    String? patientId,
  }) async {
    print('🔄 Iniciando agregado de reporte...');
    print('📊 Reportes antes de agregar: ${_reports.length}');
    
    final newReport = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'Reporte de Colonoscopia - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      'date': DateTime.now().toIso8601String().split('T')[0],
      'status': 'Completado',
      'result': result,
      'stage': stage,
      'confidence': confidence,
      'riskLevel': riskLevel,
      'createdAt': DateTime.now().toIso8601String(),
      if (imageBase64 != null) 'imageBase64': imageBase64,
      if (patientName != null) 'patientName': patientName,
      if (patientId != null) 'patientId': patientId,
    };

    _reports.insert(0, newReport); // Agregar al inicio de la lista

    print('✅ Reporte agregado al historial: ${newReport['title']}');
    print('📊 Total de reportes en memoria después: ${_reports.length}');
    
    // Mostrar todos los reportes para debugging
    for (int i = 0; i < _reports.length; i++) {
      print('📋 Reporte $i: ${_reports[i]['title']} - ${_reports[i]['result']}');
    }
    
    // Guardar en almacenamiento persistente
    await _saveReportsToStorage();
    
    print('✅ Proceso de agregado completado');
  }

  /// Obtener un reporte por ID
  static Map<String, dynamic>? getReportById(String id) {
    try {
      return _reports.firstWhere((report) => report['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// Eliminar un reporte
  static Future<void> deleteReport(String id) async {
    _reports.removeWhere((report) => report['id'] == id);
    await _saveReportsToStorage();
    print('🗑️ Reporte eliminado: $id');
  }

  /// Obtener estadísticas de reportes
  static Map<String, dynamic> getReportStats() {
    if (_reports.isEmpty) {
      return {
        'total': 0,
        'completed': 0,
        'inProgress': 0,
        'errors': 0,
      };
    }

    int completed = 0;
    int inProgress = 0;
    int errors = 0;

    for (var report in _reports) {
      switch (report['status'].toString().toLowerCase()) {
        case 'completado':
          completed++;
          break;
        case 'en proceso':
          inProgress++;
          break;
        case 'error':
          errors++;
          break;
      }
    }

    return {
      'total': _reports.length,
      'completed': completed,
      'inProgress': inProgress,
      'errors': errors,
    };
  }
}

