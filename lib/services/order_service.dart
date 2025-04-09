import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/order.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../models/address.dart';
import '../utils/api_utils.dart';
import '../utils/logging_service.dart';

class OrderService {
  // Singleton pattern
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();
  
  final LoggingService _logger = LoggingService('OrderService');
  
  // Get orders for the current user
  Future<List<Order>> getUserOrders() async {
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/orders'),
        headers: ApiUtils.createAuthHeaders(token),
      );
      
      _logger.debug('Get user orders response status: ${response.statusCode}');
      return ApiUtils.handleListResponse(response, (json) => Order.fromJson(json));
    });
  }
  
  // Get a specific order by ID
  Future<Order> getOrderById(String orderId) async {
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/orders/$orderId'),
        headers: ApiUtils.createAuthHeaders(token),
      );
      
      _logger.debug('Get order by ID response status: ${response.statusCode}');
      return ApiUtils.handleResponse(response, (json) => Order.fromJson(json));
    });
  }
  
  // Create a new order
  Future<Order> createOrder({
    required String farmId,
    required List<CartItem> items,
    required Address deliveryAddress,
    required String paymentMethod,
    String? notes,
  }) async {
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      // Prepare order items data
      final List<Map<String, dynamic>> itemsData = items.map((item) => {
        'product_id': item.product.id,
        'quantity': item.quantity,
        'price': item.product.price,
      }).toList();
      
      // Calculate total amount
      final double totalAmount = items.fold(
        0,
        (total, item) => total + (item.product.price * item.quantity),
      );
      
      // Prepare order data
      final Map<String, dynamic> orderData = {
        'farm_id': farmId,
        'items': itemsData,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'delivery_address': deliveryAddress.toJson(),
        'notes': notes,
      };
      
      _logger.debug('Creating order with data: ${jsonEncode(orderData)}');
      
      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/orders'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(orderData),
      );
      
      _logger.debug('Create order response status: ${response.statusCode}');
      return ApiUtils.handleResponse(response, (json) => Order.fromJson(json));
    });
  }
  
  // Update order status (for farmers to process orders)
  Future<Order> updateOrderStatus({
    required String orderId,
    required String status,
    String? notes,
  }) async {
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final Map<String, dynamic> updateData = {
        'status': status,
        'notes': notes,
      };
      
      _logger.debug('Updating order $orderId status to: $status');
      
      final response = await http.patch(
        Uri.parse('${FreshConfig.apiUrl}/orders/$orderId/status'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );
      
      _logger.debug('Update order status response status: ${response.statusCode}');
      return ApiUtils.handleResponse(response, (json) => Order.fromJson(json));
    });
  }
  
  // Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      _logger.debug('Cancelling order: $orderId');
      
      final response = await http.delete(
        Uri.parse('${FreshConfig.apiUrl}/orders/$orderId'),
        headers: ApiUtils.createAuthHeaders(token),
      );
      
      _logger.debug('Cancel order response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          message: errorData['message'] ?? 'Failed to cancel order',
          type: ApiErrorType.badRequest,
          statusCode: response.statusCode,
          data: errorData,
        );
      }
    });
  }
  
  // Get orders for a specific farm (for farmers)
  Future<List<Order>> getFarmOrders(String farmId) async {
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/farms/$farmId/orders'),
        headers: ApiUtils.createAuthHeaders(token),
      );
      
      _logger.debug('Get farm orders response status: ${response.statusCode}');
      return ApiUtils.handleListResponse(response, (json) => Order.fromJson(json));
    });
  }
  
  // Get delivery assignments (for drivers)
  Future<List<Order>> getDeliveryAssignments() async {
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/driver/assignments'),
        headers: ApiUtils.createAuthHeaders(token),
      );
      
      _logger.debug('Get delivery assignments response status: ${response.statusCode}');
      return ApiUtils.handleListResponse(response, (json) => Order.fromJson(json));
    });
  }
  
  // Update delivery status (for drivers)
  Future<Order> updateDeliveryStatus({
    required String orderId,
    required String status,
    String? notes,
    DateTime? deliveryDate,
  }) async {
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final updateData = {
        'status': status,
        'notes': notes,
        'delivery_date': deliveryDate?.toIso8601String(),
      };
      
      _logger.debug('Updating delivery status for order $orderId to: $status');
      
      final response = await http.patch(
        Uri.parse('${FreshConfig.apiUrl}/driver/orders/$orderId/delivery-status'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );
      
      _logger.debug('Update delivery status response status: ${response.statusCode}');
      return ApiUtils.handleResponse(response, (json) => Order.fromJson(json));
    });
  }
}
