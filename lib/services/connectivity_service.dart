import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared/utils/logging_service.dart';

enum NetworkStatus {
  connected,
  disconnected,
  connecting,
  unknown
}

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final LoggingService _logger = LoggingService('ConnectivityService');
  final StreamController<NetworkStatus> _connectionStatusController = StreamController<NetworkStatus>.broadcast();
  
  NetworkStatus _lastStatus = NetworkStatus.unknown;
  Timer? _connectionCheckTimer;
  final Duration _pingInterval = const Duration(seconds: 30);
  final Duration _pingTimeout = const Duration(seconds: 5);
  
  Stream<NetworkStatus> get connectionStatus => _connectionStatusController.stream;
  NetworkStatus get currentStatus => _lastStatus;
  
  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  
  factory ConnectivityService() {
    return _instance;
  }
  
  ConnectivityService._internal() {
    // Initialize the connection status
    _initConnectionStatus();
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    
    // Start periodic connection quality check
    _startPeriodicConnectionCheck();
  }
  
  // Initialize connectivity
  Future<void> _initConnectionStatus() async {
    try {
      _connectionStatusController.add(NetworkStatus.connecting);
      
      final result = await _connectivity.checkConnectivity();
      
      if (result != ConnectivityResult.none) {
        // Double-check with actual connection test
        final isReachable = await _isActuallyConnected();
        _updateConnectionStatus(isReachable ? NetworkStatus.connected : NetworkStatus.disconnected);
      } else {
        _updateConnectionStatus(NetworkStatus.disconnected);
      }
    } catch (e) {
      _logger.error('Failed to initialize connectivity: $e');
      _updateConnectionStatus(NetworkStatus.disconnected);
    }
  }
  
  // Handle connectivity change events
  void _handleConnectivityChange(ConnectivityResult result) async {
    _logger.info('Connectivity changed: $result');
    
    if (result == ConnectivityResult.none) {
      _updateConnectionStatus(NetworkStatus.disconnected);
    } else {
      // We have connectivity, but need to verify actual internet connection
      _connectionStatusController.add(NetworkStatus.connecting);
      final isReachable = await _isActuallyConnected();
      _updateConnectionStatus(isReachable ? NetworkStatus.connected : NetworkStatus.disconnected);
    }
  }
  
  // Update connection status with proper logging
  void _updateConnectionStatus(NetworkStatus status) {
    if (status != _lastStatus) {
      _lastStatus = status;
      _connectionStatusController.add(status);
      
      if (status == NetworkStatus.disconnected) {
        _logger.warn('Device is not connected to the internet');
      } else if (status == NetworkStatus.connected) {
        _logger.info('Device connected to the internet');
      }
    }
  }
  
  // Check if device actually has internet connection by pinging a reliable service
  Future<bool> _isActuallyConnected() async {
    try {
      // Try to reach Google's DNS server
      final result = await InternetAddress.lookup('8.8.8.8')
          .timeout(_pingTimeout);
      
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      _logger.warn('Socket exception while checking internet: $e');
      return false;
    } on TimeoutException catch (e) {
      _logger.warn('Timeout while checking internet: $e');
      return false;
    } catch (e) {
      _logger.error('Error checking internet connection: $e');
      return false;
    }
  }
  
  // Start a timer to periodically check connection quality
  void _startPeriodicConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(_pingInterval, (_) async {
      if (_lastStatus == NetworkStatus.connected) {
        final isConnected = await _isActuallyConnected();
        if (!isConnected) {
          _updateConnectionStatus(NetworkStatus.disconnected);
        }
      }
    });
  }
  
  // Check if device is connected to the internet
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      
      if (result != ConnectivityResult.none) {
        return await _isActuallyConnected();
      }
      return false;
    } catch (e) {
      _logger.error('Error checking connectivity: $e');
      return false;
    }
  }
  
  // Get current network type (wifi, mobile, etc)
  Future<String> getConnectionType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      
      if (result == ConnectivityResult.wifi) {
        return 'wifi';
      } else if (result == ConnectivityResult.mobile) {
        return 'mobile';
      } else if (result == ConnectivityResult.ethernet) {
        return 'ethernet';
      } else if (result == ConnectivityResult.bluetooth) {
        return 'bluetooth';
      } else {
        return 'none';
      }
    } catch (e) {
      _logger.error('Error getting connection type: $e');
      return 'unknown';
    }
  }
  
  // Dispose of resources
  void dispose() {
    _connectionCheckTimer?.cancel();
    _connectionStatusController.close();
  }
}
