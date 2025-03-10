import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';
import '../themes/fresh_theme.dart';
import 'network_image.dart';

/// An onboarding view component based on Pro-Grocery UI kit
/// Used to display individual onboarding slides
class OnboardingView extends StatelessWidget {
  final OnboardingModel data;
  final EdgeInsetsGeometry imagePadding;
  final TextStyle? headlineStyle;
  final TextStyle? descriptionStyle;
  final EdgeInsetsGeometry contentPadding;
  
  const OnboardingView({
    Key? key,
    required this.data,
    this.imagePadding = const EdgeInsets.all(32.0),
    this.headlineStyle,
    this.descriptionStyle,
    this.contentPadding = const EdgeInsets.all(16.0),
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image or Icon
        SizedBox(
          width: screenWidth,
          height: screenWidth * 0.8,
          child: Padding(
            padding: imagePadding,
            child: data.imageUrl != null
                ? NetworkImageWithLoader(
                    imageUrl: data.imageUrl!,
                    fit: BoxFit.contain,
                    placeholder: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : data.placeholderIcon != null
                    ? Center(
                        child: Icon(
                          data.placeholderIcon,
                          size: 120,
                          color: theme.primaryColor,
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
          ),
        ),
        
        // Content
        Padding(
          padding: contentPadding,
          child: Column(
            children: [
              // Headline
              Text(
                data.headline,
                textAlign: TextAlign.center,
                style: headlineStyle ?? 
                  theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              ),
              
              // Description
              Padding(
                padding: const EdgeInsets.all(FreshTheme.padding),
                child: Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: descriptionStyle ?? 
                    theme.textTheme.bodyMedium?.copyWith(
                      color: FreshTheme.textSecondary,
                    ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
