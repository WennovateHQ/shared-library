import 'package:flutter/material.dart';
import '../themes/fresh_theme.dart';

/// A product tile widget based on the Pro-Grocery UI kit
/// Can be used to display products in a grid or list
class ProductTile extends StatelessWidget {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double? discountPrice;
  final String unit;
  final bool inStock;
  final double rating;
  final int reviewCount;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final bool showAddButton;
  final String? category;
  final String? farmName;
  
  const ProductTile({
    Key? key,
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.discountPrice,
    required this.unit,
    this.inStock = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.onTap,
    this.onAddToCart,
    this.showAddButton = true,
    this.category,
    this.farmName,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = discountPrice != null && discountPrice! < price;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: FreshTheme.borderRadius,
          boxShadow: FreshTheme.boxShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Discount Badge
            Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(FreshTheme.radius),
                    topRight: Radius.circular(FreshTheme.radius),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: FreshTheme.gray.withAlpha(77),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: FreshTheme.placeholder,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Discount Badge
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${(((price - discountPrice!) / price) * 100).round()}% OFF",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                // Out of stock overlay
                if (!inStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(128),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(FreshTheme.radius),
                          topRight: Radius.circular(FreshTheme.radius),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "OUT OF STOCK",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Product Details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category or Farm name
                  if (category != null || farmName != null)
                    Text(
                      category ?? farmName ?? "",
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary.withAlpha(204),
                      ),
                    ),
                  
                  // Product Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Price and Unit
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Discounted Price
                      if (hasDiscount) ...[
                        Text(
                          "\$${discountPrice!.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "\$${price.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: FreshTheme.placeholder,
                          ),
                        ),
                      ] else
                        Text(
                          "\$${price.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // Unit
                      Text(
                        "/ $unit",
                        style: const TextStyle(
                          fontSize: 12,
                          color: FreshTheme.placeholder,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Rating
                  if (rating > 0)
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$rating",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "($reviewCount)",
                          style: const TextStyle(
                            fontSize: 12,
                            color: FreshTheme.placeholder,
                          ),
                        ),
                      ],
                    ),
                    
                  // Add to Cart Button
                  if (showAddButton && inStock)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
