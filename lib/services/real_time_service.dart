import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/order.dart';
import '../utils/api_utils.dart';

class RealTimeService {
  static final RealTimeService _instance = RealTimeService._internal();
  WebSocketChannel? _channel;
  bool _isConnected = false;
  
  String _userId = '';
  String _userType = ''; // 'farmer', 'driver', or 'consumer'
  
  // Stream controllers for different notification types
  final _orderUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  final _inventoryUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  final _generalUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  
  // Public streams that other classes can listen to
  Stream<Map<String, dynamic>> get orderUpdates => _orderUpdatesController.stream;
  Stream<Map<String, dynamic>> get messageUpdates => _messageUpdatesController.stream;
  Stream<Map<String, dynamic>> get inventoryUpdates => _inventoryUpdatesController.stream;
  Stream<Map<String, dynamic>> get generalUpdates => _generalUpdatesController.stream;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // Reconnection properties
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 2);
  String? _authToken;

  factory RealTimeService() {
    return _instance;
  }

  RealTimeService._internal();

  // Initialize the WebSocket connection
  Future<void> initialize({
    required String userId,
    required String userType,
    required String authToken,
  }) async {
    _userId = userId;
    _userType = userType;
    _authToken = authToken;
    
    await _connect();
  }
  
  Future<void> _connect() async {
    if (_isConnected) {
      return;
    }
    
    try {
      // Check for internet connection first
      final hasConnection = await ApiUtils.hasInternetConnection();
      if (!hasConnection) {
        _connectionStatusController.add(false);
        _scheduleReconnect();
        return;
      }
      
      final wsUrl = Uri.parse('wss://${FreshConfig.apiBaseUrl.replaceFirst('https://', '')}/ws?token=$_authToken&user_type=$_userType');
      
      _channel = IOWebSocketChannel.connect(
        wsUrl,
        pingInterval: const Duration(seconds: 30),
      );
      
      _connectionStatusController.add(true);
      _isConnected = true;
      _reconnectAttempts = 0;
      
      // Listen for incoming messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      
      // Send authentication message
      _sendMessage({
        'type': 'auth',
        'user_id': _userId,
        'user_type': _userType,
      });
      
      debugPrint('WebSocket connected successfully');
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _isConnected = false;
      _connectionStatusController.add(false);
      
      _scheduleReconnect();
    }
  }
  
  void _scheduleReconnect() {
    // Cancel any existing reconnect timer
    _reconnectTimer?.cancel();
    
    // If we've reached the maximum reconnection attempts, notify the user
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Maximum reconnection attempts reached.');
      return;
    }
    
    // Exponential backoff for reconnect attempts
    final delay = _initialReconnectDelay * pow(1.5, _reconnectAttempts);
    debugPrint('Scheduling reconnect in ${delay.inSeconds} seconds (attempt ${_reconnectAttempts + 1})');
    
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _connect();
    });
  }
  
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      final String type = data['type'] ?? 'general';
      
      switch (type) {
        case 'order_update':
          _orderUpdatesController.add(data);
          break;
        case 'message':
          _messageUpdatesController.add(data);
          break;
        case 'inventory_update':
          _inventoryUpdatesController.add(data);
          break;
        case 'pong':
          // Heartbeat response, no need to propagate
          break;
        default:
          _generalUpdatesController.add(data);
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }
  
  void _onError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _isConnected = false;
    _connectionStatusController.add(false);
    _scheduleReconnect();
  }
  
  void _onDone() {
    debugPrint('WebSocket connection closed');
    _isConnected = false;
    _connectionStatusController.add(false);
    
    // Only attempt to reconnect if not explicitly closed
    if (_channel != null) {
      _scheduleReconnect();
    }
  }
  
  void _sendMessage(Map<String, dynamic> message) {
    if (!_isConnected) {
      debugPrint('Cannot send message: WebSocket not connected');
      return;
    }
    
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('Error sending WebSocket message: $e');
      // Connection might be broken, try to reconnect
      _isConnected = false;
      _connectionStatusController.add(false);
      _scheduleReconnect();
    }
  }
  
  // Subscribe to specific events based on user type
  Future<void> subscribeToEvents() async {
    final subscriptions = <String>[];
    
    // Common subscriptions for all user types
    subscriptions.add('user_notifications');
    
    // User-type specific subscriptions
    switch (_userType) {
      case 'farmer':
        subscriptions.addAll(['farm_orders', 'inventory_changes']);
        break;
      case 'driver':
        subscriptions.addAll(['delivery_assignments', 'route_updates']);
        break;
      case 'consumer':
        subscriptions.addAll(['order_updates', 'farm_updates']);
        break;
    }
    
    _sendMessage({
      'type': 'subscribe',
      'channels': subscriptions,
    });
  }
  
  // Send a direct message to another user
  Future<void> sendDirectMessage({
    required String recipientId,
    required String content,
  }) async {
    final message = {
      'type': 'message',
      'recipient_id': recipientId,
      'sender_id': _userId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(message);
  }
  
  // Manually trigger reconnection
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    _connect();
  }
  
  // Send heartbeat to keep connection alive
  void sendHeartbeat() {
    if (_isConnected) {
      _sendMessage({
        'type': 'ping',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
  
  // Close WebSocket connection
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    
    if (_channel != null) {
      try {
        _channel!.sink.close();
        _channel = null;
      } catch (e) {
        debugPrint('Error closing WebSocket: $e');
      }
    }
    
    _isConnected = false;
    _connectionStatusController.add(false);
  }
  
  // Dispose method to clean up resources
  void dispose() {
    disconnect();
    
    _orderUpdatesController.close();
    _messageUpdatesController.close();
    _inventoryUpdatesController.close();
    _generalUpdatesController.close();
    _connectionStatusController.close();
  }
}
