class PaymentMethod {
  final String id;
  final String type; // credit_card, bank_account, etc.
  final String displayName;
  final bool isDefault;
  final Map<String, dynamic> details;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.displayName,
    this.isDefault = false,
    required this.details,
  });

  // Used for displaying the icon in UI
  String get brand {
    if (type == 'credit_card') {
      return details['brand'] ?? 'unknown';
    }
    return type;
  }

  // Mask sensitive information for display
  String get maskedNumber {
    if (type == 'credit_card' && details.containsKey('last4')) {
      return '•••• ${details['last4']}';
    } else if (type == 'bank_account' && details.containsKey('last4')) {
      return '•••• ${details['last4']}';
    }
    return '';
  }

  // Factory constructor to create a PaymentMethod from JSON
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      type: json['type'],
      displayName: json['display_name'] ?? 'Payment Method',
      isDefault: json['is_default'] ?? false,
      details: json['details'] ?? {},
    );
  }

  // Convert the PaymentMethod to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'display_name': displayName,
      'is_default': isDefault,
      'details': details,
    };
  }
}

class PaymentTransaction {
  final String id;
  final String orderId;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final String? paymentMethodId;
  final Map<String, dynamic>? metadata;

  PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.paymentMethodId,
    this.metadata,
  });

  // Format the amount with currency symbol
  String formattedAmount() {
    String symbol = currency.toUpperCase() == 'USD' ? '\$' : currency;
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  // Factory constructor to create a PaymentTransaction from JSON
  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'],
      orderId: json['order_id'],
      amount: double.parse(json['amount'].toString()),
      currency: json['currency'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      paymentMethodId: json['payment_method_id'],
      metadata: json['metadata'],
    );
  }

  // Convert the PaymentTransaction to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'payment_method_id': paymentMethodId,
      'metadata': metadata,
    };
  }
}

class PaymentIntent {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String clientSecret;
  final Map<String, dynamic>? metadata;

  PaymentIntent({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.clientSecret,
    this.metadata,
  });

  // Factory constructor to create a PaymentIntent from JSON
  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      currency: json['currency'],
      status: json['status'],
      clientSecret: json['client_secret'],
      metadata: json['metadata'],
    );
  }

  // Convert the PaymentIntent to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'status': status,
      'client_secret': clientSecret,
      'metadata': metadata,
    };
  }
}
