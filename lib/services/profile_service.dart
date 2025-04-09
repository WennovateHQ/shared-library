import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../utils/api_utils.dart';
import '../utils/logging_service.dart';

/// A service class that handles all user profile-related operations
class ProfileService {
  // Singleton pattern
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final LoggingService _logger = LoggingService('ProfileService');

  /// Get the current user profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      _logger.debug('Fetching user profile');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse(FreshConfig.userProfileEndpoint),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Get user profile response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['user'] ?? data;
      } else {
        final error = json.decode(response.body);
        _logger.error('Get user profile error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to get user profile');
      }
    } catch (e) {
      _logger.error('Get user profile exception: $e');
      rethrow;
    }
  }

  /// Update the user profile data
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
    try {
      _logger.debug('Updating user profile with data: ${userData.keys.join(", ")}');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.put(
        Uri.parse(FreshConfig.updateProfileEndpoint),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      _logger.debug('Update profile response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['user'] ?? data;
      } else {
        final error = json.decode(response.body);
        _logger.error('Update profile error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _logger.error('Update profile exception: $e');
      rethrow;
    }
  }

  /// Upload a profile image
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      _logger.debug('Uploading profile image');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      // Create multipart request
      final request = http.MultipartRequest(
        'POST', 
        Uri.parse(FreshConfig.uploadProfileImageEndpoint)
      );
      
      // Add authorization headers
      request.headers.addAll(ApiUtils.createAuthHeaders(token));
      
      // Get the file extension and determine mime type
      final fileExtension = path.extension(imageFile.path).substring(1);
      final mimeType = 'image/$fileExtension';
      
      // Add file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image', 
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _logger.debug('Upload profile image response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['url'] ?? data['imageUrl'] ?? '';
      } else {
        final error = json.decode(response.body);
        _logger.error('Upload profile image error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to upload profile image');
      }
    } catch (e) {
      _logger.error('Upload profile image exception: $e');
      rethrow;
    }
  }

  /// Update user notification preferences
  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, bool> preferences) async {
    try {
      _logger.debug('Updating notification preferences: $preferences');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.put(
        Uri.parse('${FreshConfig.apiUrl}/user/notification-preferences'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode({'preferences': preferences}),
      );

      _logger.debug('Update notification preferences response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        _logger.error('Update notification preferences error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to update notification preferences');
      }
    } catch (e) {
      _logger.error('Update notification preferences exception: $e');
      rethrow;
    }
  }

  /// Get user notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      _logger.debug('Fetching notification preferences');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/user/notification-preferences'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Get notification preferences response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final preferences = data['preferences'];
        return Map<String, bool>.from(preferences);
      } else {
        final error = json.decode(response.body);
        _logger.error('Get notification preferences error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to get notification preferences');
      }
    } catch (e) {
      _logger.error('Get notification preferences exception: $e');
      rethrow;
    }
  }

  /// Update user address
  Future<Map<String, dynamic>> updateAddress(Map<String, dynamic> addressData) async {
    try {
      _logger.debug('Updating user address');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.put(
        Uri.parse('${FreshConfig.apiUrl}/user/address'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(addressData),
      );

      _logger.debug('Update address response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        _logger.error('Update address error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to update address');
      }
    } catch (e) {
      _logger.error('Update address exception: $e');
      rethrow;
    }
  }

  /// Get user address list
  Future<List<Map<String, dynamic>>> getUserAddresses() async {
    try {
      _logger.debug('Fetching user addresses');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/user/addresses'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Get user addresses response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addresses = data['addresses'] as List;
        return addresses.map((address) => Map<String, dynamic>.from(address)).toList();
      } else {
        final error = json.decode(response.body);
        _logger.error('Get user addresses error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to get user addresses');
      }
    } catch (e) {
      _logger.error('Get user addresses exception: $e');
      rethrow;
    }
  }

  /// Add a new address
  Future<Map<String, dynamic>> addAddress(Map<String, dynamic> addressData) async {
    try {
      _logger.debug('Adding new address');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/user/addresses'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(addressData),
      );

      _logger.debug('Add address response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        _logger.error('Add address error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to add address');
      }
    } catch (e) {
      _logger.error('Add address exception: $e');
      rethrow;
    }
  }

  /// Delete an address
  Future<bool> deleteAddress(String addressId) async {
    try {
      _logger.debug('Deleting address ID: $addressId');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.delete(
        Uri.parse('${FreshConfig.apiUrl}/user/addresses/$addressId'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Delete address response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        _logger.error('Delete address error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to delete address');
      }
    } catch (e) {
      _logger.error('Delete address exception: $e');
      rethrow;
    }
  }

  /// Set a default address
  Future<bool> setDefaultAddress(String addressId) async {
    try {
      _logger.debug('Setting default address ID: $addressId');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.put(
        Uri.parse('${FreshConfig.apiUrl}/user/addresses/$addressId/default'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Set default address response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        _logger.error('Set default address error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to set default address');
      }
    } catch (e) {
      _logger.error('Set default address exception: $e');
      rethrow;
    }
  }

  /// Update user settings (app preferences)
  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    try {
      _logger.debug('Updating user settings: ${settings.keys.join(", ")}');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.put(
        Uri.parse('${FreshConfig.apiUrl}/user/settings'),
        headers: {
          ...ApiUtils.createAuthHeaders(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(settings),
      );

      _logger.debug('Update settings response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        _logger.error('Update settings error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to update settings');
      }
    } catch (e) {
      _logger.error('Update settings exception: $e');
      rethrow;
    }
  }

  /// Get user settings (app preferences)
  Future<Map<String, dynamic>> getSettings() async {
    try {
      _logger.debug('Fetching user settings');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('${FreshConfig.apiUrl}/user/settings'),
        headers: ApiUtils.createAuthHeaders(token),
      );

      _logger.debug('Get settings response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['settings'] ?? data;
      } else {
        final error = json.decode(response.body);
        _logger.error('Get settings error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to get settings');
      }
    } catch (e) {
      _logger.error('Get settings exception: $e');
      rethrow;
    }
  }
}
