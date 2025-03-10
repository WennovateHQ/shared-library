import 'package:flutter/material.dart';
import '../themes/fresh_theme.dart';

enum FreshButtonType {
  primary,
  secondary,
  outline,
  text,
}

enum FreshButtonSize {
  small,
  medium,
  large,
}

/// A customized button based on Pro-Grocery UI kit design
class FreshButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final FreshButtonType type;
  final FreshButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double? height;
  final Color? customColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  
  const FreshButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = FreshButtonType.primary,
    this.size = FreshButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height,
    this.customColor,
    this.borderRadius = FreshTheme.radius,
    this.padding,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = customColor ?? theme.colorScheme.primary;
    
    // Determine button style based on type
    ButtonStyle buttonStyle;
    switch (type) {
      case FreshButtonType.primary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
        break;
      case FreshButtonType.secondary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: primaryColor.withOpacity(0.1),
          foregroundColor: primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
        break;
      case FreshButtonType.outline:
        buttonStyle = OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
        break;
      case FreshButtonType.text:
        buttonStyle = TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
        break;
    }
    
    // Determine button padding based on size
    final EdgeInsetsGeometry buttonPadding = padding ?? _getPaddingBySize();
    
    // Determine text style based on size
    final TextStyle textStyle = _getTextStyleBySize(context);
    
    // Build the button content
    Widget buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == FreshButtonType.primary
                    ? Colors.white
                    : primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ] else ...[
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: _getIconSizeByButtonSize()),
            const SizedBox(width: 8),
          ],
        ],
        Text(
          text,
          style: textStyle,
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: _getIconSizeByButtonSize()),
        ],
      ],
    );
    
    // Build the button with correct type
    Widget button;
    switch (type) {
      case FreshButtonType.primary:
      case FreshButtonType.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: Padding(
            padding: buttonPadding,
            child: buttonContent,
          ),
        );
        break;
      case FreshButtonType.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: Padding(
            padding: buttonPadding,
            child: buttonContent,
          ),
        );
        break;
      case FreshButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: Padding(
            padding: buttonPadding,
            child: buttonContent,
          ),
        );
        break;
    }
    
    // Apply custom dimensions if provided
    if (width != null || height != null || isFullWidth) {
      return SizedBox(
        width: isFullWidth ? double.infinity : width,
        height: height,
        child: button,
      );
    }
    
    return button;
  }
  
  EdgeInsetsGeometry _getPaddingBySize() {
    switch (size) {
      case FreshButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: FreshTheme.padding / 2,
          vertical: FreshTheme.padding / 3,
        );
      case FreshButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: FreshTheme.padding,
          vertical: FreshTheme.padding / 2,
        );
      case FreshButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: FreshTheme.padding * 1.5,
          vertical: FreshTheme.padding,
        );
    }
  }
  
  TextStyle _getTextStyleBySize(BuildContext context) {
    final baseStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: type == FreshButtonType.primary
          ? Colors.white
          : customColor ?? Theme.of(context).colorScheme.primary,
    );
    
    switch (size) {
      case FreshButtonSize.small:
        return baseStyle.copyWith(fontSize: 12);
      case FreshButtonSize.medium:
        return baseStyle.copyWith(fontSize: 14);
      case FreshButtonSize.large:
        return baseStyle.copyWith(fontSize: 16);
    }
  }
  
  double _getIconSizeByButtonSize() {
    switch (size) {
      case FreshButtonSize.small:
        return 16;
      case FreshButtonSize.medium:
        return 20;
      case FreshButtonSize.large:
        return 24;
    }
  }
}
