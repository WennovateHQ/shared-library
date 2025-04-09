import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final double? unitPrice;
  final double? totalPrice;

  CartItem({
    required this.product,
    required this.quantity,
    this.unitPrice,
    this.totalPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      unitPrice: json['unitPrice']?.toDouble(),
      totalPrice: json['totalPrice']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'unitPrice': unitPrice ?? product.price,
      'totalPrice': totalPrice ?? (product.price * quantity),
    };
  }
}

class Cart {
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double total;

  Cart({
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.total,
  });

  factory Cart.empty() {
    return Cart(
      items: [],
      subtotal: 0.0,
      tax: 0.0,
      deliveryFee: 0.0,
      total: 0.0,
    );
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      subtotal: json['subtotal'].toDouble(),
      tax: json['tax'].toDouble(),
      deliveryFee: json['deliveryFee'].toDouble(),
      total: json['total'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'total': total,
    };
  }

  Cart copyWith({
    List<CartItem>? items,
    double? subtotal,
    double? tax,
    double? deliveryFee,
    double? total,
  }) {
    return Cart(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
    );
  }
}
