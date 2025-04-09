import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// Google Sign-In package - temporarily not in use
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import '../utils/logging_service.dart';

class AuthService with ChangeNotifier {
  // GoogleSignIn implementation temporarily disabled
  // late final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LoggingService _logger = LoggingService('AuthService');

  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;

  // User name getter
  String? get userName => _userData?['firstName'];

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    /* Google Sign-In initialization commented out
    // Initialize GoogleSignIn based on platform and mode
    if (FreshConfig.testingMode) {
      // In testing mode, use a minimal configuration to avoid errors
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    } else if (kIsWeb) {
      // For web, we need to provide the client ID
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
          'https://www.googleapis.com/auth/userinfo.profile',
          'https://www.googleapis.com/auth/userinfo.email',
        ],
        clientId: FreshConfig.googleClientIds['web'],
      );
    } else if (Platform.isAndroid) {
      // For Android, we don't need to specify client ID
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    } else if (Platform.isIOS) {
      // For iOS, we don't need to specify client ID
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    } else {
      // Default configuration for other platforms
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }
    */

    // Initialize auth state from storage
    _checkAuth();
  }

  // Public method to check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _getSecureToken();
    return token != null;
  }

  // Initialize authentication state
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final token = await _getSecureToken();

      // Check if token exists and user was previously logged in
      if (isLoggedIn && token != null) {
        try {
          // Try to fetch user profile from backend
          await getUserProfile();
          _isAuthenticated = true;
        } catch (e) {
          // If getting profile fails, token might be invalid
          _logger.error('Failed to get user profile on init: $e');
          _isAuthenticated = false;

          // Clean up invalid session
          await _secureStorage.delete(key: FreshConfig.tokenKey);
          await prefs.setBool('isLoggedIn', false);
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      _logger.error('Error initializing auth service: $e');
      _isAuthenticated = false;
    }

    notifyListeners();
  }

  // Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      _logger.debug('Attempting login for user: $email');
      
      final response = await http.post(
        Uri.parse(FreshConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      _logger.debug('Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Store authentication data
        await _storeAuthData(
          data['token'],
          data['refreshToken'] ?? '',
          data['user']['role'], 
          data['user']['id'],
          data['user']['email'],
        );
        
        // Store user data
        _userData = data['user'];
        _isAuthenticated = true;
        notifyListeners();
        
        return data['user'];
      } else {
        // Handle error response
        final error = json.decode(response.body);
        _logger.error('Login error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to login');
      }
    } catch (e) {
      _logger.error('Login exception: $e');
      rethrow;
    }
  }

  // Register a new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData,
      {String userType = 'consumer'}) async {
    try {
      _logger.debug('Registering new user with email: ${userData['email']}');
      
      // Add user type to registration data
      userData['role'] = userType;
      
      final response = await http.post(
        Uri.parse(FreshConfig.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      _logger.debug('Register response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Store authentication data if tokens are provided
        if (data['token'] != null) {
          await _storeAuthData(
            data['token'],
            data['refreshToken'] ?? '',
            data['user']['role'], 
            data['user']['id'],
            data['user']['email'],
          );
          
          // Update authentication state
          _userData = data['user'];
          _isAuthenticated = true;
          notifyListeners();
        }
        
        return data['user'];
      } else {
        // Handle error response
        final error = json.decode(response.body);
        _logger.error('Registration error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to register');
      }
    } catch (e) {
      _logger.error('Registration exception: $e');
      rethrow;
    }
  }

  // Logout user
  Future<bool> logout() async {
    try {
      _logger.debug('Logging out user');
      
      final token = await _getSecureToken();
      if (token != null) {
        // Send logout request to backend
        try {
          final response = await http.post(
            Uri.parse(FreshConfig.logoutEndpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          _logger.debug('Logout response status: ${response.statusCode}');
        } catch (e) {
          // Even if the backend request fails, continue with local logout
          _logger.error('Error sending logout to backend: $e');
        }
      }
      
      // Clear local storage and state
      await _secureStorage.delete(key: FreshConfig.tokenKey);
      await _secureStorage.delete(key: FreshConfig.refreshTokenKey);
      await _secureStorage.delete(key: FreshConfig.userRoleKey);
      await _secureStorage.delete(key: FreshConfig.userIdKey);
      await _secureStorage.delete(key: FreshConfig.userEmailKey);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      
      _userData = null;
      _isAuthenticated = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _logger.error('Logout exception: $e');
      return false;
    }
  }

  // Request password reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      if (FreshConfig.testingMode) {
        // For testing purposes, simulate success
        await Future.delayed(const Duration(seconds: 1));
        return true;
      }
      
      final response = await http.post(
        Uri.parse(FreshConfig.forgotPasswordEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to send password reset email');
      }
    } catch (e) {
      _logger.error('Password reset request error: $e');
      if (FreshConfig.testingMode) {
        return true;
      }
      rethrow;
    }
  }

  // Reset password with token
  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      _logger.debug('Resetting password with token');
      
      final response = await http.post(
        Uri.parse(FreshConfig.resetPasswordEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      _logger.debug('Reset password response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        // Handle error response
        final error = json.decode(response.body);
        _logger.error('Reset password error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      _logger.error('Reset password exception: $e');
      rethrow;
    }
  }

  // Verify email address
  Future<bool> verifyEmail(String token) async {
    try {
      _logger.debug('Verifying email with token');
      
      final response = await http.post(
        Uri.parse(FreshConfig.verifyEmailEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );

      _logger.debug('Verify email response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        // Handle error response
        final error = json.decode(response.body);
        _logger.error('Verify email error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to verify email');
      }
    } catch (e) {
      _logger.error('Verify email exception: $e');
      rethrow;
    }
  }

  // Resend verification email
  Future<bool> resendVerificationEmail(String email) async {
    try {
      _logger.debug('Requesting verification email resend for: $email');
      
      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      _logger.debug('Resend verification email response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        // Handle error response
        final error = json.decode(response.body);
        _logger.error('Resend verification email error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to resend verification email');
      }
    } catch (e) {
      _logger.error('Resend verification email exception: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> userData) async {
    try {
      _logger.debug('Updating user profile with data: ${userData.keys.join(", ")}');
      
      final token = await _getSecureToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse(FreshConfig.updateProfileEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      _logger.debug('Update profile response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Update user data
        _userData = data['user'] ?? data;
        notifyListeners();
        
        return _userData!;
      } else {
        // Handle error response
        final error = json.decode(response.body);
        _logger.error('Update profile error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _logger.error('Update profile exception: $e');
      rethrow;
    }
  }

  // Change user password
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      _logger.debug('Changing password for current user');
      
      final token = await _getSecureToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse(FreshConfig.changePasswordEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      _logger.debug('Change password response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        // Handle error response
        final error = json.decode(response.body);
        _logger.error('Change password error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      _logger.error('Change password exception: $e');
      rethrow;
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(XFile image) async {
    try {
      if (FreshConfig.testingMode) {
        // For testing purposes, simulate success
        await Future.delayed(const Duration(seconds: 2));
        
        // Return a mock image URL
        return 'https://picsum.photos/200';
      }
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(FreshConfig.uploadProfileImageEndpoint),
      );
      
      // Add auth headers
      final headers = await getAuthHeaders();
      request.headers.addAll(headers);
      
      // Add file
      final bytes = await image.readAsBytes();
      final file = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: image.name,
      );
      request.files.add(file);
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageUrl = data['imageUrl'] ?? data['url'];
        
        if (imageUrl != null) {
          return imageUrl;
        } else {
          throw Exception('No image URL returned from server');
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to upload profile image');
      }
    } catch (e) {
      _logger.error('Profile image upload error: $e');
      if (FreshConfig.testingMode) {
        return 'https://picsum.photos/200';
      }
      rethrow;
    }
  }

  // Get user profile from backend
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      _logger.debug('Fetching user profile');
      
      final token = await _getSecureToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse(FreshConfig.userProfileEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _logger.debug('Get user profile response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Update user data
        _userData = data['user'] ?? data;
        _isAuthenticated = true;
        notifyListeners();
        
        return _userData!;
      } else {
        // Handle error response
        final error = json.decode(response.body);
        _logger.error('Get user profile error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to get user profile');
      }
    } catch (e) {
      _logger.error('Get user profile exception: $e');
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    }
  }

  // Secure token storage methods
  Future<void> _storeAuthData(String token, String refreshToken, String role, String userId, String email) async {
    try {
      await _secureStorage.write(key: FreshConfig.tokenKey, value: token);
      await _secureStorage.write(key: FreshConfig.refreshTokenKey, value: refreshToken);
      await _secureStorage.write(key: FreshConfig.userRoleKey, value: role);
      await _secureStorage.write(key: FreshConfig.userIdKey, value: userId);
      await _secureStorage.write(key: FreshConfig.userEmailKey, value: email);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
    } catch (e) {
      _logger.error('Error storing auth data: $e');
    }
  }

  Future<String?> _getSecureToken() async {
    try {
      return await _secureStorage.read(key: FreshConfig.tokenKey);
    } catch (e) {
      _logger.error('Error retrieving token: $e');
      return null;
    }
  }

  // Helper method to get auth headers for API requests
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _getSecureToken();
    if (token == null) {
      return {
        'Content-Type': 'application/json',
      };
    }
    
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Check if a user has required permissions
  bool hasPermission(String permission) {
    if (!_isAuthenticated || _userData == null) {
      return false;
    }

    final role = _userData!['role'];
    
    // Define permissions for each role
    Map<String, List<String>> rolePermissions = {
      'admin': ['read', 'write', 'update', 'delete', 'admin'],
      'farmer': ['read', 'write', 'update', 'delete_own'],
      'driver': ['read', 'update_delivery'],
      'consumer': ['read', 'create_order']
    };
    
    if (rolePermissions.containsKey(role)) {
      return rolePermissions[role]!.contains(permission);
    }
    
    return false;
  }

  // Forgot Password
  Future<bool> forgotPassword(String email) async {
    try {
      _logger.debug('Requesting password reset for: $email');
      
      final response = await http.post(
        Uri.parse(FreshConfig.forgotPasswordEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      _logger.debug('Forgot password response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        _logger.error('Forgot password error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to send password reset email');
      }
    } catch (e) {
      _logger.error('Forgot password exception: $e');
      rethrow;
    }
  }

  // Initialize auth state from storage
  Future<void> _checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final token = await _getSecureToken();

      // Check if token exists and user was previously logged in
      if (isLoggedIn && token != null) {
        try {
          // Try to fetch user profile from backend
          await getUserProfile();
          _isAuthenticated = true;
        } catch (e) {
          // If getting profile fails, token might be invalid
          _logger.error('Failed to get user profile on init: $e');
          _isAuthenticated = false;

          // Clean up invalid session
          await _secureStorage.delete(key: FreshConfig.tokenKey);
          await prefs.setBool('isLoggedIn', false);
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      _logger.error('Error initializing auth service: $e');
      _isAuthenticated = false;
    }

    notifyListeners();
  }
}
