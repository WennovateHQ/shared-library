import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/review.dart';

class ReviewService {
  // Singleton pattern
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  // Mock data for test mode
  final List<Review> _mockProductReviews = [];
  final List<Review> _mockFarmReviews = [];
  
  // Initialize mock data
  Future<void> _initializeMockData() async {
    if (_mockProductReviews.isNotEmpty || _mockFarmReviews.isNotEmpty) return;
    
    // Create sample product reviews
    _mockProductReviews.addAll([
      Review(
        id: 'review_prod_001',
        userId: 'user_101',
        userName: 'John Smith',
        targetId: 'prod_001', // product id
        targetType: 'product',
        rating: 4.5,
        title: 'Great quality produce',
        content: 'These apples were incredibly fresh and delicious. Will definitely buy again!',
        date: DateTime.now().subtract(const Duration(days: 5)),
        likes: 3,
        images: [],
      ),
      Review(
        id: 'review_prod_002',
        userId: 'user_102',
        userName: 'Jane Doe',
        targetId: 'prod_001', // product id
        targetType: 'product',
        rating: 5.0,
        title: 'Best apples I\'ve ever had',
        content: 'So crisp and sweet. Organic really does taste better!',
        date: DateTime.now().subtract(const Duration(days: 10)),
        likes: 7,
        images: [],
      ),
      Review(
        id: 'review_prod_003',
        userId: 'user_103',
        userName: 'Mike Johnson',
        targetId: 'prod_002', // product id
        targetType: 'product',
        rating: 3.5,
        title: 'Good, but not great',
        content: 'The lettuce was fresh, but slightly wilted on arrival. Still good overall.',
        date: DateTime.now().subtract(const Duration(days: 3)),
        likes: 1,
        images: [],
      ),
    ]);
    
    // Create sample farm reviews
    _mockFarmReviews.addAll([
      Review(
        id: 'review_farm_001',
        userId: 'user_101',
        userName: 'John Smith',
        targetId: 'farm_101', // farm id
        targetType: 'farm',
        rating: 4.8,
        title: 'Amazing farm experience',
        content: 'Visited the farm and was impressed by their sustainable practices. All their produce is excellent!',
        date: DateTime.now().subtract(const Duration(days: 15)),
        likes: 12,
        images: [],
      ),
      Review(
        id: 'review_farm_002',
        userId: 'user_104',
        userName: 'Emma Wilson',
        targetId: 'farm_101', // farm id
        targetType: 'farm',
        rating: 4.5,
        title: 'Great customer service',
        content: 'The farmers are so friendly and knowledgeable. They always throw in some extra herbs with my order!',
        date: DateTime.now().subtract(const Duration(days: 8)),
        likes: 5,
        images: [],
      ),
      Review(
        id: 'review_farm_003',
        userId: 'user_105',
        userName: 'David Brown',
        targetId: 'farm_102', // farm id
        targetType: 'farm',
        rating: 4.0,
        title: 'Good products, slow delivery',
        content: 'The milk and eggs are excellent, but delivery took longer than expected. Still would recommend.',
        date: DateTime.now().subtract(const Duration(days: 6)),
        likes: 2,
        images: [],
      ),
    ]);
  }
  
  // Get all reviews for a product
  Future<List<Review>> getProductReviews(String productId) async {
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      
      // Filter reviews for this product
      final reviews = _mockProductReviews
          .where((review) => review.targetId == productId && review.targetType == 'product')
          .toList();
      
      // Sort by date (newest first)
      reviews.sort((a, b) => b.date.compareTo(a.date));
      
      // If no reviews exist for this product but we're in test mode,
      // generate some mock reviews for testing UI
      if (reviews.isEmpty) {
        final mockReviews = [
          Review(
            id: 'mock_review_${DateTime.now().millisecondsSinceEpoch}_1',
            userId: 'test_user_1',
            userName: 'Test User 1',
            targetId: productId,
            targetType: 'product',
            rating: 4.0,
            title: 'Great product',
            content: 'This is a mock review generated for testing purposes. The product is excellent!',
            date: DateTime.now().subtract(const Duration(days: 2)),
            likes: 3,
            images: [],
          ),
          Review(
            id: 'mock_review_${DateTime.now().millisecondsSinceEpoch}_2',
            userId: 'test_user_2',
            userName: 'Test User 2',
            targetId: productId,
            targetType: 'product',
            rating: 5.0,
            title: 'Fantastic quality',
            content: 'Another mock review for testing. The quality of this product exceeded my expectations.',
            date: DateTime.now().subtract(const Duration(days: 5)),
            likes: 7,
            images: [],
          ),
        ];
        
        // Add these to our mock data for consistency
        _mockProductReviews.addAll(mockReviews);
        return mockReviews;
      }
      
      return reviews;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/products/$productId/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> reviewsJson = json.decode(response.body);
        return reviewsJson.map((json) => Review.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load product reviews: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching product reviews: $e');
      throw Exception('Network error: Unable to fetch product reviews');
    }
  }
  
