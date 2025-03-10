import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared/models/product.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/config/api_config.dart';
import 'package:shared/utils/cache_manager.dart';
import '../config.dart';

class InventoryService {
  final String _baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();
  final CacheManager _cacheManager = CacheManager();
  
  // Get inventory
  Future<List<Product>> getInventory({bool forceRefresh = false}) async {
    const cacheKey = 'farmer_inventory';
    
    // Use mock data in test mode
    if (FreshConfig.testingMode) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      return _getMockInventory();
    }
    
    // Check if we have cached data and it's not a forced refresh
    if (!forceRefresh) {
      final cachedData = await _cacheManager.getList(cacheKey);
      if (cachedData != null) {
        return cachedData
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
    
    // No cache or forced refresh, fetch from API
    final token = await _authService.getAccessToken();
    
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.get(
      Uri.parse('$_baseUrl/inventory'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      
      // Parse the products
      final products = data
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
      
      // Cache the response (30 minutes)
      await _cacheManager.setList(
        cacheKey, 
        data, 
        expiration: const Duration(minutes: 30),
      );
      
      return products;
    } else if (FreshConfig.testingMode) {
      // Fallback to mock data in test mode if API fails
      debugPrint('API request failed, falling back to mock data');
      return _getMockInventory();
    } else {
      throw Exception('Failed to load inventory: ${response.statusCode}');
    }
  }
  
  // Update product stock
  Future<void> updateProductStock(String productId, int newStock) async {
    // In test mode, just delay and return
    if (FreshConfig.testingMode) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      debugPrint('Test mode: Product $productId stock updated to $newStock');
      return;
    }
    
    final token = await _authService.getAccessToken();
    
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.patch(
      Uri.parse('$_baseUrl/inventory/$productId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'stock': newStock,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update product stock: ${response.statusCode}');
    }
    
    // Update cache
    const cacheKey = 'farmer_inventory';
    final cachedData = await _cacheManager.getList(cacheKey);
    
    if (cachedData != null) {
      final updatedCache = cachedData.map((item) {
        final product = item as Map<String, dynamic>;
        if (product['id'] == productId) {
          product['stock'] = newStock;
        }
        return product;
      }).toList();
      
      await _cacheManager.setList(
        cacheKey, 
        updatedCache, 
        expiration: const Duration(minutes: 30),
      );
    }
  }
  
  // Create a new product
  Future<Product> createProduct(Product product) async {
    // In test mode, return a mock response
    if (FreshConfig.testingMode) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      
      // Create a copy of the product with a new ID to simulate server-generated ID
      final mockProduct = Product(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        name: product.name,
        description: product.description,
        price: product.price,
        unit: product.unit,
        category: product.category,
        farmId: product.farmId,
        farmName: product.farmName ?? 'Mock Farm',
        isOrganic: product.isOrganic,
        inStock: product.inStock,
        quantity: product.quantity,
        availableFrom: product.availableFrom,
        availableTo: product.availableTo,
        imageUrl: product.imageUrl,
      );
      
      debugPrint('Test mode: Created new product: ${mockProduct.name}');
      return mockProduct;
    }
    
    final token = await _authService.getAccessToken();
    
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.post(
      Uri.parse('$_baseUrl/inventory'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(product.toJson()),
    );
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final newProduct = Product.fromJson(data);
      
      // Update cache
      const cacheKey = 'farmer_inventory';
      final cachedData = await _cacheManager.getList(cacheKey);
      
      if (cachedData != null) {
        cachedData.add(data);
        await _cacheManager.setList(
          cacheKey, 
          cachedData, 
          expiration: const Duration(minutes: 30),
        );
      }
      
      return newProduct;
    } else {
      throw Exception('Failed to create product: ${response.statusCode}');
    }
  }
  
  // Update a product
  Future<Product> updateProduct(Product product) async {
    // In test mode, just delay and return the same product
    if (FreshConfig.testingMode) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      debugPrint('Test mode: Updated product: ${product.name}');
      return product;
    }
    
    final token = await _authService.getAccessToken();
    
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.put(
      Uri.parse('$_baseUrl/inventory/${product.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(product.toJson()),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final updatedProduct = Product.fromJson(data);
      
      // Update cache
      const cacheKey = 'farmer_inventory';
      final cachedData = await _cacheManager.getList(cacheKey);
      
      if (cachedData != null) {
        final updatedCache = cachedData.map((item) {
          final cachedProduct = item as Map<String, dynamic>;
          if (cachedProduct['id'] == product.id) {
            return data;
          }
          return cachedProduct;
        }).toList();
        
        await _cacheManager.setList(
          cacheKey, 
          updatedCache, 
          expiration: const Duration(minutes: 30),
        );
      }
      
      return updatedProduct;
    } else {
      throw Exception('Failed to update product: ${response.statusCode}');
    }
  }
  
