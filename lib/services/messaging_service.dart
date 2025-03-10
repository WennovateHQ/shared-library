import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import 'real_time_service.dart';
import '../config.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  
  late String _userId;
  late String _userType;
  late String _userName;
  
  final RealTimeService _realTimeService = RealTimeService();
  final List<Conversation> _conversations = [];
  final _conversationsController = StreamController<List<Conversation>>.broadcast();
  
  // Public stream that other classes can listen to
  Stream<List<Conversation>> get conversationsStream => _conversationsController.stream;
  
  factory MessagingService() {
    return _instance;
  }
  
  MessagingService._internal();
  
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  
  // Initialize the service
  Future<void> initialize({
    required String userId,
    required String userType,
    required String userName,
  }) async {
    _userId = userId;
    _userType = userType;
    _userName = userName;
    
    // Handle test mode
    if (FreshConfig.testingMode) {
      debugPrint('MessagingService: Initializing in test mode with mock data');
      _initializeTestMode();
      return;
    }
    
    // Load conversations from local storage
    await _loadConversations();
    
    // Listen for real-time message updates
    _realTimeService.messageUpdates.listen(_handleIncomingMessage);
  }
  
  // Initialize test mode with mock data
  void _initializeTestMode() {
    _conversations.clear();
    
    // Add mock conversations with sample messages
    _conversations.addAll(_getMockConversations());
    
    // Sort conversations by last updated timestamp (most recent first)
    _conversations.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    
    // Notify listeners
    _conversationsController.add(List.unmodifiable(_conversations));
  }
  
  // Send a message to another user
  Future<void> sendMessage({
    required String recipientId,
    required String recipientType,
    required String recipientName,
    required String text,
    String? orderId,
  }) async {
    // Create a message object
    final timestamp = DateTime.now();
    final messageId = '${_userId}_${timestamp.millisecondsSinceEpoch}';
    
    final message = Message(
      id: messageId,
      senderId: _userId,
      senderType: _userType,
      senderName: _userName,
      recipientId: recipientId,
      recipientType: recipientType,
      text: text,
      timestamp: timestamp,
      orderId: orderId,
    );
    
    // Handle test mode
    if (FreshConfig.testingMode) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Update local conversations
      _updateConversationWithMessage(message);
      
      // Simulate a response in test mode
      _simulateResponseInTestMode(recipientId, recipientType, recipientName, text, orderId);
      
      return;
    }
    
    // Send message via real-time service
    _realTimeService.sendDirectMessage(recipientId, recipientType, text);
    
    // Update local conversations
    _updateConversationWithMessage(message);
    
    // Save updated conversations to local storage
    _saveConversations();
  }
  
  // Simulate a response message in test mode
  Future<void> _simulateResponseInTestMode(
    String recipientId, 
    String recipientType, 
    String recipientName,
    String originalText,
    String? orderId
  ) async {
    // Delay to simulate the other user typing
    await Future.delayed(const Duration(seconds: 2));
    
    // Generate a response based on the original message
    String responseText;
    if (originalText.toLowerCase().contains('hello') || 
        originalText.toLowerCase().contains('hi')) {
      responseText = 'Hello! How can I help you today?';
    } else if (originalText.toLowerCase().contains('order')) {
      responseText = 'Your order is being processed. Is there anything specific you\'d like to know about it?';
    } else if (originalText.toLowerCase().contains('delivery')) {
      responseText = 'Deliveries typically take 1-2 days. We\'ll notify you when your order is on the way!';
    } else if (originalText.toLowerCase().contains('price') || 
              originalText.toLowerCase().contains('cost')) {
      responseText = 'We offer competitive prices. If you have any questions about specific products, feel free to ask!';
    } else if (originalText.toLowerCase().contains('thank')) {
      responseText = 'You\'re welcome! Let me know if you need anything else.';
    } else {
      responseText = 'Thanks for your message. I\'ll get back to you as soon as possible!';
    }
    
    // Create the response message
    final timestamp = DateTime.now();
    final messageId = '${recipientId}_${timestamp.millisecondsSinceEpoch}';
    
    final message = Message(
      id: messageId,
      senderId: recipientId,
      senderType: recipientType,
      senderName: recipientName,
      recipientId: _userId,
      recipientType: _userType,
      text: responseText,
      timestamp: timestamp,
      orderId: orderId,
    );
    
    // Update local conversations
    _updateConversationWithMessage(message);
  }
  
  // Handle an incoming message from the real-time service
  void _handleIncomingMessage(Map<String, dynamic> data) {
    // Convert WebSocket data to Message object
    final message = Message.fromJson(data);
    
    // Update local conversations
    _updateConversationWithMessage(message);
    
    // Save updated conversations to local storage
    _saveConversations();
  }
  
  // Update or create a conversation with a new message
  void _updateConversationWithMessage(Message message) {
    final bool isIncoming = message.senderId != _userId;
    final otherUserId = isIncoming ? message.senderId : message.recipientId ?? '';
    final otherUserType = isIncoming ? message.senderType : message.recipientType ?? '';
    final otherUserName = isIncoming ? message.senderName : message.recipientName ?? '';
    
    // Find existing conversation
    int existingIndex = _conversations.indexWhere(
      (conv) => conv.otherUserId == otherUserId
    );
    
    if (existingIndex >= 0) {
      // Update existing conversation
      _conversations[existingIndex] = _conversations[existingIndex].addMessage(message, _userId);
    } else {
      // Create new conversation
      _conversations.add(Conversation.fromMessage(message, _userId));
    }
    
    // Sort conversations by last updated timestamp (most recent first)
    _conversations.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    
    // Notify listeners
    _conversationsController.add(List.unmodifiable(_conversations));
    
    // Save to local storage (skip in test mode)
    if (!FreshConfig.testingMode) {
      _saveConversations();
    }
  }
  
  // Mark all messages in a conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    int index = _conversations.indexWhere((conv) => conv.id == conversationId);
    
    if (index >= 0 && _conversations[index].unreadMessages) {
      _conversations[index] = _conversations[index].markAsRead();
      
      // Notify listeners
      _conversationsController.add(List.unmodifiable(_conversations));
      
      // Save updated conversations to local storage (skip in test mode)
      if (!FreshConfig.testingMode) {
        _saveConversations();
      }
    }
  }
  
  // Load conversations from local storage
  Future<void> _loadConversations() async {
    // Skip loading in test mode
    if (FreshConfig.testingMode) {
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonData = prefs.getString('driver_conversations');
      
      if (jsonData != null && jsonData.isNotEmpty) {
        final List<dynamic> convData = jsonDecode(jsonData);
        
        for (var convJson in convData) {
          final String id = convJson['id'];
          final String otherUserId = convJson['otherUserId'];
          final String otherUserType = convJson['otherUserType'];
          final String otherUserName = convJson['otherUserName'];
          final String? orderId = convJson['orderId'];
          final DateTime lastUpdated = DateTime.parse(convJson['lastUpdated']);
          final bool unreadMessages = convJson['unreadMessages'] ?? false;
          
          // Deserialize messages
          final List<Message> messages = [];
          for (var msgJson in convJson['messages']) {
            messages.add(Message.fromJson(msgJson));
          }
          
          final conversation = Conversation(
            id: id,
            otherUserId: otherUserId,
            otherUserType: otherUserType,
            otherUserName: otherUserName,
            messages: messages,
            orderId: orderId,
            lastUpdated: lastUpdated,
            unreadMessages: unreadMessages,
          );
          
          _conversations.add(conversation);
        }
        
        // Sort conversations by last updated timestamp (most recent first)
        _conversations.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        
        // Notify listeners
        _conversationsController.add(List.unmodifiable(_conversations));
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }
  
  // Save conversations to local storage
  Future<void> _saveConversations() async {
    // Skip saving in test mode
    if (FreshConfig.testingMode) {
      return;
    }
    
    try {
      final List<Map<String, dynamic>> convData = _conversations.map((conv) {
        final List<Map<String, dynamic>> messages = conv.messages.map((msg) => msg.toJson()).toList();
        
        return {
          'id': conv.id,
          'otherUserId': conv.otherUserId,
          'otherUserType': conv.otherUserType,
          'otherUserName': conv.otherUserName,
          'messages': messages,
          'orderId': conv.orderId,
          'lastUpdated': conv.lastUpdated.toIso8601String(),
          'unreadMessages': conv.unreadMessages,
        };
      }).toList();
      
      final String jsonData = jsonEncode(convData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('driver_conversations', jsonData);
    } catch (e) {
      debugPrint('Error saving conversations: $e');
    }
  }
  
  // Generate mock conversations for testing mode
  List<Conversation> _getMockConversations() {
    final now = DateTime.now();
    
    // Mock farmer conversation
    final farmerConversation = Conversation(
      id: 'conv_farmer_1',
      otherUserId: 'farmer_1',
      otherUserType: 'farmer',
      otherUserName: 'Green Valley Farm',
      orderId: null,
      lastUpdated: now.subtract(const Duration(hours: 2)),
      unreadMessages: true,
      messages: [
        Message(
          id: 'msg_1',
          senderId: 'farmer_1',
          senderType: 'farmer',
          senderName: 'Green Valley Farm',
          recipientId: _userId,
          recipientType: _userType,
          text: 'Hello! We have some fresh produce available this week. Would you like to place an order?',
          timestamp: now.subtract(const Duration(hours: 5)),
          orderId: null,
        ),
        Message(
          id: 'msg_2',
          senderId: _userId,
          senderType: _userType,
          senderName: _userName,
          recipientId: 'farmer_1',
          recipientType: 'farmer',
          text: 'Yes, I\'m interested in ordering some organic vegetables. What do you have available?',
          timestamp: now.subtract(const Duration(hours: 4, minutes: 45)),
          orderId: null,
        ),
        Message(
          id: 'msg_3',
          senderId: 'farmer_1',
          senderType: 'farmer',
          senderName: 'Green Valley Farm',
          recipientId: _userId,
          recipientType: _userType,
          text: 'We have fresh organic kale, tomatoes, carrots, and lettuce. We also have some seasonal berries.',
          timestamp: now.subtract(const Duration(hours: 4, minutes: 30)),
          orderId: null,
        ),
        Message(
          id: 'msg_4',
          senderId: 'farmer_1',
          senderType: 'farmer',
          senderName: 'Green Valley Farm',
          recipientId: _userId,
          recipientType: _userType,
          text: 'Would you like me to put together an assorted basket for you?',
          timestamp: now.subtract(const Duration(hours: 2)),
          orderId: null,
        ),
      ],
    );
    
    // Mock support conversation
    final supportConversation = Conversation(
      id: 'conv_support_1',
      otherUserId: 'support_1',
      otherUserType: 'admin',
      otherUserName: 'FreshFarmily Support',
      orderId: null,
      lastUpdated: now.subtract(const Duration(days: 1, hours: 3)),
      unreadMessages: false,
      messages: [
        Message(
          id: 'msg_5',
          senderId: _userId,
          senderType: _userType,
          senderName: _userName,
          recipientId: 'support_1',
          recipientType: 'admin',
          text: 'Hi, I have a question about my delivery schedule.',
          timestamp: now.subtract(const Duration(days: 1, hours: 6)),
          orderId: null,
        ),
        Message(
          id: 'msg_6',
          senderId: 'support_1',
          senderType: 'admin',
          senderName: 'FreshFarmily Support',
          recipientId: _userId,
          recipientType: _userType,
          text: 'Hello! Thank you for reaching out. How can I help you with your delivery schedule?',
          timestamp: now.subtract(const Duration(days: 1, hours: 5, minutes: 45)),
          orderId: null,
        ),
        Message(
          id: 'msg_7',
          senderId: _userId,
          senderType: _userType,
          senderName: _userName,
          recipientId: 'support_1',
          recipientType: 'admin',
          text: 'I need to change my delivery address for my next order.',
          timestamp: now.subtract(const Duration(days: 1, hours: 5, minutes: 30)),
          orderId: null,
        ),
        Message(
          id: 'msg_8',
          senderId: 'support_1',
          senderType: 'admin',
          senderName: 'FreshFarmily Support',
          recipientId: _userId,
          recipientType: _userType,
          text: 'I can help you with that. You can update your delivery address in your profile settings, or I can update it for you here. Would you like to provide the new address?',
          timestamp: now.subtract(const Duration(days: 1, hours: 5, minutes: 15)),
          orderId: null,
        ),
        Message(
          id: 'msg_9',
          senderId: _userId,
          senderType: _userType,
          senderName: _userName,
          recipientId: 'support_1',
          recipientType: 'admin',
          text: 'Thank you, I was able to update it in my profile. Appreciate the help!',
          timestamp: now.subtract(const Duration(days: 1, hours: 3)),
          orderId: null,
        ),
      ],
    );
    
    // Mock driver conversation
    final driverConversation = Conversation(
      id: 'conv_driver_1',
      otherUserId: 'driver_1',
      otherUserType: 'driver',
      otherUserName: 'John (Delivery Driver)',
      orderId: 'order_123',
      lastUpdated: now.subtract(const Duration(hours: 8)),
      unreadMessages: false,
      messages: [
        Message(
          id: 'msg_10',
          senderId: 'driver_1',
          senderType: 'driver',
          senderName: 'John (Delivery Driver)',
          recipientId: _userId,
          recipientType: _userType,
          text: 'Hi there! I\'m your delivery driver for order #123. I\'ll be delivering your order in about 30 minutes.',
          timestamp: now.subtract(const Duration(hours: 10)),
          orderId: 'order_123',
        ),
        Message(
          id: 'msg_11',
          senderId: _userId,
          senderType: _userType,
          senderName: _userName,
          recipientId: 'driver_1',
          recipientType: 'driver',
          text: 'Great, thank you for letting me know!',
          timestamp: now.subtract(const Duration(hours: 9, minutes: 45)),
          orderId: 'order_123',
        ),
        Message(
          id: 'msg_12',
          senderId: 'driver_1',
          senderType: 'driver',
          senderName: 'John (Delivery Driver)',
          recipientId: _userId,
          recipientType: _userType,
          text: 'I\'ve arrived at your location. I\'ll leave the order at your door as requested.',
          timestamp: now.subtract(const Duration(hours: 9)),
          orderId: 'order_123',
        ),
        Message(
          id: 'msg_13',
          senderId: _userId,
          senderType: _userType,
          senderName: _userName,
          recipientId: 'driver_1',
          recipientType: 'driver',
          text: 'Perfect, thank you so much!',
          timestamp: now.subtract(const Duration(hours: 8, minutes: 55)),
          orderId: 'order_123',
        ),
        Message(
          id: 'msg_14',
          senderId: 'driver_1',
          senderType: 'driver',
          senderName: 'John (Delivery Driver)',
          recipientId: _userId,
          recipientType: _userType,
          text: 'Your order has been delivered. Thank you for using FreshFarmily! Have a great day!',
          timestamp: now.subtract(const Duration(hours: 8)),
          orderId: 'order_123',
        ),
      ],
    );
    
    return [farmerConversation, supportConversation, driverConversation];
  }
}
