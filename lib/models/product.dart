class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stock;
  final int lowStockThreshold;
  final String? imageUrl;
  final bool isOrganic;
  final bool isAvailable;
  final String unit;
  final double popularity;
  final List<String>? tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? farmId;
  final String? farmName;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    required this.lowStockThreshold,
    this.imageUrl,
    required this.isOrganic,
    required this.isAvailable,
    required this.unit,
    required this.popularity,
    this.tags,
    this.createdAt,
    this.updatedAt,
    this.farmId,
    this.farmName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : json['price']?.toDouble() ?? 0.0,
      stock: json['stock'] ?? 0,
      lowStockThreshold: json['lowStockThreshold'] ?? 10,
      imageUrl: json['imageUrl'],
      isOrganic: json['isOrganic'] ?? false,
      isAvailable: json['isAvailable'] ?? true,
      unit: json['unit'] ?? 'item',
      popularity: (json['popularity'] is int)
          ? (json['popularity'] as int).toDouble()
          : json['popularity']?.toDouble() ?? 0.0,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      farmId: json['farmId'],
      farmName: json['farmName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
      'imageUrl': imageUrl,
      'isOrganic': isOrganic,
      'isAvailable': isAvailable,
      'unit': unit,
      'popularity': popularity,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'farmId': farmId,
      'farmName': farmName,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    int? stock,
    int? lowStockThreshold,
    String? imageUrl,
    bool? isOrganic,
    bool? isAvailable,
    String? unit,
    double? popularity,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? farmId,
    String? farmName,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      imageUrl: imageUrl ?? this.imageUrl,
      isOrganic: isOrganic ?? this.isOrganic,
      isAvailable: isAvailable ?? this.isAvailable,
      unit: unit ?? this.unit,
      popularity: popularity ?? this.popularity,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
    );
  }
}
