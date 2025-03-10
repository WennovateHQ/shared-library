import 'package:flutter/material.dart';
import '../themes/fresh_theme.dart';

/// A search bar widget based on Pro-Grocery UI kit design
class FreshSearchBar extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool showLeadingIcon;
  final Widget? suffix;
  final FocusNode? focusNode;
  final String? initialValue;
  final bool readOnly;
  final VoidCallback? onTap;
  
  const FreshSearchBar({
    Key? key,
    this.hintText = 'Search',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.backgroundColor,
    this.borderRadius,
    this.margin,
    this.padding,
    this.showLeadingIcon = true,
    this.suffix,
    this.focusNode,
    this.initialValue,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);
  
  @override
  State<FreshSearchBar> createState() => _FreshSearchBarState();
}

class _FreshSearchBarState extends State<FreshSearchBar> {
  late TextEditingController _controller;
  bool _showClearButton = false;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _showClearButton = _controller.text.isNotEmpty;
    
    _controller.addListener(() {
      final shouldShowClear = _controller.text.isNotEmpty;
      if (_showClearButton != shouldShowClear) {
        setState(() {
          _showClearButton = shouldShowClear;
        });
      }
    });
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
  
  void _clearSearch() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? FreshTheme.textInputBackground,
        borderRadius: widget.borderRadius ?? FreshTheme.borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            color: FreshTheme.placeholder,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: widget.padding ?? 
            const EdgeInsets.symmetric(
              horizontal: FreshTheme.padding,
              vertical: FreshTheme.padding,
            ),
          prefixIcon: widget.showLeadingIcon 
              ? const Icon(Icons.search, color: FreshTheme.placeholder)
              : null,
          suffixIcon: _showClearButton
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: _clearSearch,
                  color: FreshTheme.placeholder,
                )
              : widget.suffix,
          filled: true,
          fillColor: Colors.transparent,
        ),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        textAlignVertical: TextAlignVertical.center,
        cursorColor: theme.colorScheme.primary,
      ),
    );
  }
}