  // Delete a product
  Future<void> deleteProduct(String productId) async {
    // In test mode, just delay and return
    if (FreshConfig.testingMode) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      debugPrint('Test mode: Deleted product: $productId');
      return;
    }
    
    final token = await _authService.getAccessToken();
    
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.delete(
      Uri.parse('$_baseUrl/inventory/$productId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.statusCode}');
    }
    
    // Update cache
    const cacheKey = 'farmer_inventory';
    final cachedData = await _cacheManager.getList(cacheKey);
    
    if (cachedData != null) {
      final updatedCache = cachedData.where((item) {
        final product = item as Map<String, dynamic>;
        return product['id'] != productId;
      }).toList();
      
      await _cacheManager.setList(
        cacheKey, 
        updatedCache, 
        expiration: const Duration(minutes: 30),
      );
    }
  }
  
  // Update product price
  Future<void> updateProductPrice(String productId, double newPrice) async {
    final token = await _authService.getAccessToken();
    
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    final response = await http.patch(
      Uri.parse('$_baseUrl/inventory/$productId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'price': newPrice,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update product price: ${response.statusCode}');
    }
    
    // Update cache
    const cacheKey = 'farmer_inventory';
    final cachedData = await _cacheManager.getList(cacheKey);
    
    if (cachedData != null) {
      final updatedCache = cachedData.map((item) {
        final product = item as Map<String, dynamic>;
        if (product['id'] == productId) {
          product['price'] = newPrice;
        }
        return product;
      }).toList();
      
      await _cacheManager.setList(
        cacheKey, 
        updatedCache, 
        expiration: const Duration(minutes: 30),
      );
    }
  }
  
  // Get inventory alerts (low stock and out of stock)
  Future<List<Product>> getInventoryAlerts() async {
    final products = await getInventory();
    
    return products.where((product) => 
        product.stock <= product.lowStockThreshold
    ).toList();
  }
  
  // Helper method to provide mock inventory data for testing
  List<Product> _getMockInventory() {
    return [
      Product(
        id: 'inv_1',
        name: 'Organic Kale',
        description: 'Fresh local organic kale, perfect for salads and smoothies.',
        price: 3.99,
        unit: 'bunch',
        category: 'Vegetables',
        farmId: 'farm_1',
        farmName: 'Green Valley Farm',
        isOrganic: true,
        inStock: true,
        quantity: 50,
        availableFrom: DateTime.now(),
        availableTo: DateTime.now().add(const Duration(days: 10)),
        imageUrl: 'https://images.unsplash.com/photo-1610348725531-843dff563e2c',
      ),
      Product(
        id: 'inv_2',
        name: 'Pasture-Raised Eggs',
        description: 'Eggs from free-roaming hens raised on organic feed.',
        price: 5.99,
        unit: 'dozen',
        category: 'Dairy & Eggs',
        farmId: 'farm_1',
        farmName: 'Green Valley Farm',
        isOrganic: true,
        inStock: true,
        quantity: 30,
        availableFrom: DateTime.now(),
        availableTo: DateTime.now().add(const Duration(days: 14)),
        imageUrl: 'https://images.unsplash.com/photo-1598965675045-45c5e72c7d05',
      ),
      Product(
        id: 'inv_3',
        name: 'Heirloom Tomatoes',
        description: 'Colorful mix of heirloom tomato varieties, grown sustainably.',
        price: 4.49,
        unit: 'lb',
        category: 'Vegetables',
        farmId: 'farm_1',
        farmName: 'Green Valley Farm',
        isOrganic: true,
        inStock: true,
        quantity: 40,
        availableFrom: DateTime.now(),
        availableTo: DateTime.now().add(const Duration(days: 7)),
        imageUrl: 'https://images.unsplash.com/photo-1582284637802-46ad6eda4771',
      ),
      Product(
        id: 'inv_4',
        name: 'Raw Honey',
        description: 'Unfiltered, pure honey from our local beehives.',
        price: 8.99,
        unit: 'jar',
        category: 'Pantry',
        farmId: 'farm_1',
        farmName: 'Green Valley Farm',
        isOrganic: true,
        inStock: true,
        quantity: 25,
        availableFrom: DateTime.now(),
        availableTo: DateTime.now().add(const Duration(days: 90)),
        imageUrl: 'https://images.unsplash.com/photo-1555211652-5c6222f971fe',
      ),
      Product(
        id: 'inv_5',
        name: 'Grass-Fed Ground Beef',
        description: 'Locally raised grass-fed beef, no hormones or antibiotics.',
        price: 7.99,
        unit: 'lb',
        category: 'Meat',
        farmId: 'farm_1',
        farmName: 'Green Valley Farm',
        isOrganic: true,
        inStock: true,
        quantity: 15,
        availableFrom: DateTime.now(),
        availableTo: DateTime.now().add(const Duration(days: 5)),
        imageUrl: 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f',
      ),
    ];
  }
}
