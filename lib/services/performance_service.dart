// import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class PerformanceService {
  // static final FirebasePerformance _performance = FirebasePerformance.instance;
  static final Map<String, Stopwatch> _stopwatches = {};

  /// Medir tiempo de inicio de la aplicación (versión local)
  static void startMeasurement(String traceName) {
    _stopwatches[traceName] = Stopwatch()..start();
    if (kDebugMode) {
      debugPrint('🕐 Iniciando medición: $traceName');
    }
  }

  /// Detener medición y mostrar resultado
  static void stopMeasurement(String traceName) {
    final stopwatch = _stopwatches[traceName];
    if (stopwatch != null) {
      stopwatch.stop();
      final milliseconds = stopwatch.elapsedMilliseconds;
      if (kDebugMode) {
        debugPrint('⏱️ $traceName completado en: ${milliseconds}ms (${(milliseconds/1000).toStringAsFixed(2)}s)');
      }
      _stopwatches.remove(traceName);
    }
  }

  /// Medir tiempo de login
  static Future<T> measureLogin<T>(Future<T> Function() loginFunction) async {
    const traceName = 'user_login';
    startMeasurement(traceName);
    
    try {
      final result = await loginFunction();
      stopMeasurement(traceName);
      return result;
    } catch (e) {
      stopMeasurement(traceName);
      if (kDebugMode) {
        debugPrint('❌ Login falló: $e');
      }
      rethrow;
    }
  }

  /// Medir tiempo de carga de pantallas
  static Future<T> measureScreenLoad<T>(
    String screenName, 
    Future<T> Function() loadFunction
  ) async {
    final traceName = 'screen_load_$screenName';
    startMeasurement(traceName);
    
    try {
      final result = await loadFunction();
      stopMeasurement(traceName);
      return result;
    } catch (e) {
      stopMeasurement(traceName);
      if (kDebugMode) {
        debugPrint('❌ Carga de pantalla $screenName falló: $e');
      }
      rethrow;
    }
  }

  /// Medir tiempo de operaciones de base de datos
  static Future<T> measureDatabaseOperation<T>(
    String operationName,
    Future<T> Function() operation
  ) async {
    final traceName = 'db_$operationName';
    startMeasurement(traceName);
    
    try {
      final result = await operation();
      stopMeasurement(traceName);
      return result;
    } catch (e) {
      stopMeasurement(traceName);
      if (kDebugMode) {
        debugPrint('❌ Operación de BD $operationName falló: $e');
      }
      rethrow;
    }
  }

  /// Medir tiempo de carga de imágenes
  static Future<T> measureImageLoad<T>(
    Future<T> Function() imageLoadFunction
  ) async {
    const traceName = 'image_load';
    startMeasurement(traceName);
    
    try {
      final result = await imageLoadFunction();
      stopMeasurement(traceName);
      return result;
    } catch (e) {
      stopMeasurement(traceName);
      if (kDebugMode) {
        debugPrint('❌ Carga de imagen falló: $e');
      }
      rethrow;
    }
  }

  /// Crear métricas personalizadas (versión local)
  static void recordCustomMetric(String metricName, int value) {
    if (kDebugMode) {
      debugPrint('📊 Métrica personalizada: $metricName = $value');
    }
  }

  /// Medir tiempo de navegación entre pantallas
  static void measureNavigation(String fromScreen, String toScreen) {
    if (kDebugMode) {
      debugPrint('🧭 Navegación: $fromScreen → $toScreen');
    }
  }

  /// Obtener estadísticas locales
  static void printPerformanceStats() {
    if (kDebugMode) {
      debugPrint('📈 === ESTADÍSTICAS DE RENDIMIENTO ===');
      debugPrint('Mediciones activas: ${_stopwatches.length}');
      for (final entry in _stopwatches.entries) {
        debugPrint('  ${entry.key}: ${entry.value.elapsedMilliseconds}ms');
      }
    }
  }
} 