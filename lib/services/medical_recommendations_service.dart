/// Servicio para generar recomendaciones médicas realistas basadas en análisis de colonoscopia
class MedicalRecommendationsService {
  /// Genera recomendaciones médicas basadas en el resultado del análisis
  static String generateRecommendations({
    required String result,
    required String stage,
    required String riskLevel,
    required double confidence,
  }) {
    final resultLower = result.toLowerCase();
    final riskLower = riskLevel.toLowerCase();

    // Recomendaciones basadas en el resultado
    if (resultLower.contains('cáncer') ||
        resultLower.contains('tumor') ||
        resultLower.contains('maligno')) {
      return _getCancerRecommendations(stage, riskLower, confidence);
    } else if (resultLower.contains('pólipo') ||
        resultLower.contains('polipo')) {
      return _getPolypRecommendations(stage, riskLower, confidence);
    } else if (resultLower.contains('anomalía') ||
        resultLower.contains('anomalia')) {
      return _getAnomalyRecommendations(stage, riskLower, confidence);
    } else if (resultLower.contains('normal') ||
        resultLower.contains('benigno') ||
        resultLower.contains('sin anomalías')) {
      return _getNormalRecommendations(confidence);
    } else {
      return _getGeneralRecommendations(riskLower, confidence);
    }
  }

  /// Genera interpretación clínica detallada
  static String generateClinicalInterpretation({
    required String result,
    required String stage,
    required String riskLevel,
    required double confidence,
  }) {
    final resultLower = result.toLowerCase();
    final riskLower = riskLevel.toLowerCase();
    final confidencePercent = (confidence * 100).toStringAsFixed(1);

    String interpretation = 'INTERPRETACIÓN CLÍNICA:\n\n';

    // Interpretación del resultado
    if (resultLower.contains('cáncer') || resultLower.contains('tumor')) {
      interpretation +=
          'Se detectaron hallazgos compatibles con neoplasia maligna en el colon. ';
      interpretation +=
          'El nivel de confianza del análisis es del $confidencePercent%. ';

      if (riskLower.contains('alto')) {
        interpretation +=
            'Se requiere atención médica inmediata y evaluación por oncología. ';
        interpretation +=
            'Se recomienda realizar estudios complementarios (biopsia, estadificación) ';
        interpretation +=
            'para confirmar el diagnóstico y determinar el estadio de la enfermedad.\n\n';
      } else {
        interpretation +=
            'Se recomienda evaluación urgente por especialista en gastroenterología ';
        interpretation +=
            'y oncología para confirmación diagnóstica y plan de tratamiento.\n\n';
      }
    } else if (resultLower.contains('pólipo') ||
        resultLower.contains('polipo')) {
      interpretation += 'Se identificaron lesiones polipoideas en el colon. ';
      interpretation +=
          'El nivel de confianza del análisis es del $confidencePercent%. ';

      if (riskLower.contains('alto') || riskLower.contains('medio')) {
        interpretation +=
            'Se recomienda evaluación endoscópica completa y posible polipectomía. ';
        interpretation +=
            'El análisis histopatológico determinará si se trata de pólipos adenomatosos ';
        interpretation +=
            'o hiperplásicos, lo cual influirá en el seguimiento.\n\n';
      } else {
        interpretation +=
            'Se recomienda seguimiento según las guías clínicas establecidas.\n\n';
      }
    } else if (resultLower.contains('anomalía') ||
        resultLower.contains('anomalia')) {
      interpretation +=
          'Se detectaron alteraciones en la mucosa colónica que requieren evaluación. ';
      interpretation +=
          'El nivel de confianza del análisis es del $confidencePercent%. ';
      interpretation +=
          'Se recomienda correlación clínica y posible repetición del estudio ';
      interpretation +=
          'o evaluación endoscópica adicional para caracterización precisa.\n\n';
    } else {
      interpretation +=
          'No se detectaron anomalías significativas en el análisis. ';
      interpretation +=
          'El nivel de confianza del análisis es del $confidencePercent%. ';
      interpretation +=
          'Se recomienda seguimiento según protocolos de prevención establecidos.\n\n';
    }

    // Interpretación del nivel de confianza
    if (confidence >= 0.9) {
      interpretation +=
          'El nivel de confianza es alto, lo que sugiere alta precisión del análisis.';
    } else if (confidence >= 0.7) {
      interpretation +=
          'El nivel de confianza es moderado-alto. Se recomienda correlación con otros estudios.';
    } else if (confidence >= 0.5) {
      interpretation +=
          'El nivel de confianza es moderado. Se recomienda evaluación clínica adicional.';
    } else {
      interpretation +=
          'El nivel de confianza es bajo. Se recomienda repetición del estudio o evaluación complementaria.';
    }

    return interpretation;
  }

