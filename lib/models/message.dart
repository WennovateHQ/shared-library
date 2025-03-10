class Message {
  final String id;
  final String senderId;
  final String senderType; // 'farmer', 'driver', or 'consumer'
  final String senderName;
  final String? recipientId;
  final String? recipientType;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String? orderId; // Optional: associated order

  Message({
    required this.id,
    required this.senderId,
    required this.senderType,
    required this.senderName,
    this.recipientId,
    this.recipientType,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.orderId,
  });

  // Create a Message from a WebSocket/JSON data
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: json['sender_id'] ?? '',
      senderType: json['sender_type'] ?? '',
      senderName: json['sender_name'] ?? 'Unknown',
      recipientId: json['recipient_id'],
      recipientType: json['recipient_type'],
      text: json['message'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      orderId: json['order_id'],
    );
  }

  // Convert Message to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_type': senderType,
      'sender_name': senderName,
      'recipient_id': recipientId,
      'recipient_type': recipientType,
      'message': text,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'order_id': orderId,
    };
  }
}
