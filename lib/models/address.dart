class Address {
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? apartmentNumber;
  final String? instructions;
  final double? latitude;
  final double? longitude;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.apartmentNumber,
    this.instructions,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postalCode'],
      country: json['country'],
      apartmentNumber: json['apartmentNumber'],
      instructions: json['instructions'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'apartmentNumber': apartmentNumber,
      'instructions': instructions,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get formattedAddress {
    String formatted = street;
    if (apartmentNumber != null && apartmentNumber!.isNotEmpty) {
      formatted += ', Apt ${apartmentNumber!}';
    }
    formatted += '\n$city, $state $postalCode\n$country';
    return formatted;
  }
}