  /// Genera plan de seguimiento
  static String generateFollowUpPlan({
    required String result,
    required String riskLevel,
  }) {
    final resultLower = result.toLowerCase();
    final riskLower = riskLevel.toLowerCase();

    String plan = 'PLAN DE SEGUIMIENTO:\n\n';

    if (resultLower.contains('cáncer') || resultLower.contains('tumor')) {
      plan +=
          '1. Confirmación diagnóstica mediante biopsia y análisis histopatológico\n';
      plan += '2. Estadificación completa (TNM) mediante estudios de imagen\n';
      plan +=
          '3. Evaluación multidisciplinaria (oncología, cirugía, gastroenterología)\n';
      plan +=
          '4. Plan de tratamiento según estadio y características del paciente\n';
      plan += '5. Seguimiento estrecho post-tratamiento\n';
    } else if (resultLower.contains('pólipo') ||
        resultLower.contains('polipo')) {
      if (riskLower.contains('alto')) {
        plan += '1. Polipectomía endoscópica con análisis histopatológico\n';
        plan += '2. Colonoscopia de seguimiento en 3-6 meses\n';
        plan += '3. Evaluación de riesgo familiar y genético si corresponde\n';
      } else {
        plan += '1. Polipectomía endoscópica si es factible\n';
        plan += '2. Colonoscopia de seguimiento según guías clínicas\n';
        plan += '3. Evaluación de factores de riesgo\n';
      }
    } else if (resultLower.contains('anomalía') ||
        resultLower.contains('anomalia')) {
      plan += '1. Evaluación clínica adicional\n';
      plan += '2. Posible repetición del estudio en 3-6 meses\n';
      plan += '3. Correlación con síntomas y antecedentes del paciente\n';
    } else {
      plan += '1. Seguimiento según protocolos de prevención\n';
      plan += '2. Colonoscopia de control según edad y factores de riesgo\n';
      plan += '3. Mantener hábitos saludables y dieta balanceada\n';
    }

    return plan;
  }

  /// Recomendaciones para cáncer
  static String _getCancerRecommendations(
      String stage, String riskLevel, double confidence) {
    String recommendations = '';

    if (riskLevel.contains('alto')) {
      recommendations += '• ATENCIÓN MÉDICA INMEDIATA REQUERIDA\n';
      recommendations += '• Se recomienda evaluación urgente por oncología\n';
      recommendations +=
          '• Realizar estudios complementarios (biopsia, estadificación)\n';
      recommendations += '• Evaluación multidisciplinaria del caso\n';
    } else {
      recommendations += '• Evaluación urgente por especialista\n';
      recommendations += '• Confirmación diagnóstica mediante biopsia\n';
      recommendations += '• Plan de tratamiento según estadio\n';
    }

    if (confidence < 0.7) {
      recommendations +=
          '• NOTA: El nivel de confianza es moderado. Se recomienda confirmación diagnóstica adicional.\n';
    }

    return recommendations;
  }

  /// Recomendaciones para pólipos
  static String _getPolypRecommendations(
      String stage, String riskLevel, double confidence) {
    String recommendations = '';

    recommendations += '• Evaluación endoscópica completa recomendada\n';
    recommendations += '• Considerar polipectomía según características\n';
    recommendations += '• Análisis histopatológico de las lesiones\n';

    if (riskLevel.contains('alto') || riskLevel.contains('medio')) {
      recommendations += '• Seguimiento estrecho según guías clínicas\n';
      recommendations += '• Evaluación de riesgo familiar\n';
    }

    return recommendations;
  }

  /// Recomendaciones para anomalías
  static String _getAnomalyRecommendations(
      String stage, String riskLevel, double confidence) {
    String recommendations = '';

    recommendations += '• Evaluación clínica adicional recomendada\n';
    recommendations += '• Correlación con síntomas y antecedentes\n';

    if (riskLevel.contains('medio') || riskLevel.contains('alto')) {
      recommendations += '• Posible repetición del estudio\n';
      recommendations += '• Evaluación endoscópica complementaria\n';
    }

    return recommendations;
  }

  /// Recomendaciones para resultados normales
  static String _getNormalRecommendations(double confidence) {
    String recommendations = '';

    recommendations += '• No se detectaron anomalías significativas\n';
    recommendations += '• Continuar con seguimiento según protocolos\n';
    recommendations += '• Mantener hábitos saludables\n';

    if (confidence < 0.8) {
      recommendations += '• NOTA: Se recomienda seguimiento de rutina\n';
    }

    return recommendations;
  }

  /// Recomendaciones generales
  static String _getGeneralRecommendations(
      String riskLevel, double confidence) {
    String recommendations = '';

    if (riskLevel.contains('alto')) {
      recommendations += '• Evaluación médica urgente recomendada\n';
      recommendations += '• Estudios complementarios necesarios\n';
    } else if (riskLevel.contains('medio')) {
      recommendations += '• Evaluación médica recomendada\n';
      recommendations += '• Seguimiento según criterio clínico\n';
    } else {
      recommendations += '• Seguimiento de rutina\n';
      recommendations += '• Mantener controles periódicos\n';
    }

    return recommendations;
  }

