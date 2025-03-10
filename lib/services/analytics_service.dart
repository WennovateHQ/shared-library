import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared/models/analytics_data.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/config/api_config.dart';
import 'package:shared/utils/cache_manager.dart';

class AnalyticsService {
  final String _baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();
  final CacheManager _cacheManager = CacheManager();
  
  // Cache expiration in minutes
  final int _cacheExpirationMinutes = 30;

  // Get sales analytics data
  Future<SalesAnalytics> getSalesAnalytics({
    required String timeRange,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'sales_analytics_$timeRange';
    
    // Check if we have cached data and it's not a forced refresh
    if (!forceRefresh) {
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null) {
        return SalesAnalytics.fromJson(jsonDecode(cachedData));
      }
    }
    
    // No cache or forced refresh, fetch from API
    final token = await _authService.getAccessToken();
    
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.get(
      Uri.parse('$_baseUrl/analytics/sales?timeRange=$timeRange'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Cache the response
      await _cacheManager.set(
        cacheKey, 
        response.body, 
        expiration: Duration(minutes: _cacheExpirationMinutes),
      );
      
      return SalesAnalytics.fromJson(data);
    } else {
      throw Exception('Failed to load sales analytics: ${response.statusCode}');
    }
  }
  
  // Get customer analytics data
  Future<CustomerAnalytics> getCustomerAnalytics({
    required String timeRange,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'customer_analytics_$timeRange';
    
    // Check if we have cached data and it's not a forced refresh
    if (!forceRefresh) {
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null) {
        return CustomerAnalytics.fromJson(jsonDecode(cachedData));
      }
    }
    
    // No cache or forced refresh, fetch from API
    final token = await _authService.getAccessToken();
    
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.get(
      Uri.parse('$_baseUrl/analytics/customers?timeRange=$timeRange'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Cache the response
      await _cacheManager.set(
        cacheKey, 
        response.body, 
        expiration: Duration(minutes: _cacheExpirationMinutes),
      );
      
      return CustomerAnalytics.fromJson(data);
    } else {
      throw Exception('Failed to load customer analytics: ${response.statusCode}');
    }
  }
  
  // Get product analytics data
  Future<ProductAnalytics> getProductAnalytics({
    required String timeRange,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'product_analytics_$timeRange';
    
    // Check if we have cached data and it's not a forced refresh
    if (!forceRefresh) {
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null) {
        return ProductAnalytics.fromJson(jsonDecode(cachedData));
      }
    }
    
    // No cache or forced refresh, fetch from API
    final token = await _authService.getAccessToken();
    
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.get(
      Uri.parse('$_baseUrl/analytics/products?timeRange=$timeRange'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Cache the response
      await _cacheManager.set(
        cacheKey, 
        response.body, 
        expiration: Duration(minutes: _cacheExpirationMinutes),
      );
      
      return ProductAnalytics.fromJson(data);
    } else {
      throw Exception('Failed to load product analytics: ${response.statusCode}');
    }
  }
  
  // Get export data (for CSV/Excel export)
  Future<String> getExportData({
    required String type,
    required String timeRange,
    String format = 'csv',
  }) async {
    final token = await _authService.getAccessToken();
    
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.get(
      Uri.parse('$_baseUrl/analytics/export?type=$type&timeRange=$timeRange&format=$format'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to export analytics data: ${response.statusCode}');
    }
  }
  
  // Get inventory alerts
  Future<List<InventoryStatus>> getInventoryAlerts() async {
    final token = await _authService.getAccessToken();
    
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.get(
      Uri.parse('$_baseUrl/analytics/inventory/alerts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((item) => InventoryStatus.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load inventory alerts: ${response.statusCode}');
    }
  }

  // For testing and development - generate mock data
  // This is useful for developing the UI before the backend is complete
  Future<SalesAnalytics> getMockSalesAnalytics({required String timeRange}) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    return SalesAnalytics(
      totalRevenue: 8750.50,
      totalOrders: 235,
      averageOrderValue: 37.24,
      conversionRate: 0.065,
      revenueOverTime: _generateMockRevenueData(timeRange),
      topProducts: [
        ProductSalesData(id: '1', name: 'Organic Tomatoes', unitsSold: 345, revenue: 1380.0),
        ProductSalesData(id: '2', name: 'Fresh Eggs', unitsSold: 230, revenue: 920.0),
        ProductSalesData(id: '3', name: 'Honey', unitsSold: 120, revenue: 840.0),
        ProductSalesData(id: '4', name: 'Kale', unitsSold: 210, revenue: 630.0),
        ProductSalesData(id: '5', name: 'Carrots', unitsSold: 280, revenue: 560.0),
      ],
    );
  }
  
  Future<CustomerAnalytics> getMockCustomerAnalytics({required String timeRange}) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    return CustomerAnalytics(
      totalCustomers: 420,
      newCustomers: 45,
      returningRate: 0.72,
      averageSatisfaction: 4.3,
      demographics: [
        DemographicData(group: 'Urban', percentage: 45.0),
        DemographicData(group: 'Suburban', percentage: 38.0),
        DemographicData(group: 'Rural', percentage: 17.0),
      ],
      topLocations: [
        LocationData(name: 'San Francisco', customers: 85, percentage: 20.2),
        LocationData(name: 'Oakland', customers: 62, percentage: 14.8),
        LocationData(name: 'San Jose', customers: 58, percentage: 13.8),
        LocationData(name: 'Berkeley', customers: 45, percentage: 10.7),
        LocationData(name: 'Palo Alto', customers: 40, percentage: 9.5),
      ],
    );
  }
  
  Future<ProductAnalytics> getMockProductAnalytics({required String timeRange}) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    return ProductAnalytics(
      totalProducts: 78,
      averageRating: 4.2,
      stockOuts: 3,
      lowStock: 8,
      productPerformance: [
        ProductPerformance(id: '1', name: 'Organic Tomatoes', performance: 87.5),
        ProductPerformance(id: '2', name: 'Fresh Eggs', performance: 82.3),
        ProductPerformance(id: '3', name: 'Honey', performance: 75.8),
        ProductPerformance(id: '4', name: 'Kale', performance: 68.2),
        ProductPerformance(id: '5', name: 'Carrots', performance: 65.9),
      ],
      inventoryStatus: [
        InventoryStatus(id: '1', name: 'Organic Tomatoes', stockLevel: 42),
        InventoryStatus(id: '2', name: 'Fresh Eggs', stockLevel: 120),
        InventoryStatus(id: '3', name: 'Honey', stockLevel: 8),
        InventoryStatus(id: '4', name: 'Kale', stockLevel: 15),
        InventoryStatus(id: '5', name: 'Carrots', stockLevel: 53),
        InventoryStatus(id: '6', name: 'Apples', stockLevel: 0),
        InventoryStatus(id: '7', name: 'Basil', stockLevel: 3),
      ],
    );
  }
  
  List<double> _generateMockRevenueData(String timeRange) {
    final random = DateTime.now().millisecondsSinceEpoch;
    int dataPoints;
    
    switch (timeRange) {
      case 'day':
        dataPoints = 12; // Hours in a day
        break;
      case 'week':
        dataPoints = 7; // Days in a week
        break;
      case 'month':
        dataPoints = 30; // Days in a month
        break;
      case 'year':
        dataPoints = 12; // Months in a year
        break;
      default:
        dataPoints = 7;
    }
    
    // Generate random data with a trend
    return List.generate(dataPoints, (index) {
      final base = 500.0 + (index * 20.0);
      final variance = (random % 100) / 100.0 * 200.0;
      return base + variance;
    });
  }
}
