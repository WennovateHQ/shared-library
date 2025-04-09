import 'address.dart';

/// Model class representing a user in the FreshFarmily system
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String role;
  final String? profileImageUrl;
  final bool isEmailVerified;
  final List<Address>? addresses;
  final Map<String, dynamic>? settings;
  final Map<String, bool>? notificationPreferences;
  final List<String> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
    this.profileImageUrl,
    required this.isEmailVerified,
    this.addresses,
    this.settings,
    this.notificationPreferences,
    required this.permissions,
    this.createdAt,
    this.updatedAt,
  });

  /// Get the full name of the user
  String get fullName => '$firstName $lastName'.trim();

  /// Check if the user has a specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  /// Factory constructor to create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    // Parse addresses if present
    List<Address>? addressList;
    if (json['addresses'] != null) {
      addressList = (json['addresses'] as List)
          .map((addr) => Address.fromJson(addr))
          .toList();
    }

    // Parse notification preferences if present
    Map<String, bool>? notifPrefs;
    if (json['notificationPreferences'] != null) {
      notifPrefs = Map<String, bool>.from(json['notificationPreferences']);
    }

    // Parse permissions
    List<String> perms = [];
    if (json['permissions'] != null) {
      perms = List<String>.from(json['permissions']);
    } else {
      // If permissions not provided, assign based on role
      switch (json['role']) {
        case 'admin':
          perms = ['read', 'write', 'update', 'delete', 'admin'];
          break;
        case 'farmer':
          perms = ['read', 'write', 'update', 'delete_own'];
          break;
        case 'driver':
          perms = ['read', 'update_delivery'];
          break;
        case 'consumer':
          perms = ['read', 'create_order'];
          break;
        default:
          perms = ['read'];
      }
    }

    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'] ?? json['phoneNumber'], // Handle both formats
      role: json['role'],
      profileImageUrl: json['profileImageUrl'] ?? json['profileImage'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      addresses: addressList,
      settings: json['settings'],
      notificationPreferences: notifPrefs,
      permissions: perms,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  /// Convert the User to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'isEmailVerified': isEmailVerified,
      'addresses': addresses?.map((addr) => addr.toJson()).toList(),
      'settings': settings,
      'notificationPreferences': notificationPreferences,
      'permissions': permissions,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of this User with modified properties
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? role,
    String? profileImageUrl,
    bool? isEmailVerified,
    List<Address>? addresses,
    Map<String, dynamic>? settings,
    Map<String, bool>? notificationPreferences,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      addresses: addresses ?? this.addresses,
      settings: settings ?? this.settings,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  @override
  String toString() {
    return 'User{id: $id, name: $fullName, email: $email, role: $role}';
  }
}
