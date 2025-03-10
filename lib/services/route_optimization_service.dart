import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared/models/delivery.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/config/api_config.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:shared/services/api_service.dart';
import 'package:shared/services/connectivity_service.dart';
import 'package:shared/utils/logging_service.dart';

class RouteOptimizationResult {
  final List<Delivery> optimizedDeliveries;
  final List<LatLng> routePoints;
  final int estimatedDurationInMinutes;
  final double estimatedDistanceInKm;
  final Map<String, dynamic>? additionalInfo;
  final String? optimizationId;

  RouteOptimizationResult({
    required this.optimizedDeliveries,
    required this.routePoints,
    required this.estimatedDurationInMinutes,
    required this.estimatedDistanceInKm,
    this.additionalInfo,
    this.optimizationId,
  });
}

class RouteOptimizationService {
  final AuthService _authService = AuthService();
  final PolylinePoints _polylinePoints = PolylinePoints();
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final LoggingService _logger = LoggingService('RouteOptimizationService');

  // Optimize route using the ML microservice
  Future<RouteOptimizationResult> optimizeRoute({
    required LatLng startLocation,
    required List<Delivery> deliveries,
    bool useTraffic = true,
    bool useML = true,
    String? vehicleType,
  }) async {
    if (deliveries.isEmpty) {
      return RouteOptimizationResult(
        optimizedDeliveries: [],
        routePoints: [],
        estimatedDurationInMinutes: 0,
        estimatedDistanceInKm: 0,
      );
    }

    // Check connectivity before making API call
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      _logger.warn('No internet connection. Using cached data if available.');
      return _getMockOptimizedRoute(startLocation, deliveries);
    }

    final token = await _authService.getAccessToken();

    if (token == null) {
      throw Exception('User not authenticated');
    }

    // Prepare the request data to match API expectations
    final requestData = {
      'locations': [
        // Add driver location as starting point
        {
          'id': 'driver_start',
          'address': 'Driver Location',
          'latitude': startLocation.latitude,
          'longitude': startLocation.longitude,
          'location_type': 'WAREHOUSE',
          'service_time_minutes': 0,
        },
        // Map deliveries to locations (both pickup and dropoff)
        for (var delivery in deliveries) ...[
          // Pickup location
          {
            'id': 'pickup_${delivery.id}',
            'address': delivery.pickupAddress,
            'latitude': delivery.pickupLatitude,
            'longitude': delivery.pickupLongitude,
            'location_type': 'PICKUP',
            'service_time_minutes': 5,
            'time_window_start':
                delivery.timeWindows?.first.start.toIso8601String(),
            'time_window_end':
                delivery.timeWindows?.first.end.toIso8601String(),
          },
          // Dropoff location
          {
            'id': 'dropoff_${delivery.id}',
            'address': delivery.dropoffAddress,
            'latitude': delivery.dropoffLatitude,
            'longitude': delivery.dropoffLongitude,
            'location_type': 'DELIVERY',
            'service_time_minutes': 2,
            'priority': delivery.priority,
          },
        ],
      ],
      'driver_location': {
        'driver_id': 'current_driver',
        'latitude': startLocation.latitude,
        'longitude': startLocation.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'preferences': {
        'priority': 'BALANCED',
        'avoid_highways': false,
        'avoid_tolls': false,
        'avoid_traffic': !useTraffic,
        'max_stops_per_route': null,
      },
      'time_window_minutes': 60,
    };

    try {
      // Use the ApiService instead of direct http calls for better error handling
      final response = await _apiService.post(
        ApiConfig.getRouteOptimizationUrl(ApiConfig.routeOptimizeEndpoint),
        body: requestData,
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        final data = response.data;

        // If job is queued and being processed asynchronously
        if (response.statusCode == 202 || data['status'] == 'PROCESSING') {
          final optimizationId = data['optimization_id'];
          // Return a partial result, client will need to check status later
          return RouteOptimizationResult(
            optimizedDeliveries: deliveries,
            routePoints: [],
            estimatedDurationInMinutes: 0,
            estimatedDistanceInKm: 0,
            additionalInfo: {
              'status': 'processing',
              'message':
                  'Optimization in progress, check status with optimizationId',
            },
            optimizationId: optimizationId,
          );
        }

        // If optimization is complete immediately
        final routePreview = List<String>.from(data['route_preview'] ?? []);
        final optimizationId = data['optimization_id'];

        // Reorder deliveries based on optimized sequence
        final optimizedDeliveries =
            _reorderDeliveries(routePreview, deliveries);

        // Get the detailed route immediately
        final detailedRouteResult = await getOptimizationRoute(optimizationId);

        return RouteOptimizationResult(
          optimizedDeliveries: optimizedDeliveries,
          routePoints: detailedRouteResult.routePoints,
          estimatedDurationInMinutes:
              detailedRouteResult.estimatedDurationInMinutes,
          estimatedDistanceInKm: detailedRouteResult.estimatedDistanceInKm,
          additionalInfo: {'message': data['message']},
          optimizationId: optimizationId,
        );
      } else {
        _logger.error('Failed to optimize route: ${response.statusCode}');
        throw Exception('Failed to optimize route: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error during route optimization: $e');
      // For development and testing, return a fallback mock result if API is unavailable
      return _getMockOptimizedRoute(startLocation, deliveries);
    }
  }

  // Check status of an ongoing optimization
  Future<RouteOptimizationResult> checkOptimizationStatus(String optimizationId,
      List<Delivery> originalDeliveries, LatLng startLocation) async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      _logger.warn('No internet connection when checking optimization status');
      throw Exception('No internet connection');
    }

