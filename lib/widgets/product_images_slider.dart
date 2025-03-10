import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../themes/fresh_theme.dart';
import 'network_image.dart';

/// A product images slider component based on Pro-Grocery UI kit
/// Used to display multiple product images in a carousel
class ProductImagesSlider extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final bool showIndicator;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final BorderRadius? borderRadius;
  final bool enableInfiniteScroll;
  final BoxFit imageFit;
  final Function(int)? onPageChanged;
  
  const ProductImagesSlider({
    Key? key,
    required this.imageUrls,
    this.height = 250,
    this.showIndicator = true,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.borderRadius,
    this.enableInfiniteScroll = true,
    this.imageFit = BoxFit.cover,
    this.onPageChanged,
  }) : super(key: key);
  
  @override
  State<ProductImagesSlider> createState() => _ProductImagesSliderState();
}

class _ProductImagesSliderState extends State<ProductImagesSlider> {
  int _currentIndex = 0;
  final CarouselController _carouselController = CarouselController();
  
  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      children: [
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: widget.height,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            autoPlay: widget.autoPlay,
            autoPlayInterval: widget.autoPlayInterval,
            enableInfiniteScroll: widget.enableInfiniteScroll && widget.imageUrls.length > 1,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
              widget.onPageChanged?.call(index);
            },
          ),
          items: widget.imageUrls.map((imageUrl) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(
                    color: FreshTheme.scaffoldWithBoxBackground,
                  ),
                  child: ClipRRect(
                    borderRadius: widget.borderRadius ?? BorderRadius.zero,
                    child: NetworkImageWithLoader(
                      imageUrl: imageUrl,
                      fit: widget.imageFit,
                      borderRadius: widget.borderRadius,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        
        if (widget.showIndicator && widget.imageUrls.length > 1)
          _buildIndicator(),
      ],
    );
  }
  
  Widget _buildIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.imageUrls.asMap().entries.map((entry) {
          return GestureDetector(
            onTap: () => _carouselController.animateToPage(entry.key),
            child: Container(
              width: _currentIndex == entry.key ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentIndex == entry.key
                    ? Theme.of(context).colorScheme.primary
                    : FreshTheme.placeholder.withOpacity(0.3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: FreshTheme.cardColor,
        borderRadius: widget.borderRadius,
      ),
      child: const Center(
        child: Icon(
          Icons.photo_outlined,
          size: 48,
          color: FreshTheme.placeholder,
        ),
      ),
    );
  }
}
