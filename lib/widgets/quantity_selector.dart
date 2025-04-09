import 'package:flutter/material.dart';
import '../themes/fresh_theme.dart';

/// A quantity selector component based on Pro-Grocery UI kit
/// Used for selecting product quantities in the shopping cart or product details
class QuantitySelector extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;
  final bool showLabel;
  final String? labelText;
  final bool compact;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  
  const QuantitySelector({
    Key? key,
    required this.value,
    this.minValue = 1,
    this.maxValue = 99,
    required this.onChanged,
    this.showLabel = false,
    this.labelText,
    this.compact = false,
    this.decoration,
    this.padding,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    final defaultDecoration = BoxDecoration(
      color: backgroundColor ?? FreshTheme.textInputBackground,
      borderRadius: BorderRadius.circular(compact ? 8 : FreshTheme.radius),
      border: Border.all(
        color: FreshTheme.gray.withAlpha(128), // 0.5 * 255 = 128
        width: 1,
      ),
    );
    
    final buttonSize = compact ? 28.0 : 36.0;
    final fontSize = compact ? 14.0 : 16.0;
    final iconSize = compact ? 16.0 : 20.0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel && labelText != null) ...[
          Text(
            labelText!,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: textColor ?? FreshTheme.placeholder,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          decoration: decoration ?? defaultDecoration,
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrease button
              _buildButton(
                onPressed: value > minValue
                    ? () => onChanged(value - 1)
                    : null,
                icon: Icons.remove,
                size: buttonSize,
                iconSize: iconSize,
                iconColor: iconColor ?? primaryColor,
                isEnabled: value > minValue,
              ),
              
              // Quantity display
              SizedBox(
                width: compact ? 32 : 40,
                child: Center(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: textColor ?? Colors.black,
                    ),
                  ),
                ),
              ),
              
              // Increase button
              _buildButton(
                onPressed: value < maxValue
                    ? () => onChanged(value + 1)
                    : null,
                icon: Icons.add,
                size: buttonSize,
                iconSize: iconSize,
                iconColor: iconColor ?? primaryColor,
                isEnabled: value < maxValue,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required double size,
    required double iconSize,
    required Color iconColor,
    required bool isEnabled,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Icon(
            icon,
            size: iconSize,
            color: isEnabled
                ? iconColor
                : FreshTheme.placeholder.withAlpha(77), // 0.3 * 255 ≈ 77
          ),
        ),
      ),
    );
  }
}
