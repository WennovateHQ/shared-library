import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  // Singleton pattern
  static final CacheManager _instance = CacheManager._internal();
  
  factory CacheManager() {
    return _instance;
  }
  
  CacheManager._internal();
  
  /// Set a value in the cache with optional expiration
  Future<void> set(
    String key, 
    String value, 
    {Duration? expiration}
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Store the value
    await prefs.setString(key, value);
    
    // If expiration is provided, store expiration timestamp
    if (expiration != null) {
      final expirationTime = DateTime.now().add(expiration).millisecondsSinceEpoch;
      await prefs.setInt('${key}_expiration', expirationTime);
    }
  }
  
  /// Get a value from the cache, returns null if expired or not found
  Future<String?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if the key exists
    if (!prefs.containsKey(key)) {
      return null;
    }
    
    // Check for expiration
    final expirationKey = '${key}_expiration';
    if (prefs.containsKey(expirationKey)) {
      final expirationTime = prefs.getInt(expirationKey);
      if (expirationTime != null && 
          DateTime.now().millisecondsSinceEpoch > expirationTime) {
        // Cache has expired, clean it up
        await remove(key);
        return null;
      }
    }
    
    // Return the cached value
    return prefs.getString(key);
  }
  
  /// Remove a value from the cache
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove the value and its expiration
    await prefs.remove(key);
    await prefs.remove('${key}_expiration');
  }
  
  /// Clear all cached values
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  /// Get a map value from the cache with typecasting
  Future<Map<String, dynamic>?> getMap(String key) async {
    final jsonString = await get(key);
    if (jsonString == null) {
      return null;
    }
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Invalid JSON or not a map
      await remove(key);
      return null;
    }
  }
  
  /// Set a map value in the cache
  Future<void> setMap(
    String key, 
    Map<String, dynamic> value, 
    {Duration? expiration}
  ) async {
    await set(key, jsonEncode(value), expiration: expiration);
  }
  
  /// Get a list value from the cache
  Future<List<dynamic>?> getList(String key) async {
    final jsonString = await get(key);
    if (jsonString == null) {
      return null;
    }
    
    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      // Invalid JSON or not a list
      await remove(key);
      return null;
    }
  }
  
  /// Set a list value in the cache
  Future<void> setList(
    String key, 
    List<dynamic> value, 
    {Duration? expiration}
  ) async {
    await set(key, jsonEncode(value), expiration: expiration);
  }
}
