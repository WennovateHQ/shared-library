import 'package:flutter/material.dart';

/// A dotted divider component based on Pro-Grocery UI kit
/// Can be used to create visual separators with a dotted pattern
class DottedDivider extends StatelessWidget {
  final bool isVertical;
  final Color? color;
  final int dashCount;
  final double dashWidth;
  final double dashHeight;
  final double dashSpacing;
  
  const DottedDivider({
    Key? key,
    this.isVertical = false,
    this.color,
    this.dashCount = 30,
    this.dashWidth = 8,
    this.dashHeight = 0.3,
    this.dashSpacing = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = color ?? theme.dividerColor;
    
    if (isVertical) {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        child: Column(
          children: List.generate(
            dashCount,
            (index) => Container(
              margin: EdgeInsets.all(dashSpacing),
              width: 1,
              height: dashWidth,
              color: defaultColor,
            ),
          ),
        ),
      );
    } else {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            dashCount,
            (index) => Container(
              margin: EdgeInsets.all(dashSpacing),
              width: dashWidth,
              height: dashHeight,
              color: defaultColor,
            ),
          ),
        ),
      );
    }
  }
}
