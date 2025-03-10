import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling local storage operations using shared preferences
/// Used for storing user preferences, app state, and caching simple data
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  static SharedPreferences? _preferences;
  
  factory LocalStorageService() {
    return _instance;
  }
  
  LocalStorageService._internal();
  
  /// Initialize the shared preferences instance
  Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }
  
  /// Get the shared preferences instance
  /// Initializes it if not already initialized
  Future<SharedPreferences> get preferences async {
    if (_preferences == null) {
      await init();
    }
    return _preferences!;
  }
  
  /// Store a string value
  Future<bool> setString(String key, String value) async {
    final prefs = await preferences;
    return prefs.setString(key, value);
  }
  
  /// Get a string value
  Future<String?> getString(String key) async {
    final prefs = await preferences;
    return prefs.getString(key);
  }
  
  /// Store an integer value
  Future<bool> setInt(String key, int value) async {
    final prefs = await preferences;
    return prefs.setInt(key, value);
  }
  
  /// Get an integer value
  Future<int?> getInt(String key) async {
    final prefs = await preferences;
    return prefs.getInt(key);
  }
  
  /// Store a boolean value
  Future<bool> setBool(String key, bool value) async {
    final prefs = await preferences;
    return prefs.setBool(key, value);
  }
  
  /// Get a boolean value
  Future<bool?> getBool(String key) async {
    final prefs = await preferences;
    return prefs.getBool(key);
  }
  
  /// Store a double value
  Future<bool> setDouble(String key, double value) async {
    final prefs = await preferences;
    return prefs.setDouble(key, value);
  }
  
  /// Get a double value
  Future<double?> getDouble(String key) async {
    final prefs = await preferences;
    return prefs.getDouble(key);
  }
  
  /// Store a list of strings
  Future<bool> setStringList(String key, List<String> value) async {
    final prefs = await preferences;
    return prefs.setStringList(key, value);
  }
  
  /// Get a list of strings
  Future<List<String>?> getStringList(String key) async {
    final prefs = await preferences;
    return prefs.getStringList(key);
  }
  
  /// Remove a value by key
  Future<bool> remove(String key) async {
    final prefs = await preferences;
    return prefs.remove(key);
  }
  
  /// Clear all stored values
  Future<bool> clear() async {
    final prefs = await preferences;
    return prefs.clear();
  }
  
  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    final prefs = await preferences;
    return prefs.containsKey(key);
  }
  
  /// Get all keys
  Future<Set<String>> getKeys() async {
    final prefs = await preferences;
    return prefs.getKeys();
  }
}
