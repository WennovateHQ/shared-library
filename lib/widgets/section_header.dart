import 'package:flutter/material.dart';
import '../themes/fresh_theme.dart';

/// A section header widget based on Pro-Grocery UI kit design
/// Used to display a section title with an optional action button
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final IconData? actionIcon;
  final bool showDivider;
  final EdgeInsetsGeometry padding;
  
  const SectionHeader({
    Key? key,
    required this.title,
    this.actionText,
    this.onActionPressed,
    this.actionIcon,
    this.showDivider = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: FreshTheme.padding, 
      vertical: FreshTheme.padding / 2,
    ),
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider)
          const Divider(height: 1),
        Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Section title
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              
              // Action button (if provided)
              if (actionText != null || actionIcon != null)
                GestureDetector(
                  onTap: onActionPressed,
                  child: Row(
                    children: [
                      if (actionText != null)
                        Text(
                          actionText!,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      if (actionIcon != null && actionText != null)
                        const SizedBox(width: 4),
                      if (actionIcon != null)
                        Icon(
                          actionIcon,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1),
      ],
    );
  }
}
