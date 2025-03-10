import 'dart:io';

class ApiConfig {
  // API versions
  static const String apiVersion = 'api';  // Changed to match our Node.js backend route structure
  
  // Environment configurations
  static const String _environment = 'development'; // Change to 'production' for deployment
  
  // Helper getters for environment checks
  static bool get isDevelopment => _environment == 'development';
  static bool get isProduction => _environment == 'production';
  static bool get isStaging => _environment == 'staging';
  
  // Base URLs for different environments
  static const String _productionUrl = 'https://api.freshfarmily.com';
  static const String _stagingUrl = 'https://staging-api.freshfarmily.com';
  
  // Get the base URL without version path (our Node.js backend already has /api in the routes)
  static String get baseUrl {
    switch (_environment) {
      case 'production':
        return _productionUrl;
      case 'staging':
        return _stagingUrl;
      case 'development':
      default:
        // Special address for Android emulator to reach host machine's localhost
        return Platform.isAndroid ? 'http://10.0.2.2:8001' : 'http://localhost:8001';
    }
  }
  
  // Get the route optimization URL with version path
  static String get routeOptimizationUrl => '${_environment == 'production' ? 'https://route-optimizer.freshfarmily.com' : _environment == 'staging' ? 'https://staging-route-optimizer.freshfarmily.com' : 'http://10.0.2.2:8001'}/$apiVersion';
  
  // API timeout durations
  static const int connectionTimeout = 10000; // 10 seconds
  static const int receiveTimeout = 15000; // 15 seconds
  
  // API endpoints based on our Node.js backend structure
  static const String authEndpoint = '/api/auth';
  static const String productsEndpoint = '/api/products';
  static const String ordersEndpoint = '/api/orders';
  static const String deliveriesEndpoint = '/api/deliveries';
  static const String farmsEndpoint = '/api/farms';
  static const String usersEndpoint = '/api/users';
  
  // Route optimization endpoints
  static const String routeOptimizeEndpoint = '/optimize';
  static const String routeStatusEndpoint = '/status';
  static const String routeDetailsEndpoint = '/route';
  static const String driverLocationEndpoint = '/driver/location';
  static const String heatmapEndpoint = '/analytics/heatmap';
  
  // Build full endpoint URLs
  static String getFullUrl(String endpoint) => '$baseUrl$endpoint';
  static String getRouteOptimizationUrl(String endpoint) => '$routeOptimizationUrl$endpoint';
}
