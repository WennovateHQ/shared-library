class AppConfig {
  // App version
  static const String version = '1.0.0';
  
  // Build number, incremented for each release
  static const int buildNumber = 1;
  
  // Current environment
  static const String _environment = 'development'; // Options: 'development', 'staging', 'production'
  
  // Environment getter
  static String get environment => _environment;
  
  // Debugging options
  static bool get isDebugMode => environment != 'production';
  static bool get isProduction => environment == 'production';
  
  // Feature flags
  static const bool enableCaching = true;
  static const bool enableAnalytics = true;
  static const bool enablePushNotifications = true;
  
  // Timeouts (in milliseconds)
  static const int defaultTimeout = 30000; // 30 seconds
  
  // Cache durations (in minutes)
  static const int defaultCacheDuration = 60; // 1 hour
  
  // Maximum retry attempts for network calls
  static const int maxRetryAttempts = 3;
  
  // Logging configuration
  static const bool enableFileLogging = true;
  static const bool enableRemoteLogging = false;  // Only enable in production
  static const int maxLogSizeKb = 5120;  // 5MB maximum log size
  static const int logRetentionDays = 7;  // Keep logs for 7 days
}
