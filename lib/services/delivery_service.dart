import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../utils/api_utils.dart';
import '../utils/logging_service.dart';

/// Service for handling delivery-related functionality including tracking
/// and delivery status updates.
class DeliveryService {
  // Singleton pattern
  static final DeliveryService _instance = DeliveryService._internal();
  factory DeliveryService() => _instance;
  DeliveryService._internal();

  final LoggingService _logger = LoggingService('DeliveryService');

  /// Get delivery details for a specific order
  Future<Map<String, dynamic>> getDeliveryDetails(String orderId) async {
    try {
      _logger.debug('Getting delivery details for order: $orderId');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/deliveries/order/$orderId'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Get delivery details response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final error = json.decode(response.body);
        _logger.error('Get delivery details error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to get delivery details');
      }
    } catch (e) {
      _logger.error('Get delivery details exception: $e');
      rethrow;
    }
  }

  /// Get real-time tracking information for a delivery
  Future<Map<String, dynamic>> trackDelivery(String trackingId) async {
    try {
      _logger.debug('Tracking delivery: $trackingId');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/deliveries/track/$trackingId'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Track delivery response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final error = json.decode(response.body);
        _logger.error('Track delivery error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to track delivery');
      }
    } catch (e) {
      _logger.error('Track delivery exception: $e');
      rethrow;
    }
  }

  /// Get all available deliveries (for driver app)
  Future<List<Map<String, dynamic>>> getAvailableDeliveries() async {
    try {
      _logger.debug('Getting available deliveries');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/deliveries/available'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Get available deliveries response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['deliveries'] ?? [];
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        final error = json.decode(response.body);
        _logger.error('Get available deliveries error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to get available deliveries');
      }
    } catch (e) {
      _logger.error('Get available deliveries exception: $e');
      rethrow;
    }
  }

  /// Accept a delivery (for driver app)
  Future<Map<String, dynamic>> acceptDelivery(String deliveryId) async {
    try {
      _logger.debug('Accepting delivery: $deliveryId');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/deliveries/$deliveryId/accept'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Accept delivery response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final error = json.decode(response.body);
        _logger.error('Accept delivery error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to accept delivery');
      }
    } catch (e) {
      _logger.error('Accept delivery exception: $e');
      rethrow;
    }
  }

  /// Update delivery status (for driver app)
  Future<Map<String, dynamic>> updateDeliveryStatus({
    required String deliveryId, 
    required String status,
    Map<String, dynamic>? statusDetails,
  }) async {
    try {
      _logger.debug('Updating delivery status: $deliveryId to $status');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final data = {
        'status': status,
        if (statusDetails != null) 'details': statusDetails,
      };

      final response = await http.put(
        Uri.parse('${FreshConfig.apiUrl}/deliveries/$deliveryId/status'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      _logger.debug('Update delivery status response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final error = json.decode(response.body);
        _logger.error('Update delivery status error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to update delivery status');
      }
    } catch (e) {
      _logger.error('Update delivery status exception: $e');
      rethrow;
    }
  }

  /// Complete a delivery (for driver app)
  Future<Map<String, dynamic>> completeDelivery({
    required String deliveryId,
    String? signatureImagePath,
    String? notes,
  }) async {
    try {
      _logger.debug('Completing delivery: $deliveryId');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final data = {
        if (signatureImagePath != null) 'signature_image': signatureImagePath,
        if (notes != null) 'notes': notes,
      };

      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/deliveries/$deliveryId/complete'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      _logger.debug('Complete delivery response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final error = json.decode(response.body);
        _logger.error('Complete delivery error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to complete delivery');
      }
    } catch (e) {
      _logger.error('Complete delivery exception: $e');
      rethrow;
    }
  }

  /// Get delivery history (for driver app)
  Future<List<Map<String, dynamic>>> getDeliveryHistory() async {
    try {
      _logger.debug('Getting delivery history');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/deliveries/history'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Get delivery history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['deliveries'] ?? [];
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        final error = json.decode(response.body);
        _logger.error('Get delivery history error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to get delivery history');
      }
    } catch (e) {
      _logger.error('Get delivery history exception: $e');
      rethrow;
    }
  }

  /// Get delivery statistics (for driver app)
  Future<Map<String, dynamic>> getDeliveryStats() async {
    try {
      _logger.debug('Getting delivery statistics');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/deliveries/stats'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Get delivery stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final error = json.decode(response.body);
        _logger.error('Get delivery stats error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to get delivery statistics');
      }
    } catch (e) {
      _logger.error('Get delivery stats exception: $e');
      rethrow;
    }
  }

  /// Update driver location (for driver app)
  Future<bool> updateDriverLocation(double latitude, double longitude) async {
    try {
      _logger.debug('Updating driver location: $latitude, $longitude');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final data = {
        'latitude': latitude,
        'longitude': longitude,
      };

      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/drivers/location'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      _logger.debug('Update driver location response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        _logger.error('Update driver location error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to update driver location');
      }
    } catch (e) {
      _logger.error('Update driver location exception: $e');
      rethrow;
    }
  }

  /// Rate delivery (for consumer app)
  Future<Map<String, dynamic>> rateDelivery({
    required String deliveryId, 
    required int rating, 
    String? comment,
  }) async {
    try {
      _logger.debug('Rating delivery: $deliveryId with rating: $rating');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final data = {
        'rating': rating,
        if (comment != null) 'comment': comment,
      };

      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/deliveries/$deliveryId/rate'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      _logger.debug('Rate delivery response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final error = json.decode(response.body);
        _logger.error('Rate delivery error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to rate delivery');
      }
    } catch (e) {
      _logger.error('Rate delivery exception: $e');
      rethrow;
    }
  }
}
