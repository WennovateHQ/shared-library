import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared/utils/logging_service.dart';
import '../models/product.dart';
import '../config.dart';
import 'auth_service.dart';

class ProductService extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final LoggingService _logger = LoggingService('ProductService');
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
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/products'),
        headers: headers,
      );

      _logger.debug('Get all products response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> productData = responseData['products'] ?? responseData['data'] ?? responseData;
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
      _logger.error('Error fetching products: $e');
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
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/products/featured'),
        headers: headers,
      );

      _logger.debug('Get featured products response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> productData = responseData['products'] ?? responseData['data'] ?? responseData;
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
      _logger.error('Error fetching featured products: $e');
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
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/products/farm/$farmId'),
        headers: headers,
      );

      _logger.debug('Get products by farm ID response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> productData = responseData['products'] ?? responseData['data'] ?? responseData;
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
      _logger.error('Error fetching farm products: $e');
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
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/products/$id'),
        headers: headers,
      );

      _logger.debug('Get product by ID response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, dynamic> productData = responseData['product'] ?? responseData;
        final product = Product.fromJson(productData);
        
        _isLoading = false;
        notifyListeners();
        return product;
      } else if (response.statusCode == 404) {
        _error = 'Product not found';
        _isLoading = false;
        notifyListeners();
        return null;
      } else {
        _error = 'Failed to load product: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _logger.error('Error fetching product: $e');
      _error = 'Error fetching product: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Create new product
  Future<Product?> createProduct(Map<String, dynamic> productData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/products'),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: json.encode(productData),
      );

      _logger.debug('Create product response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, dynamic> productResponseData = responseData['product'] ?? responseData;
        final product = Product.fromJson(productResponseData);
        
        _products.add(product);
        _isLoading = false;
        notifyListeners();
        return product;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['message'] ?? 'Failed to create product: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _logger.error('Error creating product: $e');
      _error = 'Error creating product: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update existing product
  Future<Product?> updateProduct(String id, Map<String, dynamic> productData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${FreshConfig.apiUrl}/products/$id'),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: json.encode(productData),
      );

      _logger.debug('Update product response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, dynamic> productResponseData = responseData['product'] ?? responseData;
        final product = Product.fromJson(productResponseData);
        
        // Update product in local list
        final index = _products.indexWhere((p) => p.id == id);
        if (index >= 0) {
          _products[index] = product;
        }
        
        _isLoading = false;
        notifyListeners();
        return product;
      } else if (response.statusCode == 404) {
        _error = 'Product not found';
        _isLoading = false;
        notifyListeners();
        return null;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['message'] ?? 'Failed to update product: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _logger.error('Error updating product: $e');
      _error = 'Error updating product: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${FreshConfig.apiUrl}/products/$id'),
        headers: headers,
      );

      _logger.debug('Delete product response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove product from local list
        final index = _products.indexWhere((p) => p.id == id);
        if (index >= 0) {
          _products.removeAt(index);
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 404) {
        _error = 'Product not found';
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['message'] ?? 'Failed to delete product: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _logger.error('Error deleting product: $e');
      _error = 'Error deleting product: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Upload product image
  Future<String?> uploadProductImage(List<int> imageBytes, String filename) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create multipart request
      final uri = Uri.parse('${FreshConfig.apiUrl}/upload/product-image');
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth headers
      final headers = await _authService.getAuthHeaders();
      request.headers.addAll(headers);
      
      // Add file
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
      );
      request.files.add(multipartFile);
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _logger.debug('Upload product image response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String imageUrl = responseData['imageUrl'] ?? responseData['url'] ?? responseData['path'];
        
        _isLoading = false;
        notifyListeners();
        return imageUrl;
      } else {
        final responseData = json.decode(response.body);
        _error = responseData['message'] ?? 'Failed to upload image: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _logger.error('Error uploading product image: $e');
      _error = 'Error uploading product image: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