  // Get review statistics for a product
  Future<Map<String, dynamic>> getProductReviewStats(String productId) async {
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      
      // Filter reviews for this product
      final reviews = _mockProductReviews
          .where((review) => review.targetId == productId && review.targetType == 'product')
          .toList();
      
      // If no reviews, generate some simple stats
      if (reviews.isEmpty) {
        return {
          'average_rating': 4.5,
          'total_reviews': 3,
          'rating_distribution': {
            '5': 2,
            '4': 1,
            '3': 0,
            '2': 0,
            '1': 0,
          }
        };
      }
      
      // Calculate average rating
      double sum = 0;
      for (final review in reviews) {
        sum += review.rating;
      }
      final averageRating = sum / reviews.length;
      
      // Calculate rating distribution
      final Map<String, int> distribution = {
        '5': 0,
        '4': 0,
        '3': 0,
        '2': 0,
        '1': 0,
      };
      
      for (final review in reviews) {
        final rating = review.rating.round();
        final key = rating.toString();
        if (distribution.containsKey(key)) {
          distribution[key] = (distribution[key] ?? 0) + 1;
        }
      }
      
      return {
        'average_rating': averageRating,
        'total_reviews': reviews.length,
        'rating_distribution': distribution,
      };
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/products/$productId/review-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load product review statistics: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching product review statistics: $e');
      throw Exception('Network error: Unable to fetch product review statistics');
    }
  }
  
  // Post a review for a product
  Future<Review> createProductReview({
    required String productId,
    required double rating,
    required String title,
    required String content,
    List<String> images = const [],
  }) async {
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      
      // Get current user info
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'test_user';
      final userName = prefs.getString('user_name') ?? 'Test User';
      
      // Create a new review
      final reviewId = 'review_${DateTime.now().millisecondsSinceEpoch}';
      final review = Review(
        id: reviewId,
        userId: userId,
        userName: userName,
        targetId: productId,
        targetType: 'product',
        rating: rating,
        title: title,
        content: content,
        date: DateTime.now(),
        likes: 0,
        images: images,
      );
      
      // Add to our mock data
      _mockProductReviews.add(review);
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      return review;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final reviewData = {
        'product_id': productId,
        'rating': rating,
        'title': title,
        'content': content,
        'images': images,
      };
      
      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/reviews/product'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(reviewData),
      );
      
      if (response.statusCode == 201) {
        final reviewJson = json.decode(response.body);
        return Review.fromJson(reviewJson);
      } else {
        throw Exception('Failed to create review: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating product review: $e');
      throw Exception('Network error: Unable to submit review');
    }
  }
  
  // Get all reviews for a farm
  Future<List<Review>> getFarmReviews(String farmId) async {
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      
      // Filter reviews for this farm
      final reviews = _mockFarmReviews
          .where((review) => review.targetId == farmId && review.targetType == 'farm')
          .toList();
      
      // Sort by date (newest first)
      reviews.sort((a, b) => b.date.compareTo(a.date));
      
      // If no reviews exist for this farm but we're in test mode,
      // generate some mock reviews for testing UI
      if (reviews.isEmpty) {
        final mockReviews = [
          Review(
            id: 'mock_farm_review_${DateTime.now().millisecondsSinceEpoch}_1',
            userId: 'test_user_1',
            userName: 'Test User 1',
            targetId: farmId,
            targetType: 'farm',
            rating: 4.8,
            title: 'Great farm experience',
            content: 'This is a fantastic farm! They have amazing produce and sustainable farming practices.',
            date: DateTime.now().subtract(const Duration(days: 4)),
            likes: 5,
            images: [],
          ),
          Review(
            id: 'mock_farm_review_${DateTime.now().millisecondsSinceEpoch}_2',
            userId: 'test_user_2',
            userName: 'Test User 2',
            targetId: farmId,
            targetType: 'farm',
            rating: 4.5,
            title: 'Love supporting local farmers',
            content: 'The quality of produce from this farm is consistently excellent. The farmers are also very friendly.',
            date: DateTime.now().subtract(const Duration(days: 12)),
            likes: 8,
            images: [],
          ),
          Review(
            id: 'mock_farm_review_${DateTime.now().millisecondsSinceEpoch}_3',
            userId: 'test_user_3',
            userName: 'Test User 3',
            targetId: farmId,
            targetType: 'farm',
            rating: 5.0,
            title: 'Best farm in the region',
            content: 'I\'ve tried many local farms, and this one is by far my favorite. The farm fresh eggs and dairy are incredible.',
            date: DateTime.now().subtract(const Duration(days: 30)),
            likes: 15,
            images: [],
          ),
        ];
        
        // Add these to our mock data for consistency
        _mockFarmReviews.addAll(mockReviews);
        return mockReviews;
      }
      
      return reviews;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/farms/$farmId/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> reviewsJson = json.decode(response.body);
        return reviewsJson.map((json) => Review.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load farm reviews: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching farm reviews: $e');
      throw Exception('Network error: Unable to fetch farm reviews');
    }
  }
  
  // Get review statistics for a farm
  Future<Map<String, dynamic>> getFarmReviewStats(String farmId) async {
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      
      // Filter reviews for this farm
      final reviews = _mockFarmReviews
          .where((review) => review.targetId == farmId && review.targetType == 'farm')
          .toList();
      
      // If no reviews, generate some simple stats
      if (reviews.isEmpty) {
        return {
          'average_rating': 4.7,
          'total_reviews': 5,
          'rating_distribution': {
            '5': 3,
            '4': 2,
            '3': 0,
            '2': 0,
            '1': 0,
          }
        };
      }
      
      // Calculate average rating
      double sum = 0;
      for (final review in reviews) {
        sum += review.rating;
      }
      final averageRating = sum / reviews.length;
      
      // Calculate rating distribution
      final Map<String, int> distribution = {
        '5': 0,
        '4': 0,
        '3': 0,
        '2': 0,
        '1': 0,
      };
      
      for (final review in reviews) {
        final rating = review.rating.round();
        final key = rating.toString();
        if (distribution.containsKey(key)) {
          distribution[key] = (distribution[key] ?? 0) + 1;
        }
      }
      
      return {
        'average_rating': averageRating,
        'total_reviews': reviews.length,
        'rating_distribution': distribution,
      };
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/farms/$farmId/review-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load farm review statistics: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching farm review statistics: $e');
      throw Exception('Network error: Unable to fetch farm review statistics');
    }
  }
  
  // Post a review for a farm
  Future<Review> createFarmReview({
    required String farmId,
    required double rating,
    required String title,
    required String content,
    List<String> images = const [],
  }) async {
    if (FreshConfig.testingMode) {
      await _initializeMockData();
      
      // Get current user info
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'test_user';
      final userName = prefs.getString('user_name') ?? 'Test User';
      
      // Create a new review
      final reviewId = 'farm_review_${DateTime.now().millisecondsSinceEpoch}';
      final review = Review(
        id: reviewId,
        userId: userId,
        userName: userName,
        targetId: farmId,
        targetType: 'farm',
        rating: rating,
        title: title,
        content: content,
        date: DateTime.now(),
        likes: 0,
        images: images,
      );
      
      // Add to our mock data
      _mockFarmReviews.add(review);
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      return review;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final reviewData = {
        'farm_id': farmId,
        'rating': rating,
        'title': title,
        'content': content,
        'images': images,
      };
      
      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/reviews/farm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(reviewData),
      );
      
      if (response.statusCode == 201) {
        final reviewJson = json.decode(response.body);
        return Review.fromJson(reviewJson);
      } else {
        throw Exception('Failed to create farm review: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating farm review: $e');
      throw Exception('Network error: Unable to submit farm review');
    }
  }
}
