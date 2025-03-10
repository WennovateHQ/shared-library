import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:shared/services/api_service.dart';
import 'package:shared/utils/logging_service.dart';
import 'package:shared/services/connectivity_service.dart';

// Generate mocks
@GenerateMocks([http.Client, LoggingService, ConnectivityService])
import 'api_service_test.mocks.dart';

void main() {
  late ApiService apiService;
  late MockClient mockHttpClient;
  late MockLoggingService mockLoggingService;
  late MockConnectivityService mockConnectivityService;

  setUp(() {
    mockHttpClient = MockClient();
    mockLoggingService = MockLoggingService();
    mockConnectivityService = MockConnectivityService();
    
    // Initialize the service with mocks
    apiService = ApiService(
      httpClient: mockHttpClient,
      loggingService: mockLoggingService,
      connectivityService: mockConnectivityService,
    );
  });

  group('ApiService Tests', () {
    test('get should make correct HTTP request and parse successful response', () async {
      // Arrange
      final url = 'https://api.freshfarmily.com/v1/deliveries';
      final successfulResponse = '''
      {
        "success": true,
        "data": {
          "deliveries": [
            {
              "id": "del123",
              "orderId": "ord456",
              "status": "pending"
            }
          ]
        }
      }
      ''';
      
      // Mock connectivity check to return true
      when(mockConnectivityService.checkConnectivity())
          .thenAnswer((_) async => true);
      
      // Mock HTTP response
      when(mockHttpClient.get(
        Uri.parse(url),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(successfulResponse, 200));
      
      // Act
      final response = await apiService.get(url);
      
      // Assert
      expect(response.success, true);
      expect(response.data?['deliveries'], isA<List>());
      expect(response.data?['deliveries'][0]['id'], 'del123');
      expect(response.error, isNull);
      
      // Verify HTTP client was called correctly
      verify(mockHttpClient.get(
        Uri.parse(url),
        headers: anyNamed('headers'),
      )).called(1);
    });

    test('get should handle error response correctly', () async {
      // Arrange
      final url = 'https://api.freshfarmily.com/v1/deliveries/invalid';
      final errorResponse = '''
      {
        "success": false,
        "error": {
          "code": "NOT_FOUND",
          "message": "Delivery not found"
        }
      }
      ''';
      
      // Mock connectivity check to return true
      when(mockConnectivityService.checkConnectivity())
          .thenAnswer((_) async => true);
      
      // Mock HTTP response
      when(mockHttpClient.get(
        Uri.parse(url),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(errorResponse, 404));
      
      // Act
      final response = await apiService.get(url);
      
      // Assert
      expect(response.success, false);
      expect(response.data, isNull);
      expect(response.error?.code, 'NOT_FOUND');
      expect(response.error?.message, 'Delivery not found');
      
      // Verify logging occurred
      verify(mockLoggingService.error(any, any, any)).called(1);
    });

    test('post should send correct data and handle successful response', () async {
      // Arrange
      final url = 'https://api.freshfarmily.com/v1/deliveries/accept';
      final requestBody = {'deliveryId': 'del123'};
      final successfulResponse = '''
      {
        "success": true,
        "data": {
          "message": "Delivery accepted successfully",
          "deliveryId": "del123",
          "status": "accepted"
        }
      }
      ''';
      
      // Mock connectivity check to return true
      when(mockConnectivityService.checkConnectivity())
          .thenAnswer((_) async => true);
      
      // Mock HTTP response
      when(mockHttpClient.post(
        Uri.parse(url),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(successfulResponse, 200));
      
      // Act
      final response = await apiService.post(url, body: requestBody);
      
      // Assert
      expect(response.success, true);
      expect(response.data?['message'], 'Delivery accepted successfully');
      expect(response.data?['deliveryId'], 'del123');
      expect(response.error, isNull);
      
      // Verify HTTP client was called correctly
      verify(mockHttpClient.post(
        Uri.parse(url),
        headers: captureAnyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);
    });

    test('should handle no internet connectivity', () async {
      // Arrange
      final url = 'https://api.freshfarmily.com/v1/deliveries';
      
      // Mock connectivity check to return false
      when(mockConnectivityService.checkConnectivity())
          .thenAnswer((_) async => false);
      
      // Act & Assert
      expect(
        () => apiService.get(url),
        throwsA(predicate((e) => 
          e is ApiException && e.code == 'NO_CONNECTIVITY')),
      );
      
      // Verify HTTP client was NOT called
      verifyNever(mockHttpClient.get(any, headers: anyNamed('headers')));
      
      // Verify logging occurred
      verify(mockLoggingService.warn(any, any, any)).called(1);
    });

    test('should handle network timeout', () async {
      // Arrange
      final url = 'https://api.freshfarmily.com/v1/deliveries';
      
      // Mock connectivity check to return true
      when(mockConnectivityService.checkConnectivity())
          .thenAnswer((_) async => true);
      
      // Mock HTTP timeout
      when(mockHttpClient.get(
        Uri.parse(url),
        headers: anyNamed('headers'),
      )).thenThrow(http.ClientException('Connection timeout'));
      
      // Act & Assert
      expect(
        () => apiService.get(url),
        throwsA(predicate((e) => 
          e is ApiException && e.code == 'CONNECTION_ERROR')),
      );
      
      // Verify logging occurred
      verify(mockLoggingService.error(any, any, any)).called(1);
    });

    test('should handle invalid JSON response', () async {
      // Arrange
      final url = 'https://api.freshfarmily.com/v1/deliveries';
      final invalidResponse = '{invalid json}';
      
      // Mock connectivity check to return true
      when(mockConnectivityService.checkConnectivity())
          .thenAnswer((_) async => true);
      
      // Mock HTTP response with invalid JSON
      when(mockHttpClient.get(
        Uri.parse(url),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(invalidResponse, 200));
      
      // Act & Assert
      expect(
        () => apiService.get(url),
        throwsA(predicate((e) => 
          e is ApiException && e.code == 'INVALID_RESPONSE')),
      );
      
      // Verify logging occurred
      verify(mockLoggingService.error(any, any, any)).called(1);
    });
  });
}
