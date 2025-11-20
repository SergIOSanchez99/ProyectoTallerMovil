import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'study_service.dart';
import 'image_storage_service.dart';

class ReportService {
  static const String _reportsKey = 'saved_reports';
  static List<Map<String, dynamic>> _reports = [];
  static bool _isInitialized = false;
  static final StudyService _studyService = StudyService();

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
  /// Recarga los reportes desde el almacenamiento persistente y sincroniza con el backend
  static Future<void> loadReports({bool syncFromBackend = true}) async {
    if (!_isInitialized) {
      await initialize();
    } else {
      // Si ya está inicializado, recargar desde el almacenamiento
      print('🔄 Recargando reportes desde almacenamiento...');
      await _loadReportsFromStorage();
      print('✅ Reportes recargados localmente: ${_reports.length}');
    }
    
    // Sincronizar con el backend si se solicita
    if (syncFromBackend) {
      await _syncFromBackend();
    }
  }
  
  /// Sincronizar reportes desde el backend
  static Future<void> _syncFromBackend() async {
    try {
      print('🌐 Sincronizando reportes desde el backend...');
      final response = await _studyService.getAllStudies();
      
      if (response.success && response.data != null) {
        final backendStudies = response.data!;
        print('📊 Estudios obtenidos del backend: ${backendStudies.length}');
        
        // Convertir estudios del backend al formato local
        final backendReports = backendStudies.map((study) {
          final createdAt = study['created_at'] ?? DateTime.now().toIso8601String();
          final dateStr = createdAt.toString().split('T')[0];
          final dateParts = dateStr.split('-');
          final day = int.tryParse(dateParts[2]) ?? DateTime.now().day;
          final month = int.tryParse(dateParts[1]) ?? DateTime.now().month;
          final year = int.tryParse(dateParts[0]) ?? DateTime.now().year;
          
          return {
            'id': 'backend_${study['id']}',
            'backendId': study['id'],
            'title': 'Reporte de Colonoscopia - $day/$month/$year',
            'date': dateStr,
            'status': 'Completado',
            'result': study['result'] ?? 'N/A',
            'stage': study['stage'] ?? 'N/A',
            'confidence': study['confidence'] != null ? (study['confidence'] is double ? study['confidence'] : double.tryParse(study['confidence'].toString()) ?? 0.0) : 0.0,
            'riskLevel': study['risk_level'] ?? 'N/A',
            'createdAt': createdAt,
            'backendCreatedAt': createdAt,
          };
        }).toList();
        
        // Combinar reportes locales y del backend, evitando duplicados
        final Map<String, Map<String, dynamic>> combinedReports = {};
        
        // Primero agregar reportes locales
        for (var report in _reports) {
          final key = report['backendId']?.toString() ?? report['id'];
          combinedReports[key] = report;
        }
        
        // Luego agregar/actualizar con reportes del backend
        for (var report in backendReports) {
          final key = report['backendId']?.toString() ?? report['id'];
          // El backend tiene prioridad si existe el mismo ID
          combinedReports[key] = report;
        }
        
        // Actualizar la lista de reportes
        _reports = combinedReports.values.toList()
          ..sort((a, b) {
            final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
            final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
            return dateB.compareTo(dateA); // Más recientes primero
          });
        
        // Guardar la lista sincronizada
        await _saveReportsToStorage();
        print('✅ Sincronización completada. Total de reportes: ${_reports.length}');
      } else {
        print('⚠️ No se pudieron obtener estudios del backend: ${response.message}');
        print('⚠️ Se mantienen solo los reportes locales');
      }
    } catch (e) {
      print('❌ Error sincronizando desde el backend: $e');
      print('⚠️ Se mantienen solo los reportes locales');
      // No lanzar excepción - los reportes locales siguen disponibles
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
    int? patientId,
    int? userId,
    String? imagePath,
    String? studyDate,
    String? doctorName,
    String? observations,
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
    
    // Construir título con fecha del estudio si está disponible
    String reportTitle;
    if (studyDate != null && studyDate.isNotEmpty) {
      try {
        // Si viene en formato YYYY-MM-DD, convertir a DD/MM/YYYY
        if (studyDate.contains('-') && studyDate.length == 10) {
          final parts = studyDate.split('-');
          if (parts.length == 3) {
            reportTitle = 'Reporte de Colonoscopia - ${parts[2]}/${parts[1]}/${parts[0]}';
          } else {
            reportTitle = 'Reporte de Colonoscopia - ${now.day}/${now.month}/${now.year}';
          }
        } else {
          // Ya está en formato DD/MM/YYYY
          reportTitle = 'Reporte de Colonoscopia - $studyDate';
        }
      } catch (e) {
        reportTitle = 'Reporte de Colonoscopia - ${now.day}/${now.month}/${now.year}';
      }
    } else {
      reportTitle = 'Reporte de Colonoscopia - ${now.day}/${now.month}/${now.year}';
    }
    
    final newReport = {
      'id': reportId,
      'title': reportTitle,
      'date': studyDate ?? now.toIso8601String().split('T')[0],
      'status': 'Completado',
      'result': result,
      'stage': stage,
      'confidence': confidence,
      'riskLevel': riskLevel,
      'createdAt': now.toIso8601String(),
      'backendId': null, // Se actualizará cuando se guarde en el backend
      // Agregar información adicional si está disponible
      if (patientId != null) 'patientId': patientId,
      if (doctorName != null && doctorName.isNotEmpty) 'doctorName': doctorName,
      if (observations != null && observations.isNotEmpty) 'observations': observations,
      if (studyDate != null && studyDate.isNotEmpty) 'studyDate': studyDate,
      if (imagePath != null && imagePath.isNotEmpty) 'imagePath': imagePath,
    };

    // Agregar al inicio de la lista
    _reports.insert(0, newReport);

    print('✅ Reporte agregado en memoria: ${newReport['title']}');
    print('📋 ID del reporte: $reportId');
    print('📊 Total de reportes en memoria: ${_reports.length}');
    
    // Guardar en almacenamiento local inmediatamente
    try {
      await _saveReportsToStorage();
      print('✅ Reporte guardado exitosamente en almacenamiento local');
    } catch (e) {
      print('❌ Error guardando reporte localmente: $e');
      // Intentar guardar de nuevo después de un breve delay
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await _saveReportsToStorage();
        print('✅ Reporte guardado localmente en segundo intento');
      } catch (e2) {
        print('❌ Error crítico: No se pudo guardar el reporte localmente después de 2 intentos: $e2');
      }
    }
    
    // Guardar en el backend (persistencia permanente)
    try {
      print('🌐 Intentando guardar reporte en el backend...');
      // Convertir ruta relativa a absoluta si es necesario para el backend
      String? backendImagePath = imagePath;
      if (imagePath != null && imagePath.isNotEmpty && !imagePath.startsWith('/')) {
        try {
          // Si es una ruta relativa, convertirla a absoluta
          final absolutePath = await ImageStorageService.getAbsolutePath(imagePath);
          backendImagePath = absolutePath;
        } catch (e) {
          print('⚠️ Error convirtiendo ruta de imagen: $e');
          // Usar la ruta original si falla la conversión
        }
      }
      
      final response = await _studyService.createStudy(
        result: result,
        stage: stage,
        confidence: confidence,
        riskLevel: riskLevel,
        patientId: patientId,
        userId: userId,
        imagePath: backendImagePath,
        studyDate: studyDate ?? now.toIso8601String().split('T')[0],
        doctorName: doctorName,
        observations: observations,
      );
      
      if (response.success && response.data != null) {
        // Actualizar el reporte local con el ID del backend
        final backendId = response.data!['id'];
        newReport['backendId'] = backendId;
        newReport['backendCreatedAt'] = response.data!['created_at'];
        
        // Guardar nuevamente con el ID del backend
        await _saveReportsToStorage();
        print('✅ Reporte guardado exitosamente en el backend (ID: $backendId)');
      } else {
        print('⚠️ No se pudo guardar en el backend: ${response.message}');
        print('⚠️ El reporte se mantiene solo en almacenamiento local');
      }
    } catch (e) {
      print('❌ Error guardando reporte en el backend: $e');
      print('⚠️ El reporte se mantiene solo en almacenamiento local');
      // No lanzar excepción - el reporte ya está guardado localmente
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

