import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A customized AppBar based on the Pro-Grocery UI kit design
class FreshAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final String? logoAsset;
  final bool useLogoInsteadOfTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool implyLeading;
  final PreferredSizeWidget? bottom;

  const FreshAppBar({
    Key? key,
    required this.title,
    this.centerTitle = true,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.logoAsset,
    this.useLogoInsteadOfTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0.3,
    this.implyLeading = true,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: elevation,
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor,
      centerTitle: centerTitle,
      automaticallyImplyLeading: implyLeading,
      bottom: bottom,
      leading: _buildLeading(context),
      title: _buildTitle(context),
      actions: actions,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading;
    }

    if (showBackButton && Navigator.of(context).canPop()) {
      return IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      );
    }

    return null;
  }

  Widget _buildTitle(BuildContext context) {
    if (useLogoInsteadOfTitle && logoAsset != null) {
      if (logoAsset!.endsWith('.svg')) {
        return SvgPicture.asset(
          logoAsset!,
          height: 32,
        );
      } else {
        return Image.asset(
          logoAsset!,
          height: 32,
        );
      }
    }

    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
