import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class ReportService {
  static const String _reportsFilePath = 'assets/data/reports.json';
  static List<Map<String, dynamic>> _reports = [];

  /// Cargar reportes desde el archivo JSON
  static Future<void> loadReports() async {
    try {
      final String jsonString = await rootBundle.loadString(_reportsFilePath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final fileReports = List<Map<String, dynamic>>.from(jsonData['reports'] ?? []);
      
      // Solo cargar reportes del archivo si no hay reportes en memoria
      if (_reports.isEmpty) {
        _reports = fileReports;
        print('📂 Reportes cargados desde archivo: ${_reports.length}');
      } else {
        print('📊 Manteniendo reportes en memoria: ${_reports.length} (archivo ignorado)');
      }
    } catch (e) {
      print('⚠️ Error cargando reportes desde archivo: $e');
      // Mantener los reportes que ya están en memoria
      print('📊 Manteniendo reportes en memoria: ${_reports.length}');
    }
  }

  /// Obtener todos los reportes
  static List<Map<String, dynamic>> getAllReports() {
    // Si no hay reportes, agregar algunos de ejemplo
    if (_reports.isEmpty) {
      _initializeSampleReports();
    }
    return List.from(_reports);
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
    };

    _reports.insert(0, newReport); // Agregar al inicio de la lista

    print('✅ Reporte agregado al historial: ${newReport['title']}');
    print('📊 Total de reportes en memoria después: ${_reports.length}');
    
    // Mostrar todos los reportes para debugging
    for (int i = 0; i < _reports.length; i++) {
      print('📋 Reporte $i: ${_reports[i]['title']} - ${_reports[i]['result']}');
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
