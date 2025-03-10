import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/farm.dart';
import '../models/forum_post.dart';
import '../models/product.dart';
import 'auth_service.dart';
import '../utils/logging_service.dart';
import 'package:shared/config/api_config.dart';

// API Response class
class ApiResponse {
  final int statusCode;
  final dynamic data;
  final String? errorMessage;
  
  ApiResponse({
    required this.statusCode,
    required this.data,
    this.errorMessage,
  });
  
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

// Pagination result class
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });
}

class ApiService {
  static String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();
  final LoggingService _logger = LoggingService('ApiService');
  final Duration _timeout = const Duration(seconds: 30);

  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = await _authService.getAuthHeaders();
    return headers;
  }
  
  // Authentication
  Future<Map<String, dynamic>> login(String email, String password, {String userType = 'consumer'}) async {
    // For testing purposes, we're simulating a successful login
    // In a real app, you would make an API call to the backend
    await Future.delayed(const Duration(seconds: 2)); // Simulate network request
    
    return {
      'token': 'sample_auth_token_${DateTime.now().millisecondsSinceEpoch}',
      'userType': userType,
      'userId': 'user_${userType}_123',
      'email': email,
    };
  }
  
  Future<bool> logout() async {
    // For testing purposes, we're simulating a successful logout
    await Future.delayed(const Duration(seconds: 1)); // Simulate network request
    return true;
  }

  // Enhanced API request methods with better error handling
  Future<ApiResponse> get(String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    bool authenticated = false,
  }) async {
    try {
      // Add query parameters if provided
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) => 
          MapEntry(key, value?.toString() ?? '')));
      }
      
      // Get headers
      Map<String, String> requestHeaders = headers ?? {};
      if (authenticated) {
        final authHeaders = await _getAuthHeaders();
        requestHeaders.addAll(authHeaders);
      }
      
      _logger.debug('GET request to $uri');
      
      // Make the request with timeout
      final response = await http.get(uri, headers: requestHeaders)
          .timeout(_timeout);
      
      // Process response
      return _processResponse(response);
    } catch (e, stackTrace) {
      _logger.error('GET request failed: $e', error: e, stackTrace: stackTrace);
      return ApiResponse(
        statusCode: 500,
        data: null,
        errorMessage: 'Request failed: ${e.toString()}',
      );
    }
  }
  
  Future<ApiResponse> post(String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic body,
    bool authenticated = false,
    String contentType = 'application/json',
  }) async {
    try {
      // Add query parameters if provided
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) => 
          MapEntry(key, value?.toString() ?? '')));
      }
      
      // Get headers
      Map<String, String> requestHeaders = headers ?? {};
      if (authenticated) {
        final authHeaders = await _getAuthHeaders();
        requestHeaders.addAll(authHeaders);
      }
      
      // Add content type
      requestHeaders['Content-Type'] = contentType;
      
      // Prepare body
      Object? encodedBody;
      if (body != null) {
        if (contentType == 'application/json') {
          encodedBody = jsonEncode(body);
        } else {
          encodedBody = body.toString();
        }
      }
      
      _logger.debug('POST request to $uri');
      
      // Make the request with timeout
      final response = await http.post(
        uri, 
        headers: requestHeaders,
        body: encodedBody,
      ).timeout(_timeout);
      
      // Process response
      return _processResponse(response);
    } catch (e, stackTrace) {
      _logger.error('POST request failed: $e', error: e, stackTrace: stackTrace);
      return ApiResponse(
        statusCode: 500,
        data: null,
        errorMessage: 'Request failed: ${e.toString()}',
      );
    }
  }
  
  Future<ApiResponse> put(String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic body,
    bool authenticated = false,
  }) async {
    try {
      // Add query parameters if provided
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) => 
          MapEntry(key, value?.toString() ?? '')));
      }
      
      // Get headers
      Map<String, String> requestHeaders = headers ?? {};
      if (authenticated) {
        final authHeaders = await _getAuthHeaders();
        requestHeaders.addAll(authHeaders);
      }
      
      // Add content type
      requestHeaders['Content-Type'] = 'application/json';
      
      _logger.debug('PUT request to $uri');
      
      // Make the request with timeout
      final response = await http.put(
        uri, 
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      
      // Process response
      return _processResponse(response);
    } catch (e, stackTrace) {
      _logger.error('PUT request failed: $e', error: e, stackTrace: stackTrace);
      return ApiResponse(
        statusCode: 500,
        data: null,
        errorMessage: 'Request failed: ${e.toString()}',
      );
    }
  }
  
  Future<ApiResponse> delete(String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    bool authenticated = false,
  }) async {
    try {
      // Add query parameters if provided
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) => 
          MapEntry(key, value?.toString() ?? '')));
      }
      
      // Get headers
      Map<String, String> requestHeaders = headers ?? {};
      if (authenticated) {
        final authHeaders = await _getAuthHeaders();
        requestHeaders.addAll(authHeaders);
      }
      
      _logger.debug('DELETE request to $uri');
      
      // Make the request with timeout
      final response = await http.delete(
        uri, 
        headers: requestHeaders,
      ).timeout(_timeout);
      
      // Process response
      return _processResponse(response);
    } catch (e, stackTrace) {
      _logger.error('DELETE request failed: $e', error: e, stackTrace: stackTrace);
      return ApiResponse(
        statusCode: 500,
        data: null,
        errorMessage: 'Request failed: ${e.toString()}',
      );
    }
  }
  
  // Process HTTP response and handle errors
  ApiResponse _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic data;
    String? errorMessage;
    
    try {
      // Try to parse response body
      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body);
      }
    } catch (e) {
      _logger.warn('Failed to parse response body: ${response.body}');
      // If JSON parsing fails, use raw body
      data = response.body;
    }
    
    // Check for error responses
    if (statusCode < 200 || statusCode >= 300) {
      // Extract error message
      if (data != null && data is Map && data.containsKey('message')) {
        errorMessage = data['message'];
      } else if (data != null && data is Map && data.containsKey('error')) {
        errorMessage = data['error'];
      } else {
        errorMessage = 'Request failed with status: $statusCode';
      }
      
      _logger.warn('HTTP Error $statusCode: $errorMessage');
    }
    
    return ApiResponse(
      statusCode: statusCode,
      data: data,
      errorMessage: errorMessage,
    );
  }

  // Products CRUD operations
  Future<Map<String, dynamic>> postResource(String endpoint, Map<String, dynamic> data) async {
    final response = await post(
      '$baseUrl$endpoint', 
      body: data,
      authenticated: true,
    );
    
    if (response.isSuccess) {
      return response.data;
    } else {
      throw Exception('Failed to create resource at $endpoint: ${response.errorMessage}');
    }
  }

  Future<Map<String, dynamic>> putResource(String endpoint, Map<String, dynamic> data) async {
    final response = await put(
      '$baseUrl$endpoint', 
      body: data,
      authenticated: true,
    );
    
    if (response.isSuccess) {
      return response.data;
    } else {
      throw Exception('Failed to update resource at $endpoint: ${response.errorMessage}');
    }
  }

  Future<void> deleteResource(String endpoint) async {
    final response = await delete(
      '$baseUrl$endpoint', 
      authenticated: true,
    );
    
    if (!response.isSuccess) {
      throw Exception('Failed to delete resource at $endpoint: ${response.errorMessage}');
    }
  }

  // Fetch farms with authentication, pagination, and filtering
  Future<PaginatedResult<Farm>> getFarms({
    int page = 1,
    int limit = 10,
    String? search,
    String? zipCode,
    String? status,
    bool? verified,
  }) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (zipCode != null && zipCode.isNotEmpty) {
        queryParams['zipCode'] = zipCode;
      }
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      
      if (verified != null) {
        queryParams['verified'] = verified.toString();
      }
      
      // Make the API request
      final response = await get(
        '${baseUrl}${ApiConfig.farmsEndpoint}',
        queryParams: queryParams,
        authenticated: true,
      );
      
      if (response.isSuccess) {
        final data = response.data;
        final List<Farm> farms = [];
        
        // Process farms data based on our backend response format
        if (data['farms'] != null) {
          for (final farmData in data['farms']) {
            farms.add(Farm.fromJson(farmData));
          }
        }
        
        return PaginatedResult<Farm>(
          items: farms,
          totalCount: data['totalFarms'] ?? 0,
          page: data['page'] ?? page,
          pageSize: data['limit'] ?? limit,
          hasMore: farms.length < (data['totalFarms'] ?? 0),
        );
      } else {
        throw Exception('Failed to fetch farms: ${response.errorMessage}');
      }
    } catch (e) {
      _logger.error('Error fetching farms: $e');
      
      if (ApiConfig.isDevelopment) {
        // In development, provide mock farms for testing
        return _getMockFarms(page, limit);
      }
      
      rethrow;
    }
  }
  
  // Fetch products with authentication, pagination, and filtering
  Future<PaginatedResult<Product>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? farmId,
    String? sortBy,
    bool? organic,
  }) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      
      if (farmId != null && farmId.isNotEmpty) {
        queryParams['farmId'] = farmId;
      }
      
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }
      
      if (organic != null) {
        queryParams['organic'] = organic.toString();
      }
      
      // Make the API request
      final response = await get(
        '${baseUrl}${ApiConfig.productsEndpoint}',
        queryParams: queryParams,
        authenticated: true,
      );
      
      if (response.isSuccess) {
        final data = response.data;
        final List<Product> products = [];
        
        // Process products data based on our backend response format
        if (data['products'] != null) {
          for (final productData in data['products']) {
            products.add(Product.fromJson(productData));
          }
        }
        
        return PaginatedResult<Product>(
          items: products,
          totalCount: data['totalCount'] ?? 0,
          page: data['currentPage'] ?? page,
          pageSize: limit,
          hasMore: data['currentPage'] < (data['totalPages'] ?? 1),
        );
      } else {
        throw Exception('Failed to fetch products: ${response.errorMessage}');
      }
    } catch (e) {
      _logger.error('Error fetching products: $e');
      
      if (ApiConfig.isDevelopment) {
        // In development, provide mock products for testing
        return _getMockProducts(page, limit);
      }
      
      rethrow;
    }
  }
  
  // Mock farm data for development and testing
  PaginatedResult<Farm> _getMockFarms(int page, int limit) {
    final mockFarms = List.generate(20, (index) => Farm.fromJson({
      'id': 'farm_${index + 1}',
      'name': 'Farm ${index + 1}',
      'description': 'This is a mock farm for testing',
      'address': '${100 + index} Farm Lane',
      'city': 'Farmville',
      'state': 'CA',
      'zipCode': '90210',
      'phone': '555-123-${1000 + index}',
      'email': 'farm${index + 1}@example.com',
      'imageUrl': 'https://picsum.photos/id/${200 + index}/300/200',
      'verified': index % 3 == 0,
      'rating': (3 + (index % 3)) / 1.0,
      'productsCount': 5 + (index % 10),
      'createdAt': DateTime.now().subtract(Duration(days: index * 7)).toIso8601String(),
    }));
    
    final startIdx = (page - 1) * limit;
    final endIdx = startIdx + limit < mockFarms.length ? startIdx + limit : mockFarms.length;
    
    return PaginatedResult<Farm>(
      items: startIdx < mockFarms.length ? mockFarms.sublist(startIdx, endIdx) : [],
      totalCount: mockFarms.length,
      page: page,
      pageSize: limit,
      hasMore: endIdx < mockFarms.length,
    );
  }
  
  // Mock product data for development and testing
  PaginatedResult<Product> _getMockProducts(int page, int limit) {
    final categories = ['Vegetables', 'Fruits', 'Dairy', 'Meat', 'Herbs'];
    final mockProducts = List.generate(50, (index) => Product.fromJson({
      'id': 'product_${index + 1}',
      'name': 'Product ${index + 1}',
      'description': 'This is a mock product for testing',
      'category': categories[index % categories.length],
      'price': 3.99 + (index % 10),
      'unit': index % 2 == 0 ? 'lb' : 'each',
      'imageUrl': 'https://picsum.photos/id/${100 + index}/300/200',
      'farmId': 'farm_${1 + (index % 10)}',
      'farmName': 'Farm ${1 + (index % 10)}',
      'organic': index % 3 == 0,
      'inStock': index % 5 != 0,
      'quantity': 10 + (index % 20),
      'createdAt': DateTime.now().subtract(Duration(days: index * 3)).toIso8601String(),
    }));
    
    final startIdx = (page - 1) * limit;
    final endIdx = startIdx + limit < mockProducts.length ? startIdx + limit : mockProducts.length;
    
    return PaginatedResult<Product>(
      items: startIdx < mockProducts.length ? mockProducts.sublist(startIdx, endIdx) : [],
      totalCount: mockProducts.length,
      page: page,
      pageSize: limit,
      hasMore: endIdx < mockProducts.length,
    );
  }

  // Products
  Future<List<Product>> getAllProducts() async {
    final result = await getProducts(limit: 100);
    return result.items;
  }

  // Get a single product by ID
  Future<Product> getProductById(String id) async {
    try {
      final response = await get(
        '${baseUrl}${ApiConfig.productsEndpoint}/$id',
        authenticated: true,
      );
      
      if (response.isSuccess) {
        return Product.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch product: ${response.errorMessage}');
      }
    } catch (e) {
      _logger.error('Error fetching product by id: $e');
      
      if (ApiConfig.isDevelopment) {
        // Return a mock product for testing
        return Product.fromJson({
          'id': id,
          'name': 'Mock Product',
          'description': 'This is a mock product for testing',
          'category': 'Vegetables',
          'price': 4.99,
          'unit': 'lb',
          'imageUrl': 'https://picsum.photos/id/292/300/200',
          'farmId': 'farm_1',
          'farmName': 'Test Farm',
          'organic': true,
          'inStock': true,
          'quantity': 15,
          'createdAt': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
        });
      }
      
      rethrow;
    }
  }

  // Farms
  Future<List<Farm>> getAllFarms() async {
    final result = await getFarms(limit: 100);
    return result.items;
  }

  // Get a single farm by ID
  Future<Farm> getFarmById(String id) async {
    try {
      final response = await get(
        '${baseUrl}${ApiConfig.farmsEndpoint}/$id',
        authenticated: true,
      );
      
      if (response.isSuccess) {
        return Farm.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch farm: ${response.errorMessage}');
      }
    } catch (e) {
      _logger.error('Error fetching farm by id: $e');
      
      if (ApiConfig.isDevelopment) {
        // Return a mock farm for testing
        return Farm.fromJson({
          'id': id,
          'name': 'Mock Farm',
          'description': 'This is a mock farm for testing',
          'address': '123 Test Lane',
          'city': 'Farmville',
          'state': 'CA',
          'zipCode': '90210',
          'phone': '555-123-4567',
          'email': 'farm@example.com',
          'imageUrl': 'https://picsum.photos/id/235/300/200',
          'verified': true,
          'rating': 4.5,
          'productsCount': 12,
          'createdAt': DateTime.now().subtract(Duration(days: 20)).toIso8601String(),
        });
      }
      
      rethrow;
    }
  }

  // Forum posts with pagination
  Future<PaginatedResult<ForumPost>> getForumPosts({
    int page = 1,
    int pageSize = 10,
    String? searchQuery,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (searchQuery != null && searchQuery.isNotEmpty) 'query': searchQuery,
    };

    final response = await get(
      '$baseUrl/forum/posts', 
      queryParams: queryParams,
      authenticated: true,
    );
    
    if (response.isSuccess) {
      final jsonData = response.data;
      final items = (jsonData['items'] as List)
          .map((json) => ForumPost.fromJson(json))
          .toList();
      
      return PaginatedResult<ForumPost>(
        items: items,
        totalCount: jsonData['totalCount'],
        page: jsonData['page'],
        pageSize: jsonData['pageSize'],
        hasMore: jsonData['hasMore'],
      );
    } else {
      throw Exception('Failed to load forum posts: ${response.errorMessage}');
    }
  }

  Future<ForumPost> createForumPost(String content) async {
    final response = await post(
      '$baseUrl/forum/posts', 
      body: {'content': content},
      authenticated: true,
    );
    
    if (response.isSuccess) {
      return ForumPost.fromJson(response.data);
    } else {
      throw Exception('Failed to create forum post: ${response.errorMessage}');
    }
  }

  Future<void> likeForumPost(String postId) async {
    final response = await post(
      '$baseUrl/forum/posts/$postId/like', 
      authenticated: true,
    );
    
    if (!response.isSuccess) {
      throw Exception('Failed to like forum post: ${response.errorMessage}');
    }
  }

  Future<void> commentOnForumPost(String postId, String comment) async {
    final response = await post(
      '$baseUrl/forum/posts/$postId/comments', 
      body: {'content': comment},
      authenticated: true,
    );
    
    if (!response.isSuccess) {
      throw Exception('Failed to comment on forum post: ${response.errorMessage}');
    }
  }

  // Farms with pagination - Removed duplicate implementation

  Future<Farm> getFarmProfile(String farmId) async {
    final response = await get(
      '$baseUrl/farms/$farmId', 
      authenticated: true,
    );
    
    if (response.isSuccess) {
      return Farm.fromJson(response.data);
    } else {
      throw Exception('Failed to load farm profile: ${response.errorMessage}');
    }
  }

  Future<void> followFarm(String farmId) async {
    final response = await post(
      '$baseUrl/farms/$farmId/follow', 
      authenticated: true,
    );
    
    if (!response.isSuccess) {
      throw Exception('Failed to follow farm: ${response.errorMessage}');
    }
  }

  Future<void> unfollowFarm(String farmId) async {
    final response = await delete(
      '$baseUrl/farms/$farmId/follow', 
      authenticated: true,
    );
    
    if (!response.isSuccess) {
      throw Exception('Failed to unfollow farm: ${response.errorMessage}');
    }
  }
}
