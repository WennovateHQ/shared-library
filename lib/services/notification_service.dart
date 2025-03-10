import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  Future<void> initialize() async {
    // In test mode, we don't need to initialize the actual notification plugin
    if (FreshConfig.testingMode) {
      debugPrint('NotificationService: Initializing in test mode');
      return;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      final payloadMap = {
        'action': 'tap',
        'payload': payload,
      };
      _notificationController.add(payloadMap);
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Handle test mode - log notification instead of showing it
    if (FreshConfig.testingMode) {
      debugPrint('TEST NOTIFICATION: ID=$id, TITLE=$title, BODY=$body, PAYLOAD=$payload');
      
      // Emit to stream for test mode to simulate tap
      final payloadMap = {
        'action': 'test_notification',
        'id': id,
        'title': title,
        'body': body,
        'payload': payload,
      };
      _notificationController.add(payloadMap);
      
      return;
    }
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'freshfarmily_channel',
      'FreshFarmily Notifications',
      channelDescription: 'Notifications from FreshFarmily',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );
    
    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (FreshConfig.testingMode) {
      debugPrint('TEST MODE: Cancelling notification with ID=$id');
      return;
    }
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    if (FreshConfig.testingMode) {
      debugPrint('TEST MODE: Cancelling all notifications');
      return;
    }
    await _notificationsPlugin.cancelAll();
  }

  // Forum-specific notifications
  Future<void> showForumReplyNotification({
    required String postId,
    required String userName,
    required String content,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await showNotification(
      id: id,
      title: '$userName replied to your post',
      body: content.length > 50 ? '${content.substring(0, 47)}...' : content,
      payload: 'forum_reply:$postId',
    );
  }

  // Order-specific notifications
  Future<void> showOrderStatusNotification({
    required String orderId,
    required String status,
    required String details,
  }) async {
    final id = int.parse(orderId.hashCode.toString().substring(0, 5).replaceAll('-', ''));
    
    String title;
    switch (status.toLowerCase()) {
      case 'accepted':
        title = 'Order Confirmed!';
        break;
      case 'processing':
        title = 'Order Processing';
        break;
      case 'ready':
        title = 'Order Ready for Pickup/Delivery';
        break;
      case 'delivered':
        title = 'Order Delivered';
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        break;
      default:
        title = 'Order Update';
    }
    
    await showNotification(
      id: id,
      title: title,
      body: details,
      payload: 'order:$orderId',
    );
  }

  // Product notifications
  Future<void> showProductRestockNotification({
    required String productId,
    required String productName,
  }) async {
    final id = int.parse(productId.hashCode.toString().substring(0, 5).replaceAll('-', ''));
    await showNotification(
      id: id,
      title: 'Back in Stock!',
      body: '$productName is now available.',
      payload: 'product:$productId',
    );
  }

  // Simulate notifications for test mode
  Future<void> simulateNotificationsForTesting() async {
    if (!FreshConfig.testingMode) return;
    
    // Simulate a series of test notifications with delay
    debugPrint('Simulating notifications for testing...');
    
    // Order status notification
    await Future.delayed(const Duration(seconds: 3));
    await showOrderStatusNotification(
      orderId: 'test_order_123',
      status: 'accepted',
      details: 'Your order #123 has been confirmed and is being prepared!',
    );
    
    // Product restock
    await Future.delayed(const Duration(seconds: 5));
    await showProductRestockNotification(
      productId: 'test_prod_456',
      productName: 'Organic Strawberries',
    );
    
    // Forum reply
    await Future.delayed(const Duration(seconds: 7));
    await showForumReplyNotification(
      postId: 'test_post_789',
      userName: 'FarmFresh Community',
      content: 'Thanks for your question! Here\'s some information about organic farming practices...',
    );
  }

  void dispose() {
    _notificationController.close();
  }
}
