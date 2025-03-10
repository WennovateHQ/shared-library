import 'product.dart';
import 'user.dart';

class Order {
  final String id;
  final List<OrderItem> items;
  final String deliveryAddress;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final User consumer;
  final String? driverId;
  final String? trackingUrl;

  Order({
    required this.id,
    required this.items,
    required this.deliveryAddress,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.consumer,
    this.driverId,
    this.trackingUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      items: (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList(),
      deliveryAddress: json['deliveryAddress'],
      status: json['status'],
      totalAmount: json['totalAmount'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      consumer: User.fromJson(json['consumer']),
      driverId: json['driverId'],
      trackingUrl: json['trackingUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'deliveryAddress': deliveryAddress,
      'status': status,
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'consumer': consumer.toJson(),
      'driverId': driverId,
      'trackingUrl': trackingUrl,
    };
  }
}

class OrderItem {
  final String id;
  final Product product;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      price: json['price'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'price': price,
    };
  }
}
