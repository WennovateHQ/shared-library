/// Configuration file for the FreshFarmily apps
/// Contains shared configuration values and API endpoints

class FreshConfig {
  /// Backend API base URL
  static const String apiBaseUrl = 'https://api.freshfarmily.com';  // Production server

  /// API path
  static const String apiPath = 'api';

  /// Full API URL
  static const String apiUrl = '$apiBaseUrl/$apiPath';

  /// Auth endpoints
  static const String loginEndpoint = '$apiUrl/auth/login';
  static const String registerEndpoint = '$apiUrl/auth/register';
  static const String googleSignInEndpoint = '$apiUrl/auth/google-signin';
  static const String forgotPasswordEndpoint = '$apiUrl/auth/forgot-password';
  static const String resetPasswordEndpoint = '$apiUrl/auth/reset-password';
  static const String verifyEmailEndpoint = '$apiUrl/auth/verify-email';
  static const String changePasswordEndpoint = '$apiUrl/auth/change-password';
  static const String refreshTokenEndpoint = '$apiUrl/auth/refresh-token';
  static const String logoutEndpoint = '$apiUrl/auth/logout';

  /// User endpoints
  static const String userProfileEndpoint = '$apiUrl/user/profile';
  static const String updateProfileEndpoint = '$apiUrl/user/profile/update';
  static const String uploadProfileImageEndpoint = '$apiUrl/user/profile/image';

  /// Storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String userEmailKey = 'user_email';
  static const String onboardingCompleteKey = 'has_completed_onboarding';
  static const String isLoggedInKey = 'is_logged_in';

  /// Testing mode flag
  static const bool testingMode = false; // Disabled for production to ensure connection to real backend

  /// Google Sign-In scopes
  static const List<String> googleSignInScopes = [
    'email',
    'profile',
  ];

  /// Google OAuth client IDs for each platform
  static const Map<String, String> googleClientIds = {
    'web':
        '57593671860-mclc7rr7d9mf0du6o19usivhd8d7fe2k.apps.googleusercontent.com', // Must match GOOGLE_CLIENT_ID in backend settings.py
    'android': '', // Add your Android client ID here if needed
    'ios': '', // Add your iOS client ID here if needed
  };

  /// App theme configurations
  static const int primaryColor = 0xFF4CAF50; // Green color for the app

  /// Debug mode flag
  static const bool debugMode = true;

  /// App specific configurations
  static Map<String, dynamic> getAppConfig(String appType) {
    switch (appType) {
      case 'consumer':
        return {
          'primaryColor': 0xFF4CAF50, // Green
          'appName': 'FreshFarmily',
          'defaultRoute': '/home',
          'splashDuration': 2, // seconds
        };
      case 'farmer':
        return {
          'primaryColor': 0xFF8BC34A, // Light Green
          'appName': 'FreshFarmily Farmer',
          'defaultRoute': '/dashboard',
          'splashDuration': 2, // seconds
        };
      case 'driver':
        return {
          'primaryColor': 0xFF009688, // Teal
          'appName': 'FreshFarmily Driver',
          'defaultRoute': '/deliveries',
          'splashDuration': 2, // seconds
        };
      default:
        return {
          'primaryColor': 0xFF4CAF50, // Green
          'appName': 'FreshFarmily',
          'defaultRoute': '/home',
          'splashDuration': 2, // seconds
        };
    }
  }

  /// Authentication timeout
  static const int tokenExpiryMinutes = 60; // 1 hour token expiry
  static const int refreshTokenExpiryDays = 30; // 30 day refresh token expiry

  /// Minimum password requirements
  static const int minPasswordLength = 8;
  static const bool requirePasswordSpecialChar = true;
  static const bool requirePasswordUppercase = true;
  static const bool requirePasswordNumber = true;

  /// Registration email verification settings
  static const bool requireEmailVerification = true;
  static const int verificationCodeExpiryMinutes = 30;
  static const int maxResendVerificationAttempts = 5;

  /// Password reset settings
  static const int resetTokenExpiryMinutes = 15;
  static const int maxFailedLoginAttempts = 5;
  static const int accountLockoutMinutes = 15;
}
