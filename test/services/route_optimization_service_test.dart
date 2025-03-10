import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared/models/delivery.dart';
import 'package:shared/services/api_service.dart';
import 'package:shared/services/route_optimization_service.dart';
import 'package:shared/utils/logging_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Generate mocks
@GenerateMocks([ApiService, LoggingService])
import 'route_optimization_service_test.mocks.dart';

void main() {
  late RouteOptimizationService routeService;
  late MockApiService mockApiService;
  late MockLoggingService mockLoggingService;

  setUp(() {
    mockApiService = MockApiService();
    mockLoggingService = MockLoggingService();
    
    // Initialize the service with mocks
    routeService = RouteOptimizationService(
      apiService: mockApiService,
      loggingService: mockLoggingService,
    );
  });

  group('RouteOptimizationService Tests', () {
    test('optimizeRoute should make correct API call and handle success response', () async {
      // Arrange
      final startLocation = LatLng(37.7749, -122.4194);
      final deliveries = [
        Delivery(
          id: 'del123',
          orderId: 'ord456',
          customerId: 'cust789',
          status: 'pending',
          pickupAddress: '123 Farm Lane',
          pickupLatitude: 37.7800,
          pickupLongitude: -122.4100,
          dropoffAddress: '456 Market St',
          dropoffLatitude: 37.7900,
          dropoffLongitude: -122.4000,
          items: [],
          scheduledTime: DateTime.now(),
        ),
      ];
      
      final expectedSuccessResponse = ApiResponse(
        success: true,
        data: {
          'optimizationId': 'test-opt-123',
          'status': 'completed',
          'optimizedDeliveries': [
            {
              'id': 'del123',
              'sequence': 1,
              'estimatedArrival': '2025-03-04T19:00:00Z'
            }
          ],
          'routePoints': [
            {'latitude': 37.7749, 'longitude': -122.4194},
            {'latitude': 37.7800, 'longitude': -122.4100},
            {'latitude': 37.7900, 'longitude': -122.4000},
          ],
          'totalDistance': 5.2,
          'totalDuration': 15
        },
      );
      
      // Mock the API service response
      when(mockApiService.post(
        any,
        body: anyNamed('body'),
        headers: anyNamed('headers'),
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => expectedSuccessResponse);
      
      // Act
      final result = await routeService.optimizeRoute(
        startLocation: startLocation,
        deliveries: deliveries,
        useTraffic: true,
        useML: true,
      );
      
      // Assert
      expect(result.optimizationId, 'test-opt-123');
      expect(result.status, 'completed');
      expect(result.optimizedDeliveries.length, 1);
      expect(result.routePoints.length, 3);
      expect(result.routePoints[0].latitude, 37.7749);
      
      // Verify API was called correctly
      verify(mockApiService.post(
        any,
        body: captureAnyNamed('body'),
        headers: anyNamed('headers'),
        timeout: anyNamed('timeout'),
      )).called(1);
    });

    test('optimizeRoute should handle API error response', () async {
      // Arrange
      final startLocation = LatLng(37.7749, -122.4194);
      final deliveries = [
        Delivery(
          id: 'del123',
          orderId: 'ord456',
          customerId: 'cust789',
          status: 'pending',
          pickupAddress: '123 Farm Lane',
          pickupLatitude: 37.7800,
          pickupLongitude: -122.4100,
          dropoffAddress: '456 Market St',
          dropoffLatitude: 37.7900,
          dropoffLongitude: -122.4000,
          items: [],
          scheduledTime: DateTime.now(),
        ),
      ];
      
      final expectedErrorResponse = ApiResponse(
        success: false,
        error: ApiError(
          code: 'VALIDATION_ERROR',
          message: 'Invalid coordinates provided',
        ),
      );
      
      // Mock the API service response
      when(mockApiService.post(
        any,
        body: anyNamed('body'),
        headers: anyNamed('headers'),
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => expectedErrorResponse);
      
      // Act & Assert
      expect(
        () => routeService.optimizeRoute(
          startLocation: startLocation,
          deliveries: deliveries,
          useTraffic: true,
          useML: true,
        ),
        throwsA(isA<Exception>()),
      );
      
      // Verify logging service was called
      verify(mockLoggingService.error(any, any, any)).called(1);
    });

    test('checkOptimizationStatus should make correct API call', () async {
      // Arrange
      final optimizationId = 'test-opt-123';
      final currentLocation = LatLng(37.7780, -122.4150);
      final deliveries = [
        Delivery(
          id: 'del123',
          orderId: 'ord456',
          customerId: 'cust789',
          status: 'pending',
          pickupAddress: '123 Farm Lane',
          pickupLatitude: 37.7800,
          pickupLongitude: -122.4100,
          dropoffAddress: '456 Market St',
          dropoffLatitude: 37.7900,
          dropoffLongitude: -122.4000,
          items: [],
          scheduledTime: DateTime.now(),
        ),
      ];
      
      final expectedSuccessResponse = ApiResponse(
        success: true,
        data: {
          'optimizationId': optimizationId,
          'status': 'completed',
          'optimizedDeliveries': [
            {
              'id': 'del123',
              'sequence': 1,
              'estimatedArrival': '2025-03-04T19:00:00Z'
            }
          ],
          'routePoints': [
            {'latitude': 37.7749, 'longitude': -122.4194},
            {'latitude': 37.7800, 'longitude': -122.4100},
            {'latitude': 37.7900, 'longitude': -122.4000},
          ],
        },
      );
      
      // Mock the API service response
      when(mockApiService.get(
        any,
        queryParams: anyNamed('queryParams'),
        headers: anyNamed('headers'),
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => expectedSuccessResponse);
      
      // Act
      final result = await routeService.checkOptimizationStatus(
        optimizationId,
        deliveries,
        currentLocation,
      );
      
      // Assert
      expect(result.optimizationId, optimizationId);
      expect(result.status, 'completed');
      expect(result.optimizedDeliveries.length, 1);
      
      // Verify API was called correctly
      verify(mockApiService.get(
        any,
        queryParams: captureAnyNamed('queryParams'),
        headers: anyNamed('headers'),
        timeout: anyNamed('timeout'),
      )).called(1);
    });

    test('updateDriverLocation should send correct location data', () async {
      // Arrange
      final optimizationId = 'test-opt-123';
      final driverId = 'drv123';
      final location = LatLng(37.7780, -122.4150);
      
      final expectedSuccessResponse = ApiResponse(
        success: true,
        data: {
          'updatedEtas': [
            {
              'deliveryId': 'del456',
              'newEta': '2025-03-04T19:05:00Z'
            }
          ],
          'routeUpdates': {
            'needsRecalculation': false
          }
        },
      );
      
      // Mock the API service response
      when(mockApiService.post(
        any,
        body: anyNamed('body'),
        headers: anyNamed('headers'),
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => expectedSuccessResponse);
      
      // Act
      final result = await routeService.updateDriverLocation(
        driverId: driverId,
        optimizationId: optimizationId,
        location: location,
        heading: 90,
        speed: 25,
      );
      
      // Assert
      expect(result.success, true);
      expect(result.needsRecalculation, false);
      expect(result.updatedEtasByDeliveryId.length, 1);
      expect(result.updatedEtasByDeliveryId['del456'], isA<DateTime>());
      
      // Verify API was called correctly
      verify(mockApiService.post(
        any,
        body: captureAnyNamed('body'),
        headers: anyNamed('headers'),
        timeout: anyNamed('timeout'),
      )).called(1);
    });

    test('getDetailedRoute should return correct route details', () async {
      // Arrange
      final optimizationId = 'test-opt-123';
      
      final expectedSuccessResponse = ApiResponse(
        success: true,
        data: {
          'optimizationId': optimizationId,
          'waypoints': [
            {
              'location': {'latitude': 37.7749, 'longitude': -122.4194},
              'instruction': 'Start at your current location',
              'distance': 0,
              'duration': 0,
              'type': 'start'
            },
            {
              'location': {'latitude': 37.7725, 'longitude': -122.4197},
              'instruction': 'Turn right onto Market St',
              'distance': 0.3,
              'duration': 1,
              'type': 'navigation'
            },
          ],
          'polyline': 'encoded_polyline_string_here',
        },
      );
      
      // Mock the API service response
      when(mockApiService.get(
        any,
        headers: anyNamed('headers'),
        timeout: anyNamed('timeout'),
      )).thenAnswer((_) async => expectedSuccessResponse);
      
      // Act
      final result = await routeService.getDetailedRoute(optimizationId);
      
      // Assert
      expect(result.optimizationId, optimizationId);
      expect(result.waypoints.length, 2);
      expect(result.waypoints[0].instruction, 'Start at your current location');
      expect(result.waypoints[0].type, 'start');
      expect(result.encodedPolyline, 'encoded_polyline_string_here');
      
      // Verify API was called correctly
      verify(mockApiService.get(
        any,
        headers: anyNamed('headers'),
        timeout: anyNamed('timeout'),
      )).called(1);
    });
  });
}
