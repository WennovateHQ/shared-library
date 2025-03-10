class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final Farm farm;
  final String? imageUrl;
  final String? category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.farm,
    this.imageUrl,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      farm: Farm.fromJson(json['farm']),
      imageUrl: json['imageUrl'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'farm': farm.toJson(),
      'imageUrl': imageUrl,
      'category': category,
    };
  }
}

class Farm {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final double? rating;
  final String? imageUrl;

  Farm({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.rating,
    this.imageUrl,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      rating: json['rating'] != null ? json['rating'].toDouble() : null,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'rating': rating,
      'imageUrl': imageUrl,
    };
  }
}
