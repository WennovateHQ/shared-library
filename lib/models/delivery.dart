class Delivery {
  final String id;
  final String orderId;
  final String farmId;
  final String farmName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String status;
  
  // Pickup location details
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  
  // Dropoff location details
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String dropoffAddress;
  
  // Time constraints
  final List<TimeWindow>? timeWindows;
  
  // Delivery information
  final DateTime scheduledTime;
  final DateTime? actualDeliveryTime;
  final String? notes;
  final int? priority; // Higher number means higher priority
  final double? weight; // In kg
  final double? volume; // In cubic meters
  final List<DeliveryItem>? items;
  final String? signature;
  final List<String>? photos;
  
  // Driver info
  final String? driverId;
  final String? driverName;
  
  // Payment info
  final double amount;
  final bool isPaid;
  final String paymentMethod;
  
  Delivery({
    required this.id,
    required this.orderId,
    required this.farmId,
    required this.farmName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.dropoffAddress,
    this.timeWindows,
    required this.scheduledTime,
    this.actualDeliveryTime,
    this.notes,
    this.priority,
    this.weight,
    this.volume,
    this.items,
    this.signature,
    this.photos,
    this.driverId,
    this.driverName,
    required this.amount,
    required this.isPaid,
    required this.paymentMethod,
  });
  
  factory Delivery.fromJson(Map<String, dynamic> json) {
    List<TimeWindow>? timeWindows;
    if (json['timeWindows'] != null) {
      timeWindows = (json['timeWindows'] as List)
          .map((window) => TimeWindow.fromJson(window))
          .toList();
    }
    
    List<DeliveryItem>? items;
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((item) => DeliveryItem.fromJson(item))
          .toList();
    }
    
    return Delivery(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      farmId: json['farmId'] ?? '',
      farmName: json['farmName'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      status: json['status'] ?? 'pending',
      pickupLatitude: json['pickupLatitude']?.toDouble() ?? 0.0,
      pickupLongitude: json['pickupLongitude']?.toDouble() ?? 0.0,
      pickupAddress: json['pickupAddress'] ?? '',
      dropoffLatitude: json['dropoffLatitude']?.toDouble() ?? 0.0,
      dropoffLongitude: json['dropoffLongitude']?.toDouble() ?? 0.0,
      dropoffAddress: json['dropoffAddress'] ?? '',
      timeWindows: timeWindows,
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'])
          : DateTime.now(),
      actualDeliveryTime: json['actualDeliveryTime'] != null
          ? DateTime.parse(json['actualDeliveryTime'])
          : null,
      notes: json['notes'],
      priority: json['priority'],
      weight: json['weight']?.toDouble(),
      volume: json['volume']?.toDouble(),
      items: items,
      signature: json['signature'],
      photos: json['photos'] != null ? List<String>.from(json['photos']) : null,
      driverId: json['driverId'],
      driverName: json['driverName'],
      amount: json['amount']?.toDouble() ?? 0.0,
      isPaid: json['isPaid'] ?? false,
      paymentMethod: json['paymentMethod'] ?? 'card',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'farmId': farmId,
      'farmName': farmName,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'status': status,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'pickupAddress': pickupAddress,
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      'dropoffAddress': dropoffAddress,
      'timeWindows': timeWindows?.map((window) => window.toJson()).toList(),
      'scheduledTime': scheduledTime.toIso8601String(),
      'actualDeliveryTime': actualDeliveryTime?.toIso8601String(),
      'notes': notes,
      'priority': priority,
      'weight': weight,
      'volume': volume,
      'items': items?.map((item) => item.toJson()).toList(),
      'signature': signature,
      'photos': photos,
      'driverId': driverId,
      'driverName': driverName,
      'amount': amount,
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
    };
  }
  
  Delivery copyWith({
    String? id,
    String? orderId,
    String? farmId,
    String? farmName,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? status,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupAddress,
    double? dropoffLatitude,
    double? dropoffLongitude,
    String? dropoffAddress,
    List<TimeWindow>? timeWindows,
    DateTime? scheduledTime,
    DateTime? actualDeliveryTime,
    String? notes,
    int? priority,
    double? weight,
    double? volume,
    List<DeliveryItem>? items,
    String? signature,
    List<String>? photos,
    String? driverId,
    String? driverName,
    double? amount,
    bool? isPaid,
    String? paymentMethod,
  }) {
    return Delivery(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      status: status ?? this.status,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      timeWindows: timeWindows ?? this.timeWindows,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      weight: weight ?? this.weight,
      volume: volume ?? this.volume,
      items: items ?? this.items,
      signature: signature ?? this.signature,
      photos: photos ?? this.photos,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class TimeWindow {
  final DateTime start;
  final DateTime end;
  
  TimeWindow({
    required this.start,
    required this.end,
  });
  
  factory TimeWindow.fromJson(Map<String, dynamic> json) {
    return TimeWindow(
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }
}

class DeliveryItem {
  final String id;
  final String productId;
  final String name;
  final int quantity;
  final double price;
  
  DeliveryItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });
  
  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price']?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}
