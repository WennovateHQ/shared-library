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

class OrderService {
  // Singleton pattern
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  // Sample mock data for test mode
  final List<Order> _mockOrders = [];
  
  // Initialize mock data
  Future<void> _initializeMockData() async {
    if (_mockOrders.isNotEmpty) return;
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString('user_id') ?? 'test_user';
    
    // Create some mock orders
    _mockOrders.addAll([
      Order(
        id: 'order_001',
        userId: userId,
        farmId: 'farm_101',
        farmName: 'Green Valley Organic Farm',
        items: [
          CartItem(
            product: Product(
              id: 'prod_001',
              name: 'Organic Apples',
              description: 'Fresh organic apples from local farms',
              price: 4.99,
              unit: 'lb',
              farmId: 'farm_101',
              imageUrls: ['assets/images/products/apples.jpg'],
              categories: ['fruits', 'organic'],
              availability: true,
              rating: 4.8,
              reviewCount: 25,
            ),
            quantity: 2,
          ),
          CartItem(
            product: Product(
              id: 'prod_002',
              name: 'Fresh Lettuce',
              description: 'Crisp lettuce grown with sustainable practices',
              price: 2.99,
              unit: 'head',
              farmId: 'farm_101',
              imageUrls: ['assets/images/products/lettuce.jpg'],
              categories: ['vegetables', 'organic'],
              availability: true,
              rating: 4.5,
              reviewCount: 18,
            ),
            quantity: 1,
          ),
        ],
        status: 'delivered',
        totalAmount: 12.97,
        paymentMethod: 'Credit Card',
        deliveryAddress: Address(
          street: '123 Main St',
          city: 'Farmville',
          state: 'CA',
          postalCode: '94123',
          country: 'USA',
        ),
        orderDate: DateTime.now().subtract(const Duration(days: 7)),
        deliveryDate: DateTime.now().subtract(const Duration(days: 5)),
        notes: 'Please leave at the front door',
      ),
      Order(
        id: 'order_002',
        userId: userId,
        farmId: 'farm_102',
        farmName: 'Sunshine Dairy Farm',
        items: [
          CartItem(
            product: Product(
              id: 'prod_003',
              name: 'Organic Milk',
              description: 'Fresh organic milk from pasture-raised cows',
              price: 5.99,
              unit: 'gallon',
              farmId: 'farm_102',
              imageUrls: ['assets/images/products/milk.jpg'],
              categories: ['dairy', 'organic'],
              availability: true,
              rating: 4.9,
              reviewCount: 32,
            ),
            quantity: 2,
          ),
          CartItem(
            product: Product(
              id: 'prod_004',
              name: 'Farm Fresh Eggs',
              description: 'Free-range eggs from happy chickens',
              price: 4.50,
              unit: 'dozen',
              farmId: 'farm_102',
              imageUrls: ['assets/images/products/eggs.jpg'],
              categories: ['dairy', 'organic'],
              availability: true,
              rating: 4.7,
              reviewCount: 28,
            ),
            quantity: 1,
          ),
        ],
        status: 'processing',
        totalAmount: 16.48,
        paymentMethod: 'PayPal',
        deliveryAddress: Address(
          street: '123 Main St',
          city: 'Farmville',
          state: 'CA',
          postalCode: '94123',
          country: 'USA',
        ),
        orderDate: DateTime.now().subtract(const Duration(hours: 5)),
        deliveryDate: DateTime.now().add(const Duration(days: 1)),
      ),
      Order(
        id: 'order_003',
        userId: userId,
        farmId: 'farm_103',
        farmName: 'Harvest Moon Vegetables',
        items: [
          CartItem(
            product: Product(
              id: 'prod_005',
              name: 'Mixed Vegetable Box',
              description: 'A selection of seasonal vegetables',
              price: 25.99,
              unit: 'box',
              farmId: 'farm_103',
              imageUrls: ['assets/images/products/vegbox.jpg'],
              categories: ['vegetables', 'organic', 'box'],
              availability: true,
              rating: 4.6,
              reviewCount: 42,
            ),
            quantity: 1,
          ),
        ],
        status: 'accepted',
        totalAmount: 25.99,
        paymentMethod: 'Credit Card',
        deliveryAddress: Address(
          street: '123 Main St',
          city: 'Farmville',
          state: 'CA',
          postalCode: '94123',
          country: 'USA',
        ),
        orderDate: DateTime.now().subtract(const Duration(hours: 2)),
        deliveryDate: DateTime.now().add(const Duration(days: 2)),
      ),
    ]);
  }

