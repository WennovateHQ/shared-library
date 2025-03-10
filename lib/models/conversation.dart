import 'message.dart';

class Conversation {
  final String id;
  final String otherUserId;
  final String otherUserType;  // 'farmer', 'consumer', or 'driver'
  final String otherUserName;
  final List<Message> messages;
  final String? orderId;       // Optional: associated order
  final DateTime lastUpdated;
  final bool unreadMessages;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserType,
    required this.otherUserName,
    required this.messages,
    this.orderId,
    required this.lastUpdated,
    this.unreadMessages = false,
  });

  // Create a Conversation from the latest message
  factory Conversation.fromMessage(Message message, String currentUserId) {
    bool isIncoming = message.senderId != currentUserId;
    
    return Conversation(
      id: '${isIncoming ? message.senderId : message.recipientId ?? "unknown"}_${currentUserId}',
      otherUserId: isIncoming ? message.senderId : message.recipientId ?? "unknown",
      otherUserType: isIncoming ? message.senderType : message.recipientType ?? "unknown",
      otherUserName: isIncoming ? message.senderName : "Unknown",
      messages: [message],
      orderId: message.orderId,
      lastUpdated: message.timestamp,
      unreadMessages: isIncoming && !message.isRead,
    );
  }

  // Add a message to the conversation and update the lastUpdated timestamp
  Conversation addMessage(Message message, String currentUserId) {
    final updatedMessages = [...messages, message];
    final isIncoming = message.senderId != currentUserId;
    
    return Conversation(
      id: id,
      otherUserId: otherUserId,
      otherUserType: otherUserType,
      otherUserName: otherUserName,
      messages: updatedMessages,
      orderId: orderId,
      lastUpdated: message.timestamp,
      unreadMessages: unreadMessages || (isIncoming && !message.isRead),
    );
  }

  // Mark all messages as read
  Conversation markAsRead() {
    if (!unreadMessages) return this;
    
    List<Message> updatedMessages = messages.map((message) {
      return Message(
        id: message.id,
        senderId: message.senderId,
        senderType: message.senderType,
        senderName: message.senderName,
        recipientId: message.recipientId,
        recipientType: message.recipientType,
        text: message.text,
        timestamp: message.timestamp,
        isRead: true,
        orderId: message.orderId,
      );
    }).toList();
    
    return Conversation(
      id: id,
      otherUserId: otherUserId,
      otherUserType: otherUserType,
      otherUserName: otherUserName,
      messages: updatedMessages,
      orderId: orderId,
      lastUpdated: lastUpdated,
      unreadMessages: false,
    );
  }
}
