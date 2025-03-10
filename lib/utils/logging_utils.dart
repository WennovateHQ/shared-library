import 'dart:developer' as developer;
import 'package:shared/config.dart';

class LoggingUtils {
  static bool get _isDebugMode => FreshConfig.debugMode;

  static void logInfo(String message, {String? tag}) {
    if (_isDebugMode) {
      _log('INFO', message, tag: tag);
    }
  }

  static void logWarning(String message, {String? tag}) {
    if (_isDebugMode) {
      _log('WARNING', message, tag: tag);
    }
  }

  static void logError(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_isDebugMode) {
      _log('ERROR', message, tag: tag);
      if (error != null) {
        developer.log('ERROR: $error', name: tag ?? 'FreshFarmily');
      }
      if (stackTrace != null) {
        developer.log('STACK: $stackTrace', name: tag ?? 'FreshFarmily');
      }
    }
  }

  static void _log(String level, String message, {String? tag}) {
    final logTag = tag ?? 'FreshFarmily';
    developer.log('[$level] $message', name: logTag);
  }
}

// Extension methods for easy logging from any class
extension LoggingExtension on Object {
  void logInfo(String message, {String? tag}) {
    LoggingUtils.logInfo('[$runtimeType] $message', tag: tag);
  }

  void logWarning(String message, {String? tag}) {
    LoggingUtils.logWarning('[$runtimeType] $message', tag: tag);
  }

  void logError(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    LoggingUtils.logError('[$runtimeType] $message', tag: tag, error: error, stackTrace: stackTrace);
  }
}
