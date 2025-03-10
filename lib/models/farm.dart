class Farm {
  final String id;
  final String name;
  final String location;
  final String established;
  final List<String> certifications;
  final List<String> products;
  final String description;
  final String image;
  final List<Map<String, dynamic>> reviews;
  final int followers;

  Farm({
    required this.id,
    required this.name,
    required this.location,
    required this.established,
    required this.certifications,
    required this.products,
    required this.description,
    required this.image,
    required this.reviews,
    required this.followers,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      established: json['established'],
      certifications: List<String>.from(json['certifications']),
      products: List<String>.from(json['products']),
      description: json['description'],
      image: json['image'],
      reviews: List<Map<String, dynamic>>.from(json['reviews']),
      followers: json['followers'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'established': established,
      'certifications': certifications,
      'products': products,
      'description': description,
      'image': image,
      'reviews': reviews,
      'followers': followers,
    };
  }
}
