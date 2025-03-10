import 'package:flutter/material.dart';
import '../themes/fresh_theme.dart';

/// A settings list tile component based on Pro-Grocery UI kit
/// Used for displaying settings options with various types of interactions
class SettingsTile extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final Color? iconColor;
  final bool showDivider;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  
  const SettingsTile({
    Key? key,
    required this.label,
    this.trailing,
    this.onTap,
    this.leadingIcon,
    this.iconColor,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: FreshTheme.padding,
      vertical: FreshTheme.padding * 0.8,
    ),
    this.backgroundColor,
    this.borderRadius,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: borderRadius ?? FreshTheme.borderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius ?? FreshTheme.borderRadius,
            child: Padding(
              padding: padding,
              child: Row(
                children: [
                  // Leading icon
                  if (leadingIcon != null) ...[
                    Icon(
                      leadingIcon,
                      color: iconColor ?? theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  // Label
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  // Trailing widget
                  if (trailing != null)
                    trailing!
                  else if (onTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: FreshTheme.placeholder,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1),
      ],
    );
  }
}

/// A settings toggle tile that includes a switch
class SettingsToggleTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? leadingIcon;
  final Color? iconColor;
  final bool showDivider;
  final String? subtitle;
  
  const SettingsToggleTile({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.leadingIcon,
    this.iconColor,
    this.showDivider = true,
    this.subtitle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SettingsTile(
      label: label,
      leadingIcon: leadingIcon,
      iconColor: iconColor,
      showDivider: showDivider,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
      ),
      onTap: () => onChanged(!value),
    );
  }
}

/// A settings radio tile that includes a radio button
class SettingsRadioTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final IconData? leadingIcon;
  final Color? iconColor;
  final bool showDivider;
  
  const SettingsRadioTile({
    Key? key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.leadingIcon,
    this.iconColor,
    this.showDivider = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      label: label,
      leadingIcon: leadingIcon,
      iconColor: iconColor,
      showDivider: showDivider,
      trailing: Radio<T>(
        value: value,
        groupValue: groupValue,
        onChanged: (T? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
      onTap: () => onChanged(value),
    );
  }
}