    try {
      final response = await _apiService.get(
        '${ApiConfig.getRouteOptimizationUrl(ApiConfig.routeStatusEndpoint)}/$optimizationId',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final status = data['status'];

        // If still processing, return a partial result
        if (status == 'PROCESSING' || status == 'PENDING') {
          return RouteOptimizationResult(
            optimizedDeliveries: originalDeliveries,
            routePoints: [],
            estimatedDurationInMinutes: 0,
            estimatedDistanceInKm: 0,
            additionalInfo: {
              'status': 'processing',
              'progress': data['progress_percentage'],
              'message': data['message'] ?? 'Optimization still in progress',
            },
            optimizationId: optimizationId,
          );
        }

        // If complete, fetch the full route details
        if (status == 'COMPLETED') {
          return await getOptimizationRoute(optimizationId);
        }

        // If failed
        throw Exception(data['message'] ?? 'Optimization failed');
      } else {
        _logger.error(
            'Failed to check optimization status: ${response.statusCode}');
        throw Exception(
            'Failed to check optimization status: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error checking optimization status: $e');
      throw Exception('Error checking optimization status: $e');
    }
  }

  // Get detailed optimization route with turn-by-turn directions
  Future<RouteOptimizationResult> getOptimizationRoute(
      String optimizationId) async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      _logger.warn('No internet connection when getting route');
      throw Exception('No internet connection');
    }

    try {
      final response = await _apiService.get(
        '${ApiConfig.getRouteOptimizationUrl(ApiConfig.routeDetailsEndpoint)}/$optimizationId',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Extract the route points
        List<LatLng> routePoints = [];

        if (data['polyline'] != null) {
          final polylineResult =
              _polylinePoints.decodePolyline(data['polyline']);
          routePoints = polylineResult
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        } else if (data['route'] != null) {
          // Manual extraction from waypoints if polyline is not available
          final route = List<Map<String, dynamic>>.from(data['route']);
          routePoints = route
              .map((waypoint) => LatLng(
                    waypoint['latitude'] as double,
                    waypoint['longitude'] as double,
                  ))
              .toList();
        }

        // Extract the optimized delivery list based on the route
        List<Delivery> optimizedDeliveries = [];
        if (data['deliveries'] != null) {
          optimizedDeliveries =
              List<Map<String, dynamic>>.from(data['deliveries'])
                  .map((item) => Delivery.fromJson(item))
                  .toList();
        }

        return RouteOptimizationResult(
          optimizedDeliveries: optimizedDeliveries,
          routePoints: routePoints,
          estimatedDurationInMinutes:
              (data['total_time_minutes'] as num).round(),
          estimatedDistanceInKm: data['total_distance_km'] as double,
          additionalInfo: {'details': data['directions'] ?? []},
          optimizationId: optimizationId,
        );
      } else {
        _logger
            .error('Failed to get optimization route: ${response.statusCode}');
        throw Exception('Failed to get optimization route');
      }
    } catch (e) {
      _logger.error('Error getting optimization route: $e');
      throw Exception('Error getting optimization route: $e');
    }
  }

  // Update driver location to the route optimization service
  Future<bool> updateDriverLocation(
      String driverId, double latitude, double longitude,
      {String? optimizationId}) async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      _logger.warn('No internet connection when updating driver location');
      return false;
    }

    try {
      final requestData = {
        'driver_id': driverId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'optimization_id': optimizationId,
      };

      final response = await _apiService.post(
        ApiConfig.getRouteOptimizationUrl(ApiConfig.driverLocationEndpoint),
        body: requestData,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _logger
            .error('Failed to update driver location: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.error('Error updating driver location: $e');
      return false;
    }
  }

  // Get delivery heatmap data
  Future<Map<String, dynamic>> getDeliveryHeatmap(
      {String? region, String? timeRange}) async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      _logger.warn('No internet connection when getting heatmap');
      throw Exception('No internet connection');
    }

    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (region != null) queryParams['region'] = region;
      if (timeRange != null) queryParams['time_range'] = timeRange;

      final uri = Uri.parse(
              ApiConfig.getRouteOptimizationUrl(ApiConfig.heatmapEndpoint))
          .replace(queryParameters: queryParams);

      final response = await _apiService.get(
        uri.toString(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        _logger.error('Failed to get heatmap data: ${response.statusCode}');
        throw Exception('Failed to get heatmap data: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error getting heatmap data: $e');
      throw Exception('Error getting heatmap data: $e');
    }
  }

  // Reorder deliveries based on location IDs
  List<Delivery> _reorderDeliveries(
      List<String> locationIds, List<Delivery> originalDeliveries) {
    // Create a map of delivery IDs to deliveries
    final deliveryMap = {for (var d in originalDeliveries) d.id: d};

    // Extract delivery IDs from location IDs (format: pickup_DELIVERY_ID or dropoff_DELIVERY_ID)
    final orderedDeliveryIds = <String>{};
    for (var locationId in locationIds) {
      if (locationId.startsWith('pickup_') ||
          locationId.startsWith('dropoff_')) {
        final deliveryId = locationId.split('_')[1];
        orderedDeliveryIds.add(deliveryId);
      }
    }

    // Create ordered list, maintaining original items if not found in the order
    final orderedDeliveries = <Delivery>[];

    // Add ordered deliveries first
    for (var id in orderedDeliveryIds) {
      if (deliveryMap.containsKey(id)) {
        orderedDeliveries.add(deliveryMap[id]!);
        deliveryMap.remove(id);
      }
    }

    // Add any remaining deliveries not in the order
    orderedDeliveries.addAll(deliveryMap.values);

    return orderedDeliveries;
  }

  // Generate a mock optimized route for development and testing
  Future<RouteOptimizationResult> _getMockOptimizedRoute(
      LatLng startLocation, List<Delivery> deliveries) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // For mock purposes, just sort by distance from start location
    final sortedDeliveries = List<Delivery>.from(deliveries);
    sortedDeliveries.sort((a, b) {
      final distA = _calculateDistance(
        startLocation.latitude,
        startLocation.longitude,
        a.dropoffLatitude,
        a.dropoffLongitude,
      );
      final distB = _calculateDistance(
        startLocation.latitude,
        startLocation.longitude,
        b.dropoffLatitude,
        b.dropoffLongitude,
      );
      return distA.compareTo(distB);
    });

    // Generate mock route points (straight lines between locations)
    List<LatLng> routePoints = [startLocation];

    // Add pickup and dropoff points to the route
    for (var delivery in sortedDeliveries) {
      // Add pickup point
      routePoints
          .add(LatLng(delivery.pickupLatitude, delivery.pickupLongitude));

      // Add dropoff point
      routePoints
          .add(LatLng(delivery.dropoffLatitude, delivery.dropoffLongitude));
    }

    // Calculate estimated distance and duration
    double totalDistance = 0;
    for (var i = 0; i < routePoints.length - 1; i++) {
      totalDistance += _calculateDistance(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
    }

    // Estimate duration (assuming average speed of 30 km/h)
    final estimatedDuration = (totalDistance / 30 * 60).round();

    return RouteOptimizationResult(
      optimizedDeliveries: sortedDeliveries,
      routePoints: routePoints,
      estimatedDurationInMinutes: estimatedDuration,
      estimatedDistanceInKm: totalDistance,
      additionalInfo: {'source': 'mock'},
      optimizationId: 'mock-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  // Helper method to calculate distance between two points using Haversine formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        (dLon / 2).sin() * (dLon / 2).sin() * lat1.cos() * lat2.cos();
    final c = 2 * a.atan2((1 - a).sqrt());

    return R * c; // Distance in km
  }

  // Helper method to convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * (3.14159 / 180);
  }
}
