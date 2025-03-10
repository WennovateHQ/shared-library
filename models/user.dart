class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final Map<String, dynamic>? profile;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      profile: json['profile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'profile': profile,
    };
  }
}
