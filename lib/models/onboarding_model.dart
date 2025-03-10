import 'dart:convert';
import 'package:flutter/material.dart';

/// Model class for onboarding screen data
class OnboardingModel {
  final String? imageUrl;
  final String headline;
  final String description;
  final IconData? placeholderIcon;
  
  OnboardingModel({
    this.imageUrl,
    required this.headline,
    required this.description,
    this.placeholderIcon,
  }) : assert(imageUrl != null || placeholderIcon != null, 'Either imageUrl or placeholderIcon must be provided');

  OnboardingModel copyWith({
    String? imageUrl,
    String? headline,
    String? description,
    IconData? placeholderIcon,
  }) {
    return OnboardingModel(
      imageUrl: imageUrl ?? this.imageUrl,
      headline: headline ?? this.headline,
      description: description ?? this.description,
      placeholderIcon: placeholderIcon ?? this.placeholderIcon,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'headline': headline,
      'description': description,
      // Note: IconData can't be easily serialized, so we exclude it
    };
  }

  factory OnboardingModel.fromMap(Map<String, dynamic> map) {
    return OnboardingModel(
      imageUrl: map['imageUrl'],
      headline: map['headline'] ?? '',
      description: map['description'] ?? '',
      placeholderIcon: null, // Can't deserialize IconData easily
    );
  }

  String toJson() => json.encode(toMap());

  factory OnboardingModel.fromJson(String source) =>
      OnboardingModel.fromMap(json.decode(source));

  @override
  String toString() =>
      'OnboardingModel(imageUrl: $imageUrl, headline: $headline, description: $description, hasPlaceholderIcon: ${placeholderIcon != null})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is OnboardingModel &&
      other.imageUrl == imageUrl &&
      other.headline == headline &&
      other.description == description;
  }

  @override
  int get hashCode => imageUrl.hashCode ^ headline.hashCode ^ description.hashCode;
}
