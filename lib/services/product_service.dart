import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../config.dart';
import 'auth_service.dart';

class ProductService extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all products
  Future<List<Product>> getAllProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use mock data in test mode
      if (FreshConfig.testingMode) {
        await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
        final mockProducts = _getMockProducts();
        _products.clear();
        _products.addAll(mockProducts);
        _isLoading = false;
        notifyListeners();
        return mockProducts;
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/products'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> productData = json.decode(response.body);
        _products.clear();
        
        for (var product in productData) {
          _products.add(Product.fromJson(product));
        }
        
        _isLoading = false;
        notifyListeners();
        return _products;
      } else {
        _error = 'Failed to load products: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      // Fallback to mock data in case of error and testing mode is enabled
      if (FreshConfig.testingMode) {
        final mockProducts = _getMockProducts();
        _products.clear();
        _products.addAll(mockProducts);
        _isLoading = false;
        notifyListeners();
        return mockProducts;
      }
      
      _error = 'Error fetching products: $e';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get featured products
  Future<List<Product>> getFeaturedProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use mock data in test mode
      if (FreshConfig.testingMode) {
        await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
        final mockProducts = _getMockProducts().take(4).toList(); // Take first 4 products as featured
        _isLoading = false;
        notifyListeners();
        return mockProducts;
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/products/featured'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> productData = json.decode(response.body);
        final List<Product> featuredProducts = [];
        
        for (var product in productData) {
          featuredProducts.add(Product.fromJson(product));
        }
        
        _isLoading = false;
        notifyListeners();
        return featuredProducts;
      } else if (response.statusCode == 404) {
        // If the featured endpoint is not available, fall back to all products
        return getAllProducts();
      } else {
        _error = 'Failed to load featured products: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching featured products: $e');
      // Fallback to mock data in case of error and testing mode is enabled
      if (FreshConfig.testingMode) {
        final mockProducts = _getMockProducts().take(4).toList(); // Take first 4 products as featured
        _isLoading = false;
        notifyListeners();
        return mockProducts;
      }
      
      _error = 'Error fetching featured products: $e';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get products by farm ID
  Future<List<Product>> getProductsByFarmId(String farmId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use mock data in test mode
      if (FreshConfig.testingMode) {
        await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
        final mockProducts = _getMockProducts().where((p) => p.farmId == farmId).toList();
        _isLoading = false;
        notifyListeners();
        return mockProducts.isEmpty ? _getMockProducts().take(3).toList() : mockProducts;
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/farms/$farmId/products'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> productData = json.decode(response.body);
        final List<Product> farmProducts = [];
        
        for (var product in productData) {
          farmProducts.add(Product.fromJson(product));
        }
        
        _isLoading = false;
        notifyListeners();
        return farmProducts;
      } else {
        _error = 'Failed to load farm products: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching farm products: $e');
      // Fallback to mock data in case of error and testing mode is enabled
      if (FreshConfig.testingMode) {
        final mockProducts = _getMockProducts().where((p) => p.farmId == farmId).toList();
        _isLoading = false;
        notifyListeners();
        return mockProducts.isEmpty ? _getMockProducts().take(3).toList() : mockProducts;
      }
      
      _error = 'Error fetching farm products: $e';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use mock data in test mode
      if (FreshConfig.testingMode) {
        await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
        final mockProduct = _getMockProducts().firstWhere(
          (product) => product.id == id,
          orElse: () => _getMockProducts().first,
        );
        _isLoading = false;
        notifyListeners();
        return mockProduct;
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/products/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final productData = json.decode(response.body);
        final product = Product.fromJson(productData);
        
        _isLoading = false;
        notifyListeners();
        return product;
      } else {
        _error = 'Failed to load product details: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching product details: $e');
      // Fallback to mock data in case of error and testing mode is enabled
      if (FreshConfig.testingMode) {
        final mockProduct = _getMockProducts().firstWhere(
          (product) => product.id == id,
          orElse: () => _getMockProducts().first,
        );
        _isLoading = false;
        notifyListeners();
        return mockProduct;
      }
      
      _error = 'Error fetching product details: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Helper method to get mock products for testing
  List<Product> _getMockProducts() {
    return [
      Product(
        id: '1',
        name: 'Organic Heirloom Tomatoes',
        description: 'Juicy, flavorful heirloom tomatoes grown without synthetic pesticides or fertilizers.',
        price: 4.99,
        unit: 'lb',
        category: 'Vegetables',
        farmId: '1',
        farmName: 'Green Valley Organics',
        isOrganic: true,
        inStock: true,
        quantity: 25,
        availableFrom: DateTime.now(),
        availableTo: DateTime.now().add(const Duration(days: 14)),
        imageUrl: 'https://images.unsplash.com/photo-1582284540020-8acbe03f4924?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=735&q=80',
      ),
      Product(
        id: '2',
        name: 'Fresh Strawberries',
        description: 'Sweet, juicy strawberries picked at peak ripeness.',
        price: 5.99,
        unit: 'pint',
        category: 'Fruits',
        farmId: '1',
        farmName: 'Green Valley Organics',
        isOrganic: true,
        inStock: true,
        quantity: 15,
        availableFrom: DateTime.now(),
        availableTo: DateTime.now().add(const Duration(days: 7)),
        imageUrl: 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
      ),
      Product(
        id: '3',
        name: 'Free Range Eggs',
        description: 'Farm-fresh eggs from free-range chickens raised without antibiotics.',
        price: 6.99,
        unit: 'dozen',
        category: 'Dairy & Eggs',
        farmId: '2',
        farmName: 'Happy Hen Farms',
        isOrganic: true,
        inStock: true,
        quantity: 30,
        availableFrom: DateTime.now(),
        availableTo: DateTime.now().add(const Duration(days: 14)),
        imageUrl: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
      ),
      Product(
        id: '4',
        name: 'Fresh-caught Salmon',
        description: 'Wild-caught Pacific salmon, sustainably harvested.',
        price: 19.99,
        unit: 'lb',
        category: 'Seafood',
        farmId: '3',
        farmName: 'Coastal Harvest',
        isOrganic: false,
        inStock: true,
        quantity: 8,
        availableFrom: DateTime.now(),
        availableTo: DateTime.now().add(const Duration(days: 3)),
        imageUrl: 'https://images.unsplash.com/photo-1574781330855-d0db8cc6a79c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
      ),
      Product(
        id: '5',
        name: 'Artisanal Cheese Sampler',
        description: 'Selection of handcrafted artisanal cheeses from grass-fed cows.',
        price: 24.99,
        unit: 'package',
        category: 'Dairy & Eggs',
        farmId: '4',
        farmName: 'Heritage Dairy',
        isOrganic: true,
        inStock: true,
        quantity: 10,
        availableFrom: DateTime.now(),
        availableTo: DateTime.now().add(const Duration(days: 14)),
        imageUrl: 'https://images.unsplash.com/photo-1452195100486-9cc805987862?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1469&q=80',
      ),
      Product(
        id: '6',
        name: 'Honeycrisp Apples',
        description: 'Crisp, sweet-tart apples perfect for snacking or baking.',
        price: 3.99,
        unit: 'lb',
        category: 'Fruits',
        farmId: '5',
        farmName: 'Sunrise Orchards',
        isOrganic: true,
        inStock: true,
        quantity: 40,
        availableFrom: DateTime.now(),
        availableTo: DateTime.now().add(const Duration(days: 21)),
        imageUrl: 'https://images.unsplash.com/photo-1503327431567-3ab5e6e79140?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1096&q=80',
      ),
      Product(
        id: '7',
        name: 'Grass-fed Ground Beef',
        description: 'Premium grass-fed beef, no hormones or antibiotics.',
        price: 8.99,
        unit: 'lb',
        category: 'Meat',
        farmId: '1',
        farmName: 'Green Valley Organics',
        isOrganic: true,
        inStock: true,
        quantity: 15,
        availableFrom: DateTime.now(),
        availableTo: DateTime.now().add(const Duration(days: 5)),
        imageUrl: 'https://images.unsplash.com/photo-1602470521006-6ba3f89aefc3?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
      ),
      Product(
        id: '8',
        name: 'Fresh Oysters',
        description: 'Fresh Pacific oysters, harvested daily.',
        price: 16.99,
        unit: 'dozen',
        category: 'Seafood',
        farmId: '3',
        farmName: 'Coastal Harvest',
        isOrganic: false,
        inStock: true,
        quantity: 10,
        availableFrom: DateTime.now(),
        availableTo: DateTime.now().add(const Duration(days: 2)),
        imageUrl: 'https://images.unsplash.com/photo-1604847399396-cf235af1d21c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=687&q=80',
      ),
    ];
  }
}
