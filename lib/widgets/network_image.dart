import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../themes/fresh_theme.dart';

/// A component for loading network images with a placeholder and error handler
/// Based on the Pro-Grocery UI kit design
class NetworkImageWithLoader extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double radius;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const NetworkImageWithLoader({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.radius = FreshTheme.radius,
    this.borderRadius,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);
  
  /// Helper method to check if a URL is a network URL or local asset
  bool _isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      child: _isNetworkUrl(imageUrl) 
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: fit,
              width: width,
              height: height,
              placeholder: (context, url) => placeholder ?? const Skeleton(),
              errorWidget: (context, url, error) => errorWidget ??
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image_outlined,
                        color: FreshTheme.placeholder,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image load error',
                        style: TextStyle(
                          color: FreshTheme.placeholder,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            )
          : Image.asset(
              imageUrl,
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (context, error, stackTrace) => errorWidget ??
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image_outlined,
                        color: FreshTheme.placeholder,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Asset not found',
                        style: TextStyle(
                          color: FreshTheme.placeholder,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) {
                  return child;
                }
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: frame == null ? placeholder ?? const Skeleton() : child,
                );
              },
            ),
    );
  }
}

/// A skeleton loading placeholder
class Skeleton extends StatelessWidget {
  final double? height;
  final double? width;
  final int layer;
  final BorderRadius? borderRadius;
  final Color? color;
  
  const Skeleton({
    Key? key,
    this.height,
    this.width,
    this.layer = 1,
    this.borderRadius,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.all(FreshTheme.padding / 2),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withOpacity(0.04 * layer),
        borderRadius: borderRadius ?? 
          BorderRadius.circular(FreshTheme.radius),
      ),
    );
  }
}

/// A circular skeleton loading placeholder
class CircleSkeleton extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const CircleSkeleton({
    Key? key,
    this.size = 24,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.primary.withOpacity(0.04),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A shimmer loading effect that can be applied to any widget
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  
  const ShimmerLoading({
    Key? key,
    required this.child,
    this.baseColor = const Color(0xFFEEEEEE),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);
  
  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _colorAnimation = ColorTween(
      begin: widget.baseColor,
      end: widget.highlightColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
    ));
    
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: _colorAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}
