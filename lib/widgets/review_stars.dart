import 'package:flutter/material.dart';
import '../themes/fresh_theme.dart';

/// A review stars component based on Pro-Grocery UI kit
/// Used to display ratings for products, farms, etc.
class ReviewStars extends StatelessWidget {
  final double rating;
  final int totalStars;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showRatingText;
  final TextStyle? ratingTextStyle;
  final MainAxisAlignment alignment;
  final bool showEmptyStars;
  final EdgeInsetsGeometry? padding;
  
  const ReviewStars({
    Key? key,
    required this.rating,
    this.totalStars = 5,
    this.size = 16,
    this.activeColor,
    this.inactiveColor,
    this.showRatingText = false,
    this.ratingTextStyle,
    this.alignment = MainAxisAlignment.start,
    this.showEmptyStars = true,
    this.padding,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starActiveColor = activeColor ?? Colors.amber;
    final starInactiveColor = inactiveColor ?? FreshTheme.placeholder.withOpacity(0.3);
    
    // Ensure the rating is not greater than the total stars
    final validRating = rating > totalStars ? totalStars.toDouble() : rating;
    
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: alignment,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalStars, (index) {
              return _buildStar(
                index: index,
                rating: validRating,
                activeColor: starActiveColor,
                inactiveColor: starInactiveColor,
              );
            }),
          ),
          if (showRatingText) ...[
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: ratingTextStyle ?? 
                TextStyle(
                  fontSize: size * 0.9,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStar({
    required int index,
    required double rating,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    // Full star
    if (index < rating.floor()) {
      return Icon(
        Icons.star,
        color: activeColor,
        size: size,
      );
    }
    // Partial star
    else if (index == rating.floor() && rating % 1 != 0) {
      final percent = rating % 1;
      
      return SizedBox(
        height: size,
        width: size,
        child: Stack(
          children: [
            Icon(
              Icons.star,
              color: inactiveColor,
              size: size,
            ),
            ClipRect(
              clipper: _StarClipper(width: size * percent),
              child: Icon(
                Icons.star,
                color: activeColor,
                size: size,
              ),
            ),
          ],
        ),
      );
    }
    // Empty star
    else {
      return Icon(
        showEmptyStars ? Icons.star : Icons.star_border,
        color: inactiveColor,
        size: size,
      );
    }
  }
}

/// Used to clip stars for partial ratings
class _StarClipper extends CustomClipper<Rect> {
  final double width;
  
  _StarClipper({required this.width});
  
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, width, size.height);
  }
  
  @override
  bool shouldReclip(_StarClipper oldClipper) => width != oldClipper.width;
}

/// Interactive star rating widget for user input
class InteractiveStarRating extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final int totalStars;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool allowHalfRating;
  final bool showRatingText;
  final TextStyle? ratingTextStyle;
  
  const InteractiveStarRating({
    Key? key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.totalStars = 5,
    this.size = 32,
    this.activeColor,
    this.inactiveColor,
    this.allowHalfRating = true,
    this.showRatingText = true,
    this.ratingTextStyle,
  }) : super(key: key);
  
  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late double _rating;
  
  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 4,
          children: List.generate(widget.totalStars, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _rating = index + 1.0;
                  widget.onRatingChanged(_rating);
                });
              },
              onHorizontalDragUpdate: widget.allowHalfRating
                  ? (details) {
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      final localPosition = box.globalToLocal(details.globalPosition);
                      final starWidth = box.size.width / widget.totalStars;
                      final starIndex = (localPosition.dx / starWidth).floor();
                      
                      // Calculate the position within the star for half ratings
                      final starPosition = localPosition.dx - (starIndex * starWidth);
                      final percent = starPosition / starWidth;
                      
                      double newRating;
                      if (percent < 0.5) {
                        newRating = starIndex + 0.5;
                      } else {
                        newRating = starIndex + 1.0;
                      }
                      
                      newRating = newRating.clamp(0.5, widget.totalStars.toDouble());
                      
                      if (_rating != newRating) {
                        setState(() {
                          _rating = newRating;
                          widget.onRatingChanged(_rating);
                        });
                      }
                    }
                  : null,
              child: Icon(
                index < _rating.floor()
                    ? Icons.star
                    : (index == _rating.floor() && _rating % 1 != 0)
                        ? Icons.star_half
                        : Icons.star_border,
                color: index < _rating
                    ? (widget.activeColor ?? Colors.amber)
                    : (index == _rating.floor() && _rating % 1 != 0)
                        ? (widget.activeColor ?? Colors.amber)
                        : (widget.inactiveColor ?? FreshTheme.placeholder),
                size: widget.size,
              ),
            );
          }),
        ),
        if (widget.showRatingText) ...[
          const SizedBox(width: 8),
          Text(
            _rating.toStringAsFixed(1),
            style: widget.ratingTextStyle ??
                TextStyle(
                  fontSize: widget.size * 0.6,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ],
    );
  }
}
