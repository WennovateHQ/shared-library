import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../utils/api_utils.dart';
import '../utils/logging_service.dart';

class PaymentService {
  // Singleton pattern
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final LoggingService _logger = LoggingService('PaymentService');

  // Create a payment intent for processing a transaction
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount, 
    required String currency,
    String? customerId,
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.debug('Creating payment intent: $amount $currency');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final data = {
        'amount': amount,
        'currency': currency,
        if (customerId != null) 'customer_id': customerId,
        if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/payments/intent'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      _logger.debug('Create payment intent response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final error = json.decode(response.body);
        _logger.error('Create payment intent error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to create payment intent');
      }
    } catch (e) {
      _logger.error('Create payment intent exception: $e');
      rethrow;
    }
  }

  // Process a payment with an existing payment method
  Future<Map<String, dynamic>> processPayment({
    required String orderId,
    required String paymentMethodId,
    required double amount,
  }) async {
    try {
      _logger.debug('Processing payment for order: $orderId');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final data = {
        'order_id': orderId,
        'payment_method_id': paymentMethodId,
        'amount': amount,
      };

      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/payments/process'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      _logger.debug('Process payment response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final error = json.decode(response.body);
        _logger.error('Process payment error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to process payment');
      }
    } catch (e) {
      _logger.error('Process payment exception: $e');
      rethrow;
    }
  }

  // Get saved payment methods for the current user
  Future<List<Map<String, dynamic>>> getSavedPaymentMethods() async {
    try {
      _logger.debug('Fetching saved payment methods');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/payments/methods'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Get payment methods response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['payment_methods'] ?? [];
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        final error = json.decode(response.body);
        _logger.error('Get payment methods error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to get payment methods');
      }
    } catch (e) {
      _logger.error('Get payment methods exception: $e');
      rethrow;
    }
  }

  // Save a new payment method
  Future<Map<String, dynamic>> savePaymentMethod({
    required String type,
    required Map<String, dynamic> details,
    bool makeDefault = false,
  }) async {
    try {
      _logger.debug('Saving payment method: $type');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final data = {
        'type': type,
        'details': details,
        'make_default': makeDefault,
      };

      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/payments/methods'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      _logger.debug('Save payment method response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final error = json.decode(response.body);
        _logger.error('Save payment method error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to save payment method');
      }
    } catch (e) {
      _logger.error('Save payment method exception: $e');
      rethrow;
    }
  }

  // Delete a saved payment method
  Future<bool> deletePaymentMethod(String paymentMethodId) async {
    try {
      _logger.debug('Deleting payment method: $paymentMethodId');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.delete(
        Uri.parse('${FreshConfig.apiUrl}/payments/methods/$paymentMethodId'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Delete payment method response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        _logger.error('Delete payment method error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to delete payment method');
      }
    } catch (e) {
      _logger.error('Delete payment method exception: $e');
      rethrow;
    }
  }

  // Get payment transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    try {
      _logger.debug('Fetching transaction history');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/payments/transactions'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Get transaction history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['transactions'] ?? [];
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        final error = json.decode(response.body);
        _logger.error('Get transaction history error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to get transaction history');
      }
    } catch (e) {
      _logger.error('Get transaction history exception: $e');
      rethrow;
    }
  }
}
