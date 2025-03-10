import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared/services/route_optimization_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  final RouteOptimizationService _routeOptimizationService =
      RouteOptimizationService();

  // Stream controller for location updates
  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  // Subscription for location updates
  StreamSubscription<Position>? _positionStreamSubscription;

  // Current optimization ID for location updates
  String? _currentOptimizationId;

  // Flag to indicate if location tracking is enabled
  bool _isTrackingEnabled = false;

  // Get the stream of location updates
  Stream<Position> get locationStream => _locationController.stream;

  // Get current location
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      if (kDebugMode) {
        print('Location services are disabled');
      }
      return null;
    }

    // Check for location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        if (kDebugMode) {
          print('Location permissions are denied');
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      if (kDebugMode) {
        print('Location permissions are permanently denied');
      }
      return null;
    }

    // Get current position
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location: $e');
      }
      return null;
    }
  }

  // Start tracking location with updates to the server
  Future<bool> startTracking({String? optimizationId}) async {
    if (_isTrackingEnabled) {
      updateOptimizationId(optimizationId);
      return true; // Already tracking
    }

    _currentOptimizationId = optimizationId;

    try {
      // Request permission if not already granted
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return false;
        }
      }

      // Start listening to location updates
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(_handleLocationUpdate);

      _isTrackingEnabled = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting location tracking: $e');
      }
      return false;
    }
  }

  // Stop tracking location
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTrackingEnabled = false;
    _currentOptimizationId = null;
  }

  // Update optimization ID for location updates
  void updateOptimizationId(String? optimizationId) {
    if (_currentOptimizationId != optimizationId) {
      _currentOptimizationId = optimizationId;
      
      // If we have a position, send an immediate update with the new optimization ID
      getCurrentLocation().then((position) {
        if (position != null) {
          _sendLocationToServer(position);
        }
      });
    }
  }

  // Handle location update
  void _handleLocationUpdate(Position position) {
    // Broadcast the position to listeners
    _locationController.add(position);

    // Send the position to the server
    _sendLocationToServer(position);
  }

  // Send location update to the server
  Future<void> _sendLocationToServer(Position position) async {
    try {
      final latLng = LatLng(position.latitude, position.longitude);
      await _routeOptimizationService.updateDriverLocation(
        latLng,
        _currentOptimizationId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending location to server: $e');
      }
    }
  }

  // Dispose of resources
  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