  // Get all orders for a user
  Future<List<Order>> getUserOrders() async {
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      return _mockOrders;
    }
    
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/orders'),
        headers: ApiUtils.createAuthHeaders(token),
      );
      
      return ApiUtils.handleListResponse(response, (json) => Order.fromJson(json));
    });
  }
  
  // Get a specific order by ID
  Future<Order> getOrderById(String orderId) async {
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      
      final order = _mockOrders.firstWhere(
        (order) => order.id == orderId,
        orElse: () => throw Exception('Order not found'),
      );
      
      return order;
    }
    
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/orders/$orderId'),
        headers: ApiUtils.createAuthHeaders(token),
      );
      
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
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      
      // Get current user
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'test_user';
      
      // Find farm name based on farm ID
      String farmName = 'Unknown Farm';
      if (farmId == 'farm_101') {
        farmName = 'Green Valley Organic Farm';
      } else if (farmId == 'farm_102') {
        farmName = 'Sunshine Dairy Farm';
      } else if (farmId == 'farm_103') {
        farmName = 'Harvest Moon Vegetables';
      }
      
      // Calculate total amount
      double total = 0;
      for (var item in items) {
        total += item.product.price * item.quantity;
      }
      
      // Create new order
      final newOrder = Order(
        id: 'order_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        farmId: farmId,
        farmName: farmName,
        items: items,
        status: 'pending',
        totalAmount: double.parse(total.toStringAsFixed(2)), // Round to 2 decimal places
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
        orderDate: DateTime.now(),
        deliveryDate: DateTime.now().add(const Duration(days: 2)), // Default to 2 days delivery
        notes: notes,
      );
      
      // Add to mock data
      _mockOrders.add(newOrder);
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      return newOrder;
    }
    
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      // Prepare the order data
      final orderData = {
        'farm_id': farmId,
        'items': items.map((item) => {
          'product_id': item.product.id,
          'quantity': item.quantity,
        }).toList(),
        'delivery_address': deliveryAddress.toJson(),
        'payment_method': paymentMethod,
        'notes': notes,
      };
      
      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/orders'),
        headers: ApiUtils.createAuthHeaders(token),
        body: json.encode(orderData),
      );
      
      return ApiUtils.handleResponse(response, (json) => Order.fromJson(json));
    });
  }
  
  // Update order status (primarily for farmer and driver)
  Future<Order> updateOrderStatus({
    required String orderId,
    required String status,
    String? notes,
  }) async {
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      
      // Find the order
      final orderIndex = _mockOrders.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) {
        throw Exception('Order not found');
      }
      
      // Update the order status
      final updatedOrder = Order(
        id: _mockOrders[orderIndex].id,
        userId: _mockOrders[orderIndex].userId,
        farmId: _mockOrders[orderIndex].farmId,
        farmName: _mockOrders[orderIndex].farmName,
        items: _mockOrders[orderIndex].items,
        status: status,
        totalAmount: _mockOrders[orderIndex].totalAmount,
        paymentMethod: _mockOrders[orderIndex].paymentMethod,
        deliveryAddress: _mockOrders[orderIndex].deliveryAddress,
        orderDate: _mockOrders[orderIndex].orderDate,
        deliveryDate: _mockOrders[orderIndex].deliveryDate,
        notes: notes ?? _mockOrders[orderIndex].notes,
      );
      
      _mockOrders[orderIndex] = updatedOrder;
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      return updatedOrder;
    }
    
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final updateData = {
        'status': status,
        'notes': notes,
      };
      
      final response = await http.patch(
        Uri.parse('${FreshConfig.apiUrl}/orders/$orderId/status'),
        headers: ApiUtils.createAuthHeaders(token),
        body: json.encode(updateData),
      );
      
      return ApiUtils.handleResponse(response, (json) => Order.fromJson(json));
    });
  }
  
  // Cancel an order (for consumers)
  Future<bool> cancelOrder(String orderId) async {
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      
      // Find the order
      final orderIndex = _mockOrders.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) {
        throw Exception('Order not found');
      }
      
      // Check if the order can be canceled (only pending or accepted status)
      if (!['pending', 'accepted'].contains(_mockOrders[orderIndex].status)) {
        throw Exception('Order cannot be canceled at this stage');
      }
      
      // Update status to cancelled
      _mockOrders[orderIndex] = Order(
        id: _mockOrders[orderIndex].id,
        userId: _mockOrders[orderIndex].userId,
        farmId: _mockOrders[orderIndex].farmId,
        farmName: _mockOrders[orderIndex].farmName,
        items: _mockOrders[orderIndex].items,
        status: 'cancelled',
        totalAmount: _mockOrders[orderIndex].totalAmount,
        paymentMethod: _mockOrders[orderIndex].paymentMethod,
        deliveryAddress: _mockOrders[orderIndex].deliveryAddress,
        orderDate: _mockOrders[orderIndex].orderDate,
        deliveryDate: _mockOrders[orderIndex].deliveryDate,
        notes: _mockOrders[orderIndex].notes,
      );
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      return true;
    }
    
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/orders/$orderId/cancel'),
        headers: ApiUtils.createAuthHeaders(token),
      );
      
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
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      
      // Filter orders for this farm
      return _mockOrders.where((order) => order.farmId == farmId).toList();
    }
    
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/farms/$farmId/orders'),
        headers: ApiUtils.createAuthHeaders(token),
      );
      
      return ApiUtils.handleListResponse(response, (json) => Order.fromJson(json));
    });
  }
  
  // Get delivery assignments (for drivers)
  Future<List<Order>> getDeliveryAssignments() async {
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      
      // Filter orders that are ready for delivery or in transit
      return _mockOrders
          .where((order) => ['ready', 'in_transit'].contains(order.status))
          .toList();
    }
    
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/driver/assignments'),
        headers: ApiUtils.createAuthHeaders(token),
      );
      
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
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      
      // Find the order
      final orderIndex = _mockOrders.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) {
        throw Exception('Order not found');
      }
      
      // Update the order status
      final updatedOrder = Order(
        id: _mockOrders[orderIndex].id,
        userId: _mockOrders[orderIndex].userId,
        farmId: _mockOrders[orderIndex].farmId,
        farmName: _mockOrders[orderIndex].farmName,
        items: _mockOrders[orderIndex].items,
        status: status,
        totalAmount: _mockOrders[orderIndex].totalAmount,
        paymentMethod: _mockOrders[orderIndex].paymentMethod,
        deliveryAddress: _mockOrders[orderIndex].deliveryAddress,
        orderDate: _mockOrders[orderIndex].orderDate,
        deliveryDate: deliveryDate ?? _mockOrders[orderIndex].deliveryDate,
        notes: notes ?? _mockOrders[orderIndex].notes,
      );
      
      _mockOrders[orderIndex] = updatedOrder;
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      return updatedOrder;
    }
    
    return ApiUtils.withConnectionHandling(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final updateData = {
        'status': status,
        'notes': notes,
        'delivery_date': deliveryDate?.toIso8601String(),
      };
      
      final response = await http.patch(
        Uri.parse('${FreshConfig.apiUrl}/driver/orders/$orderId/delivery-status'),
        headers: ApiUtils.createAuthHeaders(token),
        body: json.encode(updateData),
      );
      
      return ApiUtils.handleResponse(response, (json) => Order.fromJson(json));
    });
  }
}
