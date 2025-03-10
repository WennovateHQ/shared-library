import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/farm.dart';
import '../config.dart';
import 'auth_service.dart';

class FarmService extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final List<Farm> _farms = [];
  bool _isLoading = false;
  String? _error;

  List<Farm> get farms => _farms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all farms
  Future<List<Farm>> getAllFarms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use mock data in test mode
      if (FreshConfig.testingMode) {
        await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
        final mockFarms = _getMockFarms();
        _farms.clear();
        _farms.addAll(mockFarms);
        _isLoading = false;
        notifyListeners();
        return mockFarms;
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/farms'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> farmData = json.decode(response.body);
        _farms.clear();
        
        for (var farm in farmData) {
          _farms.add(Farm.fromJson(farm));
        }
        
        _isLoading = false;
        notifyListeners();
        return _farms;
      } else {
        _error = 'Failed to load farms: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching farms: $e');
      // Fallback to mock data in case of error and testing mode is enabled
      if (FreshConfig.testingMode) {
        final mockFarms = _getMockFarms();
        _farms.clear();
        _farms.addAll(mockFarms);
        _isLoading = false;
        notifyListeners();
        return mockFarms;
      }
      
      _error = 'Error fetching farms: $e';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get featured farms
  Future<List<Farm>> getFeaturedFarms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use mock data in test mode
      if (FreshConfig.testingMode) {
        await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
        final mockFarms = _getMockFarms().take(3).toList(); // Take first 3 farms as featured
        _isLoading = false;
        notifyListeners();
        return mockFarms;
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/farms/featured'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> farmData = json.decode(response.body);
        final List<Farm> featuredFarms = [];
        
        for (var farm in farmData) {
          featuredFarms.add(Farm.fromJson(farm));
        }
        
        _isLoading = false;
        notifyListeners();
        return featuredFarms;
      } else if (response.statusCode == 404) {
        // If the featured endpoint is not available, fall back to all farms
        return getAllFarms();
      } else {
        _error = 'Failed to load featured farms: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching featured farms: $e');
      // Fallback to mock data in case of error and testing mode is enabled
      if (FreshConfig.testingMode) {
        final mockFarms = _getMockFarms().take(3).toList(); // Take first 3 farms as featured
        _isLoading = false;
        notifyListeners();
        return mockFarms;
      }
      
      _error = 'Error fetching featured farms: $e';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get farm by ID
  Future<Farm?> getFarmById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use mock data in test mode
      if (FreshConfig.testingMode) {
        await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
        final mockFarm = _getMockFarms().firstWhere(
          (farm) => farm.id == id,
          orElse: () => _getMockFarms().first,
        );
        _isLoading = false;
        notifyListeners();
        return mockFarm;
      }

      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/farms/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final farmData = json.decode(response.body);
        final farm = Farm.fromJson(farmData);
        
        _isLoading = false;
        notifyListeners();
        return farm;
      } else {
        _error = 'Failed to load farm details: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching farm details: $e');
      // Fallback to mock data in case of error and testing mode is enabled
      if (FreshConfig.testingMode) {
        final mockFarm = _getMockFarms().firstWhere(
          (farm) => farm.id == id,
          orElse: () => _getMockFarms().first,
        );
        _isLoading = false;
        notifyListeners();
        return mockFarm;
      }
      
      _error = 'Error fetching farm details: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Follow/unfollow a farm
  Future<bool> toggleFollowFarm(String farmId, bool follow) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final url = '${FreshConfig.apiUrl}/farms/$farmId/${follow ? 'follow' : 'unfollow'}';
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Update the local farm object if it exists in the list
        final index = _farms.indexWhere((farm) => farm.id == farmId);
        if (index != -1) {
          // This is a simplified update since we'd need to get the updated farm from the response
          // In a real app, we might want to refetch the farm or update the followers count
          await getFarmById(farmId);
          notifyListeners();
        }
        return true;
      } else {
        _error = 'Failed to ${follow ? 'follow' : 'unfollow'} farm: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper method to get mock farms for testing
  List<Farm> _getMockFarms() {
    return [
      Farm(
        id: '1',
        name: 'Green Valley Organics',
        description: 'Organic vegetables and fruits grown using sustainable practices. Family-owned farm since 1985.',
        location: 'Sonoma County, CA',
        image: 'https://images.unsplash.com/photo-1500076656116-558758c991c1?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1471&q=80',
        rating: 4.8,
        productsCount: 24,
        isOrganic: true,
        specialties: ['Heirloom Tomatoes', 'Fresh Berries', 'Leafy Greens'],
      ),
      Farm(
        id: '2',
        name: 'Happy Hen Farms',
        description: 'Free-range eggs and poultry. Our chickens roam freely on open pastures and are fed non-GMO feed.',
        location: 'Petaluma, CA',
        image: 'https://images.unsplash.com/photo-1500595046743-cd271d694e30?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1474&q=80',
        rating: 4.7,
        productsCount: 12,
        isOrganic: true,
        specialties: ['Free-range Eggs', 'Organic Chicken', 'Turkey'],
      ),
      Farm(
        id: '3',
        name: 'Coastal Harvest',
        description: 'Fresh seafood caught daily from the Pacific. Sustainable fishing practices that protect marine ecosystems.',
        location: 'Bodega Bay, CA',
        image: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
        rating: 4.9,
        productsCount: 18,
        isOrganic: false,
        specialties: ['Wild-caught Salmon', 'Pacific Oysters', 'Dungeness Crab'],
      ),
      Farm(
        id: '4',
        name: 'Heritage Dairy',
        description: 'Artisanal cheeses and dairy products from grass-fed cows. Traditional cheese-making techniques passed down for generations.',
        location: 'Marin County, CA',
        image: 'https://images.unsplash.com/photo-1529498951903-7fe187ccb990?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
        rating: 4.6,
        productsCount: 15,
        isOrganic: true,
        specialties: ['Aged Cheddar', 'Fresh Butter', 'Artisanal Yogurt'],
      ),
      Farm(
        id: '5',
        name: 'Sunrise Orchards',
        description: 'Family-owned apple orchard with over 20 varieties of apples and stone fruits. Known for our fresh-pressed cider.',
        location: 'Sebastopol, CA',
        image: 'https://images.unsplash.com/photo-1506917728037-b6af01a7d403?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1074&q=80',
        rating: 4.7,
        productsCount: 28,
        isOrganic: true,
        specialties: ['Honeycrisp Apples', 'Fresh-pressed Cider', 'Cherry Preserves'],
      ),
    ];
  }
}
