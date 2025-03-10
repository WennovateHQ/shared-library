import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared/config/app_config.dart';

enum LogLevel {
  debug,
  info,
  warn,
  error,
  fatal
}

class LogEntry {
  final DateTime timestamp;
  final String tag;
  final LogLevel level;
  final String message;
  final String? stackTrace;
  
  LogEntry({
    required this.timestamp,
    required this.tag,
    required this.level,
    required this.message,
    this.stackTrace,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'tag': tag,
      'level': level.toString().split('.').last,
      'message': message,
      'stackTrace': stackTrace,
    };
  }
  
  @override
  String toString() {
    final levelStr = level.toString().split('.').last.toUpperCase();
    final baseString = '${timestamp.toIso8601String()} [$levelStr] $tag: $message';
    if (stackTrace != null) {
      return '$baseString\n$stackTrace';
    }
    return baseString;
  }
}

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  static LoggingService get instance => _instance;
  
  final String tag;
  bool _initialized = false;
  File? _logFile;
  final StreamController<LogEntry> _logStreamController = StreamController<LogEntry>.broadcast();
  
  // Configurable options
  LogLevel _minimumLogLevel = LogLevel.debug;
  bool _consoleOutput = true;
  bool _fileOutput = true;
  bool _remoteLogging = false;
  final int _maxLogFiles = 5;
  final int _maxLogSize = 1024 * 1024 * 5; // 5MB
  
  // For factory constructor with tag
  factory LoggingService(String tag) {
    return LoggingService._withTag(tag);
  }
  
  // Internal singleton constructor
  LoggingService._internal() : tag = 'App' {
    _init();
  }
  
  // Constructor with custom tag
  LoggingService._withTag(this.tag) {
    // Ensure instance is initialized
    if (!_instance._initialized) {
      _instance._init();
    }
  }
  
  // Initialize the logging service
  Future<void> _init() async {
    if (_initialized) return;
    
    try {
      // Set minimum log level based on environment
      _minimumLogLevel = AppConfig.environment == 'production' 
          ? LogLevel.info 
          : LogLevel.debug;
      
      // Setup file logging if enabled
      if (_fileOutput) {
        await _setupFileLogging();
      }
      
      _initialized = true;
    } catch (e) {
      // Fall back to console only if initialization fails
      print('Failed to initialize logging: $e');
      _fileOutput = false;
      _initialized = true;
    }
  }
  
  // Setup file logging
  Future<void> _setupFileLogging() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      
      // Create log directory if it doesn't exist
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      // Create or open log file
      final now = DateTime.now();
      final fileName = 'freshfarmily_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.log';
      _logFile = File('${logDir.path}/$fileName');
      
      // Check if we need to rotate logs
      await _rotateLogsIfNeeded();
    } catch (e) {
      _fileOutput = false;
      print('Error setting up file logging: $e');
    }
  }
  
  // Rotate logs if current log is too big or if there are too many log files
  Future<void> _rotateLogsIfNeeded() async {
    try {
      if (_logFile == null) return;
      
      // Check if current log file is too big
      if (await _logFile!.exists() && await _logFile!.length() > _maxLogSize) {
        // Rename with timestamp
        final now = DateTime.now();
        final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
        final newPath = _logFile!.path.replaceFirst('.log', '_$timestamp.log');
        await _logFile!.rename(newPath);
        
        // Create a new log file
        _logFile = File(_logFile!.path);
      }
      
      // Check if we have too many log files and delete oldest
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      final logFiles = await logDir.list().where((entity) => 
          entity is File && entity.path.endsWith('.log')).toList();
      
      if (logFiles.length > _maxLogFiles) {
        // Sort by modified time
        logFiles.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        
        // Delete oldest files
        final filesToDelete = logFiles.take(logFiles.length - _maxLogFiles);
        for (var file in filesToDelete) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error rotating logs: $e');
    }
  }
  
  // Get log stream
  Stream<LogEntry> get logStream => _logStreamController.stream;
  
  // Configure the logging service
  void configure({
    LogLevel? minimumLogLevel,
    bool? consoleOutput,
    bool? fileOutput,
    bool? remoteLogging,
  }) {
    if (minimumLogLevel != null) _minimumLogLevel = minimumLogLevel;
    if (consoleOutput != null) _consoleOutput = consoleOutput;
    if (fileOutput != null) {
      final wasFileOutput = _fileOutput;
      _fileOutput = fileOutput;
      
      // If file output was turned on, setup file logging
      if (!wasFileOutput && fileOutput) {
        _setupFileLogging();
      }
    }
    if (remoteLogging != null) _remoteLogging = remoteLogging;
  }
  
  // Log a message
  void log(LogLevel level, String message, {Object? error, StackTrace? stackTrace}) {
    // Skip if below minimum log level
    if (level.index < _minimumLogLevel.index) return;
    
    final now = DateTime.now();
    String? stackTraceStr;
    
    // Format stack trace if available
    if (stackTrace != null) {
      stackTraceStr = stackTrace.toString();
    } else if (error != null && error is Error) {
      stackTraceStr = error.stackTrace?.toString();
    }
    
    // Create log entry
    final entry = LogEntry(
      timestamp: now,
      tag: tag,
      level: level,
      message: message,
      stackTrace: stackTraceStr,
    );
    
    // Add to stream
    _logStreamController.add(entry);
    
    // Console output
    if (_consoleOutput) {
      if (kDebugMode) {
        print(entry.toString());
      }
    }
    
    // File output
    if (_fileOutput && _logFile != null) {
      _writeToFile(entry);
    }
    
    // Remote logging
    if (_remoteLogging) {
      _sendToRemoteLogging(entry);
    }
  }
  
  // Write log entry to file
  Future<void> _writeToFile(LogEntry entry) async {
    try {
      if (_logFile == null) return;
      
      // Ensure file exists
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }
      
      // Write log entry
      await _logFile!.writeAsString('${entry.toString()}\n', 
        mode: FileMode.append, flush: true);
        
      // Check if we need to rotate logs
      if (await _logFile!.length() > _maxLogSize) {
        await _rotateLogsIfNeeded();
      }
    } catch (e) {
      // If file logging fails, fall back to console
      if (_consoleOutput) {
        print('Error writing to log file: $e');
        print(entry.toString());
      }
    }
  }
  
  // Send log entry to remote logging service
  Future<void> _sendToRemoteLogging(LogEntry entry) async {
    // Only send warnings, errors and fatal logs to remote
    if (entry.level.index < LogLevel.warn.index) return;
    
    try {
      // This would be implemented to send logs to a remote service
      // For now, just a placeholder
    } catch (e) {
      if (_consoleOutput) {
        print('Error sending log to remote service: $e');
      }
    }
  }
  
  // Helper methods for different log levels
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    log(LogLevel.debug, message, error: error, stackTrace: stackTrace);
  }
  
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    log(LogLevel.info, message, error: error, stackTrace: stackTrace);
  }
  
  void warn(String message, {Object? error, StackTrace? stackTrace}) {
    log(LogLevel.warn, message, error: error, stackTrace: stackTrace);
  }
  
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }
  
  void fatal(String message, {Object? error, StackTrace? stackTrace}) {
    log(LogLevel.fatal, message, error: error, stackTrace: stackTrace);
  }
  
  // Export logs as JSON
  Future<String> exportLogs() async {
    try {
      if (_logFile == null || !await _logFile!.exists()) {
        return '[]';
      }
      
      final logContent = await _logFile!.readAsString();
      final logEntries = logContent.split('\n')
          .where((line) => line.isNotEmpty)
          .map((line) {
            try {
              // Parse log entry from line
              final match = RegExp(r'(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3,6}Z?) \[(DEBUG|INFO|WARN|ERROR|FATAL)\] ([^:]+): (.+)')
                  .firstMatch(line);
              
              if (match != null) {
                final timestamp = DateTime.parse(match.group(1)!);
                final level = match.group(2)!.toLowerCase();
                final tag = match.group(3)!;
                final message = match.group(4)!;
                
                LogLevel logLevel;
                switch (level) {
                  case 'debug': logLevel = LogLevel.debug; break;
                  case 'info': logLevel = LogLevel.info; break;
                  case 'warn': logLevel = LogLevel.warn; break;
                  case 'error': logLevel = LogLevel.error; break;
                  case 'fatal': logLevel = LogLevel.fatal; break;
                  default: logLevel = LogLevel.info;
                }
                
                return LogEntry(
                  timestamp: timestamp,
                  tag: tag,
                  level: logLevel,
                  message: message,
                ).toJson();
              }
              return null;
            } catch (e) {
              return null;
            }
          })
          .where((entry) => entry != null)
          .toList();
      
      return jsonEncode(logEntries);
    } catch (e) {
      print('Error exporting logs: $e');
      return '[]';
    }
  }
  
  // Clear all logs
  Future<void> clearLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      
      if (await logDir.exists()) {
        final logFiles = await logDir.list().where((entity) => 
            entity is File && entity.path.endsWith('.log')).toList();
        
        for (var file in logFiles) {
          await file.delete();
        }
      }
      
      // Create a new log file
      if (_fileOutput) {
        await _setupFileLogging();
      }
      
      info('Logs cleared');
    } catch (e) {
      print('Error clearing logs: $e');
    }
  }
  
  // Dispose of resources
  void dispose() {
    _logStreamController.close();
  }
}
