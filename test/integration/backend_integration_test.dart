import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shared/services/api_service.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/models/product.dart';
import 'package:shared/models/order.dart';
import 'package:shared/models/user.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Create a real API service that connects to the backend
  late ApiService apiService;
  late AuthService authService;
  
  // Test data
  const String testEmail = 'test@example.com';
  const String testPassword = 'Test123!';
  
  // Consumer test data
  final testProduct = {
    'id': 'prod_123',
    'name': 'Organic Apples',
    'price': 3.99,
    'farmId': 'farm_456',
    'category': 'Fruits',
    'inStock': true
  };
  
  // Farmer test data
  final testFarmProduct = {
    'id': 'prod_789',
    'name': 'Fresh Carrots',
    'price': 2.49,
    'description': 'Locally grown carrots',
    'quantity': 100,
    'unit': 'kg'
  };
  
  // Driver test data
  final testDelivery = {
    'id': 'del_123',
    'orderId': 'ord_456',
    'customerAddress': '123 Main St',
    'farmAddress': '456 Farm Rd',
    'status': 'pending'
  };

  setUp(() {
    // Initialize real services that connect to the backend
    apiService = ApiService();
    authService = AuthService();
  });

  group('Authentication Integration Tests', () {
    test('Login with valid credentials should return a token', () async {
      // Act
      final loginResult = await authService.login(testEmail, testPassword);
      
      // Assert
      expect(loginResult, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.userType, isNotNull);
    });
    
    test('Logout should clear auth token', () async {
      // Arrange
      await authService.login(testEmail, testPassword);
      expect(authService.isAuthenticated, isTrue);
      
      // Act
      await authService.logout();
      
      // Assert
      expect(authService.isAuthenticated, isFalse);
      expect(authService.token, isNull);
    });
    
    test('API calls should include auth token after login', () async {
      // Arrange
      await authService.login(testEmail, testPassword);
      
      // Act
      final headers = await authService.getAuthHeaders();
      
      // Assert
      expect(headers['Authorization'], contains('Bearer '));
    });
  });

  group('Consumer App API Integration Tests', () {
    test('Fetch products list should return valid data', () async {
      // Arrange
      await authService.login(testEmail, testPassword);
      
      // Act
      final response = await apiService.get(
        '/products', 
        authenticated: true
      );
      
      // Assert
      expect(response.isSuccess, isTrue);
      expect(response.data, isNotNull);
      expect(response.data['products'], isA<List>());
    });
    
    test('Add product to cart should succeed', () async {
      // Arrange
      await authService.login(testEmail, testPassword);
      final payload = {
        'productId': testProduct['id'],
        'quantity': 2
      };
      
      // Act
      final response = await apiService.post(
        '/cart/add', 
        body: payload,
        authenticated: true
      );
      
      // Assert
      expect(response.isSuccess, isTrue);
    });
    
    test('Place order should create a new order', () async {
      // Arrange
      await authService.login(testEmail, testPassword);
      final payload = {
        'items': [
          {
            'productId': testProduct['id'],
            'quantity': 2
          }
        ],
        'deliveryAddress': '123 Test St',
        'paymentMethod': 'credit_card'
      };
      
      // Act
      final response = await apiService.post(
        '/orders', 
        body: payload,
        authenticated: true
      );
      
      // Assert
      expect(response.isSuccess, isTrue);
      expect(response.data['orderId'], isNotNull);
    });
  });

  group('Farmer App API Integration Tests', () {
    test('Fetch farmer products should return valid data', () async {
      // Arrange - login as farmer
      await authService.login('farmer@example.com', 'farmerpass');
      
      // Act
      final response = await apiService.get(
        '/farmer/products', 
        authenticated: true
      );
      
      // Assert
      expect(response.isSuccess, isTrue);
      expect(response.data['products'], isA<List>());
    });
    
    test('Add new product should succeed', () async {
      // Arrange - login as farmer
      await authService.login('farmer@example.com', 'farmerpass');
      
      // Act
      final response = await apiService.post(
        '/farmer/products', 
        body: testFarmProduct,
        authenticated: true
      );
      
      // Assert
      expect(response.isSuccess, isTrue);
      expect(response.data['productId'], isNotNull);
    });
    
    test('Update product inventory should succeed', () async {
      // Arrange - login as farmer
      await authService.login('farmer@example.com', 'farmerpass');
      final payload = {
        'productId': testFarmProduct['id'],
        'quantity': 75
      };
      
      // Act
      final response = await apiService.put(
        '/farmer/products/${testFarmProduct['id']}/inventory', 
        body: payload,
        authenticated: true
      );
      
      // Assert
      expect(response.isSuccess, isTrue);
    });
  });

  group('Driver App API Integration Tests', () {
    test('Fetch assigned deliveries should return valid data', () async {
      // Arrange - login as driver
      await authService.login('driver@example.com', 'driverpass');
      
      // Act
      final response = await apiService.get(
        '/driver/deliveries', 
        authenticated: true
      );
      
      // Assert
      expect(response.isSuccess, isTrue);
      expect(response.data['deliveries'], isA<List>());
    });
    
    test('Update delivery status should succeed', () async {
      // Arrange - login as driver
      await authService.login('driver@example.com', 'driverpass');
      final payload = {
        'status': 'in_progress',
        'notes': 'On my way to customer'
      };
      
      // Act
      final response = await apiService.put(
        '/driver/deliveries/${testDelivery['id']}/status', 
        body: payload,
        authenticated: true
      );
      
      // Assert
      expect(response.isSuccess, isTrue);
    });
    
    test('Get optimized route should return valid route data', () async {
      // Arrange - login as driver
      await authService.login('driver@example.com', 'driverpass');
      
      // Act
      final response = await apiService.get(
        '/driver/route/optimize', 
        queryParams: {
          'deliveryIds': '${testDelivery['id']},del_456,del_789'
        },
        authenticated: true
      );
      
      // Assert
      expect(response.isSuccess, isTrue);
      expect(response.data['route'], isNotNull);
      expect(response.data['waypoints'], isA<List>());
    });
  });

  group('Error Handling Integration Tests', () {
    test('Invalid authentication should return 401', () async {
      // Act
      final loginResult = await authService.login('wrong@example.com', 'wrongpass');
      
      // Assert
      expect(loginResult, isFalse);
    });
    
    test('Unauthorized access should return 403', () async {
      // Arrange - login as consumer
      await authService.login(testEmail, testPassword);
      
      // Act - attempt to access farmer endpoint
      final response = await apiService.get(
        '/farmer/products', 
        authenticated: true
      );
      
      // Assert
      expect(response.isSuccess, isFalse);
      expect(response.statusCode, equals(403));
    });
    
    test('Invalid request should return 400', () async {
      // Arrange
      await authService.login(testEmail, testPassword);
      final invalidPayload = {
        'invalid': 'data'
      };
      
      // Act
      final response = await apiService.post(
        '/orders', 
        body: invalidPayload,
        authenticated: true
      );
      
      // Assert
      expect(response.isSuccess, isFalse);
      expect(response.statusCode, equals(400));
    });
  });
}