  /// Genera análisis comparativo entre dos reportes
  static String generateComparativeAnalysis({
    required Map<String, dynamic> currentReport,
    required Map<String, dynamic> previousReport,
  }) {
    String analysis = 'ANÁLISIS COMPARATIVO:\n\n';

    final currentResult =
        (currentReport['result'] ?? '').toString().toLowerCase();
    final previousResult =
        (previousReport['result'] ?? '').toString().toLowerCase();
    final currentRisk =
        (currentReport['riskLevel'] ?? currentReport['risk_level'] ?? '')
            .toString()
            .toLowerCase();
    final previousRisk =
        (previousReport['riskLevel'] ?? previousReport['risk_level'] ?? '')
            .toString()
            .toLowerCase();
    final currentConfidence =
        _getConfidenceValue(currentReport['confidence'] ?? 0.0);
    final previousConfidence =
        _getConfidenceValue(previousReport['confidence'] ?? 0.0);

    // Comparación de resultados
    analysis += 'EVOLUCIÓN DEL RESULTADO:\n';
    if (currentResult == previousResult) {
      analysis +=
          '• El resultado se mantiene estable: ${currentReport['result']}\n';
    } else {
      analysis += '• Resultado previo: ${previousReport['result']}\n';
      analysis += '• Resultado actual: ${currentReport['result']}\n';

      // Determinar si hay mejoría o empeoramiento
      if (_isWorse(currentResult, previousResult)) {
        analysis +=
            '• ⚠️ HAY EVIDENCIA DE PROGRESIÓN. Se requiere evaluación médica inmediata.\n';
      } else if (_isBetter(currentResult, previousResult)) {
        analysis +=
            '• ✅ HAY EVIDENCIA DE MEJORÍA. Continuar con seguimiento.\n';
      }
    }

    analysis += '\nEVOLUCIÓN DEL RIESGO:\n';
    if (currentRisk == previousRisk) {
      analysis +=
          '• El nivel de riesgo se mantiene: ${currentReport['riskLevel'] ?? currentReport['risk_level']}\n';
    } else {
      analysis +=
          '• Riesgo previo: ${previousReport['riskLevel'] ?? previousReport['risk_level']}\n';
      analysis +=
          '• Riesgo actual: ${currentReport['riskLevel'] ?? currentReport['risk_level']}\n';

      if (_isRiskHigher(currentRisk, previousRisk)) {
        analysis +=
            '• ⚠️ AUMENTO DEL RIESGO DETECTADO. Se requiere atención médica.\n';
      } else {
        analysis += '• ✅ REDUCCIÓN DEL RIESGO. Evolución favorable.\n';
      }
    }

    analysis += '\nCONFIABILIDAD DEL ANÁLISIS:\n';
    analysis +=
        '• Confianza previa: ${(previousConfidence * 100).toStringAsFixed(1)}%\n';
    analysis +=
        '• Confianza actual: ${(currentConfidence * 100).toStringAsFixed(1)}%\n';

    // Calcular intervalo entre estudios
    try {
      final currentDate = DateTime.tryParse(
          currentReport['date'] ?? currentReport['createdAt'] ?? '');
      final previousDate = DateTime.tryParse(
          previousReport['date'] ?? previousReport['createdAt'] ?? '');

      if (currentDate != null && previousDate != null) {
        final difference = currentDate.difference(previousDate);
        final months = (difference.inDays / 30).round();
        analysis += '\nINTERVALO ENTRE ESTUDIOS:\n';
        analysis += '• $months meses entre estudios\n';

        if (months < 3) {
          analysis += '• Intervalo corto - seguimiento estrecho\n';
        } else if (months <= 12) {
          analysis += '• Intervalo adecuado según protocolos\n';
        } else {
          analysis +=
              '• Intervalo largo - considerar seguimiento más frecuente\n';
        }
      }
    } catch (e) {
      // Ignorar errores de fecha
    }

    return analysis;
  }

  static bool _isWorse(String current, String previous) {
    final worseKeywords = ['cáncer', 'tumor', 'maligno', 'alto'];
    final betterKeywords = ['normal', 'benigno', 'bajo'];

    final currentHasWorse = worseKeywords.any((k) => current.contains(k));
    final previousHasBetter = betterKeywords.any((k) => previous.contains(k));

    return currentHasWorse && previousHasBetter;
  }

  static bool _isBetter(String current, String previous) {
    final betterKeywords = ['normal', 'benigno', 'bajo'];
    final worseKeywords = ['cáncer', 'tumor', 'maligno', 'alto'];

    final currentHasBetter = betterKeywords.any((k) => current.contains(k));
    final previousHasWorse = worseKeywords.any((k) => previous.contains(k));

    return currentHasBetter && previousHasWorse;
  }

  static bool _isRiskHigher(String current, String previous) {
    final riskOrder = {'bajo': 1, 'medio': 2, 'alto': 3};
    final currentLevel = riskOrder[current] ?? 2;
    final previousLevel = riskOrder[previous] ?? 2;

    return currentLevel > previousLevel;
  }

  static double _getConfidenceValue(dynamic confidence) {
    if (confidence == null) return 0.0;
    if (confidence is double) return confidence;
    if (confidence is int) return confidence.toDouble();
    if (confidence is String) return double.tryParse(confidence) ?? 0.0;
    return 0.0;
  }
}
