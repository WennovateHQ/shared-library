import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// Google Sign-In package - temporarily not in use
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../config.dart';

class AuthService with ChangeNotifier {
  // GoogleSignIn implementation temporarily disabled
  // late final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;

  // User name getter
  String? get userName => _userData?['name'];

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
          debugPrint('Failed to get user profile on init: $e');
          _isAuthenticated = false;

          // Clean up invalid session
          await _secureStorage.delete(key: FreshConfig.tokenKey);
          await prefs.setBool('isLoggedIn', false);
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
      _isAuthenticated = false;
    }

    notifyListeners();
  }

  // Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${FreshConfig.apiBaseUrl}/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Debug the response structure
        debugPrint('Auth response: ${response.body}');

        // Store auth data - backend JWT format
        await _storeAuthData(
          data['access_token'], 
          data['refresh_token'],
          data['user_role'],
          data['user_id'],
          email
        );

        // Store user data if available in the response
        if (data['user'] != null) {
          _userData = data['user'];
        } else {
          // If user data isn't returned directly, create basic user object
          _userData = {
            'id': data['user_id'] ?? 'unknown_id',
            'email': email,
            'role': data['user_role'] ?? 'consumer'
          };
        }

        _isAuthenticated = true;
        notifyListeners();

        return data;
      } else {
        debugPrint('Login failed with status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? error['error'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('Login error: $e');

      // Add test mode handling for login
      if (FreshConfig.testingMode) {
        // For testing mode, provide mock login data based on our JWT system
        if (email == 'test@example.com' && password == 'password123') {
          // Mock successful login with structure matching our JWT backend
          final mockToken =
              'mock_jwt_token_for_testing_${DateTime.now().millisecondsSinceEpoch}';
          final mockRefreshToken = 
              'mock_refresh_token_for_testing_${DateTime.now().millisecondsSinceEpoch}';
          final mockUserRole = 'consumer';
          final mockUserId = 'mock_user_id_${DateTime.now().millisecondsSinceEpoch}';

          // Store auth data
          await _storeAuthData(
            mockToken,
            mockRefreshToken,
            mockUserRole,
            mockUserId,
            email
          );

          // Generate mock user data matching our backend structure
          _userData = {
            'id': mockUserId,
            'email': email,
            'role': mockUserRole,
            'firstName': 'Test',
            'lastName': 'User',
            'profile': {
              'phoneNumber': '1234567890',
              'address': '123 Test Street'
            }
          };

          _isAuthenticated = true;
          notifyListeners();

          return {
            'access_token': mockToken,
            'token_type': 'bearer',
            'expires_in': 3600,
            'refresh_token': mockRefreshToken,
            'user_id': mockUserId,
            'user_role': mockUserRole,
            'user': _userData,
          };
        } else {
          // Mock login failure with structure matching our backend error responses
          throw Exception('Invalid email or password');
        }
      }

      rethrow;
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData,
      {String userType = 'consumer'}) async {
    try {
      // Add role to the userData if not already present
      if (!userData.containsKey('role')) {
        userData['role'] = userType;
      }

      // Ensure proper field naming to match backend expectations
      final Map<String, dynamic> requestBody = {
        'email': userData['email'],
        'password': userData['password'],
        'firstName': userData['firstName'],
        'lastName': userData['lastName'],
        'phoneNumber': userData['phoneNumber'],
        'role': userData['role'] ?? 'consumer'
      };

      final response = await http.post(
        Uri.parse('${FreshConfig.apiBaseUrl}/api/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      debugPrint('Registration response code: ${response.statusCode}');
      debugPrint('Registration response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // For development with TESTING=true, we'll store the verification token
        // so we can use it without an actual email
        if (data['user'] != null && data['user']['verificationToken'] != null) {
          // Store verification token in secure storage for testing purposes
          await _secureStorage.write(
            key: 'verification_token',
            value: data['user']['verificationToken']
          );
          debugPrint('Saved verification token: ${data['user']['verificationToken']}');
        }
        
        // Return the full response data
        return data;
      } else {
        debugPrint('Registration failed with status code: ${response.statusCode}');
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? error['error'] ?? 'Registration failed');
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      
      // Test mode handling
      if (FreshConfig.testingMode) {
        // Mock successful registration
        final mockToken = 'mock_jwt_token_for_testing_${DateTime.now().millisecondsSinceEpoch}';
        
        // Store auth data
        await _storeAuthData(mockToken, 'mock_refresh_token', userType, 'mock_user_id_${DateTime.now().millisecondsSinceEpoch}', userData['email']);
        
        _userData = userData;
        _isAuthenticated = true;
        notifyListeners();
        
        return {
          'access_token': mockToken,
          'user_id': 'mock_user_id_${DateTime.now().millisecondsSinceEpoch}',
          'role': userType,
          'message': 'Registration successful'
        };
      }
      
      rethrow;
    }
  }

  // Logout user
  Future<bool> logout() async {
    try {
      // Clear secure storage
      await _secureStorage.deleteAll();

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userType');

      _isAuthenticated = false;
      _userData = null;
      notifyListeners();

      return true;
    } catch (e) {
      return false;
    }
  }

  // Password Reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse(FreshConfig.forgotPasswordEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['message'] ?? 'Failed to send password reset email');
      }
    } catch (e) {
      if (!FreshConfig.testingMode) {
        rethrow;
      }

      // For testing mode, simulate successful password reset request
      return true;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse(FreshConfig.resetPasswordEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      if (!FreshConfig.testingMode) {
        rethrow;
      }

      // For testing mode, simulate successful password reset
      return true;
    }
  }

  // Verify email with verification token
  Future<bool> verifyEmail(String token) async {
    try {
      // If token is empty, try to retrieve it from secure storage (for testing)
      if (token.isEmpty) {
        final storedToken = await _secureStorage.read(key: 'verification_token');
        if (storedToken != null) {
          token = storedToken;
          debugPrint('Using stored verification token: $token');
        } else {
          throw Exception('Verification token not provided');
        }
      }

      final response = await http.post(
        Uri.parse('${FreshConfig.apiBaseUrl}/api/auth/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'token': token}),
      );

      debugPrint('Verification response status: ${response.statusCode}');
      debugPrint('Verification response: ${response.body}');

      if (response.statusCode == 200) {
        // Clear the stored verification token after successful verification
        await _secureStorage.delete(key: 'verification_token');
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? error['error'] ?? 'Email verification failed');
      }
    } catch (e) {
      debugPrint('Email verification error: $e');
      
      // Testing mode - auto-verify
      if (FreshConfig.testingMode) {
        debugPrint('Testing mode: Auto-verifying email');
        return true;
      }
      
      rethrow;
    }
  }

  // Resend verification email
  Future<bool> resendVerificationEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${FreshConfig.apiUrl}/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['message'] ?? 'Failed to resend verification email');
      }
    } catch (e) {
      if (!FreshConfig.testingMode) {
        rethrow;
      }

      // For testing mode, simulate successful email resend
      return true;
    }
  }

  // Update User Profile
  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> userData) async {
    try {
      final token = await _getSecureToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse(FreshConfig.updateProfileEndpoint),
        headers: await getAuthHeaders(),
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update local user data
        _userData = data['user'];
        notifyListeners();

        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      if (!FreshConfig.testingMode) {
        rethrow;
      }

      // For testing mode, simulate successful profile update

      // Update local user data with new data while preserving existing data
      _userData = {
        ..._userData ?? {},
        ...userData,
      };

      notifyListeners();

      return {
        'success': true,
        'user': _userData,
      };
    }
  }

  // Change Password
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final token = await _getSecureToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse(FreshConfig.changePasswordEndpoint),
        headers: await getAuthHeaders(),
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      if (!FreshConfig.testingMode) {
        rethrow;
      }

      // For testing mode, simulate successful password change
      return true;
    }
  }

  // Upload Profile Image
  Future<String> uploadProfileImage(XFile image) async {
    try {
      final token = await _getSecureToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Create a multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(FreshConfig.uploadProfileImageEndpoint),
      );

      // Set the authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the file to the request
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
      ));

      // Send the request
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);

        // Update profile image in user data
        if (_userData != null) {
          _userData!['profileImage'] = data['imageUrl'];
          notifyListeners();
        }

        return data['imageUrl'];
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      if (!FreshConfig.testingMode) {
        rethrow;
      }

      // For testing mode, simulate successful image upload
      final mockImageUrl =
          'https://example.com/uploads/profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Update profile image in user data
      if (_userData != null) {
        _userData!['profileImage'] = mockImageUrl;
        notifyListeners();
      }

      return mockImageUrl;
    }
  }

  // Get User Profile
  Future<Map<String, dynamic>> getUserProfile() async {
    if (!_isAuthenticated) {
      throw Exception('User not authenticated');
    }

    final token = await _getSecureToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse(FreshConfig.userProfileEndpoint),
        headers: await getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Update the user data with the profile information
        _userData = data;
        notifyListeners();
        return data;
      } else if (response.statusCode == 401) {
        // Token is invalid or expired
        _isAuthenticated = false;
        notifyListeners();
        throw Exception('Authentication token expired');
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get user profile error: $e');
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
      debugPrint('Error storing auth data: $e');
    }
  }

  Future<String?> _getSecureToken() async {
    try {
      return await _secureStorage.read(key: FreshConfig.tokenKey);
    } catch (e) {
      debugPrint('Error retrieving token: $e');
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
      final response = await http.post(
        Uri.parse(FreshConfig.forgotPasswordEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['message'] ?? 'Failed to send password reset email');
      }
    } catch (e) {
      if (!FreshConfig.testingMode) {
        rethrow;
      }

      // For testing mode, simulate successful password reset request
      return true;
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
          debugPrint('Failed to get user profile on init: $e');
          _isAuthenticated = false;

          // Clean up invalid session
          await _secureStorage.delete(key: FreshConfig.tokenKey);
          await prefs.setBool('isLoggedIn', false);
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
      _isAuthenticated = false;
    }

    notifyListeners();
  }
}
