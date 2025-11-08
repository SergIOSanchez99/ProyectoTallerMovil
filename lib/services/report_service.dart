import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReportService {
  static const String _reportsKey = 'saved_reports';
  static List<Map<String, dynamic>> _reports = [];
  static bool _isInitialized = false;

  /// Inicializar el servicio y cargar reportes guardados
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('ℹ️ ReportService ya está inicializado con ${_reports.length} reportes');
      return;
    }
    
    try {
      print('🔄 Inicializando ReportService...');
      await _loadReportsFromStorage();
      _isInitialized = true;
      print('✅ ReportService inicializado exitosamente con ${_reports.length} reportes');
      
      // Verificar que los reportes están en memoria
      if (_reports.isNotEmpty) {
        print('📊 Reportes cargados en memoria:');
        for (int i = 0; i < _reports.length; i++) {
          print('  - ${_reports[i]['title']} (ID: ${_reports[i]['id']})');
        }
      } else {
        print('ℹ️ No hay reportes guardados aún. Los nuevos análisis se guardarán automáticamente.');
      }
    } catch (e, stackTrace) {
      print('❌ Error inicializando ReportService: $e');
      print('❌ Stack trace: $stackTrace');
      // En caso de error, inicializar lista vacía (NO usar ejemplos)
      _reports = [];
      _isInitialized = true;
      print('⚠️ ReportService inicializado con lista vacía debido a error');
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
        
        // Verificar que los reportes se cargaron correctamente
        for (int i = 0; i < _reports.length; i++) {
          print('📋 Reporte cargado $i: ${_reports[i]['title']} - ID: ${_reports[i]['id']}');
        }
      } else {
        print('📝 No hay reportes guardados en almacenamiento');
        // NO inicializar reportes de ejemplo automáticamente
        // Solo inicializar la lista vacía
        _reports = [];
        print('📝 Lista de reportes inicializada vacía (sin ejemplos)');
      }
    } catch (e, stackTrace) {
      print('⚠️ Error cargando reportes desde almacenamiento: $e');
      print('⚠️ Stack trace: $stackTrace');
      // En caso de error, inicializar lista vacía
      _reports = [];
      print('📝 Lista de reportes inicializada vacía debido a error');
    }
  }

  /// Guardar reportes en SharedPreferences
  static Future<void> _saveReportsToStorage() async {
    try {
      print('💾 Iniciando guardado de reportes...');
      print('📊 Total de reportes a guardar: ${_reports.length}');
      
      final prefs = await SharedPreferences.getInstance();
      final String reportsJson = json.encode(_reports);
      
      // Verificar que el JSON se generó correctamente
      if (reportsJson.isEmpty) {
        print('⚠️ Advertencia: El JSON generado está vacío');
      }
      
      final success = await prefs.setString(_reportsKey, reportsJson);
      
      if (success) {
        print('✅ Reportes guardados exitosamente en SharedPreferences');
        print('📊 Reportes guardados: ${_reports.length}');
        
        // Verificar que se guardaron correctamente leyendo de vuelta
        final String? savedJson = prefs.getString(_reportsKey);
        if (savedJson != null && savedJson.isNotEmpty) {
          final List<dynamic> savedList = json.decode(savedJson);
          print('✅ Verificación: ${savedList.length} reportes confirmados en almacenamiento');
        } else {
          print('⚠️ Advertencia: No se pudo verificar el guardado');
        }
      } else {
        print('❌ Error: No se pudo guardar en SharedPreferences');
      }
    } catch (e, stackTrace) {
      print('❌ Error guardando reportes: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow; // Relanzar el error para que se pueda manejar arriba
    }
  }

  /// Obtener todos los reportes
  static List<Map<String, dynamic>> getAllReports() {
    return List.from(_reports);
  }

  /// Cargar reportes (método público para la UI)
  /// Recarga los reportes desde el almacenamiento persistente
  static Future<void> loadReports() async {
    if (!_isInitialized) {
      await initialize();
    } else {
      // Si ya está inicializado, recargar desde el almacenamiento
      print('🔄 Recargando reportes desde almacenamiento...');
      await _loadReportsFromStorage();
      print('✅ Reportes recargados: ${_reports.length}');
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
  }) async {
    // Asegurar que el servicio esté inicializado
    if (!_isInitialized) {
      print('⚠️ ReportService no inicializado, inicializando ahora...');
      await initialize();
    }
    
    print('🔄 Iniciando agregado de reporte...');
    print('📊 Reportes antes de agregar: ${_reports.length}');
    
    // Generar ID único basado en timestamp
    final now = DateTime.now();
    final reportId = '${now.millisecondsSinceEpoch}_${now.microsecondsSinceEpoch}';
    
    final newReport = {
      'id': reportId,
      'title': 'Reporte de Colonoscopia - ${now.day}/${now.month}/${now.year}',
      'date': now.toIso8601String().split('T')[0],
      'status': 'Completado',
      'result': result,
      'stage': stage,
      'confidence': confidence,
      'riskLevel': riskLevel,
      'createdAt': now.toIso8601String(),
    };

    // Agregar al inicio de la lista
    _reports.insert(0, newReport);

    print('✅ Reporte agregado en memoria: ${newReport['title']}');
    print('📋 ID del reporte: $reportId');
    print('📊 Total de reportes en memoria: ${_reports.length}');
    
    // Guardar en almacenamiento persistente inmediatamente
    try {
      await _saveReportsToStorage();
      print('✅ Reporte guardado exitosamente en almacenamiento persistente');
    } catch (e) {
      print('❌ Error guardando reporte: $e');
      // Intentar guardar de nuevo después de un breve delay
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await _saveReportsToStorage();
        print('✅ Reporte guardado en segundo intento');
      } catch (e2) {
        print('❌ Error crítico: No se pudo guardar el reporte después de 2 intentos: $e2');
        // El reporte está en memoria, pero no se guardó permanentemente
        // Esto puede causar pérdida de datos si se reinicia la app
      }
    }
    
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

