/// Configuration file for the FreshFarmily apps
/// Contains shared configuration values and API endpoints

class FreshConfig {
  /// Backend API base URL
  static const String apiBaseUrl = 'http://localhost:5000'; // Development server

  /// Full API URL
  static const String apiUrl = '$apiBaseUrl';

  /// Auth endpoints
  static const String loginEndpoint = '$apiUrl/auth/login';
  static const String registerEndpoint = '$apiUrl/auth/register';
  static const String googleSignInEndpoint = '$apiUrl/auth/google-signin';
  static const String forgotPasswordEndpoint = '$apiUrl/auth/forgot-password';
  static const String resetPasswordEndpoint = '$apiUrl/auth/reset-password';
  static const String verifyEmailEndpoint = '$apiUrl/auth/verify';
  static const String changePasswordEndpoint = '$apiUrl/auth/change-password';
  static const String refreshTokenEndpoint = '$apiUrl/auth/refresh';
  static const String logoutEndpoint = '$apiUrl/auth/logout';
  static const String meEndpoint = '$apiUrl/auth/me';

  /// User endpoints
  static const String userProfileEndpoint = '$apiUrl/auth/me';
  static const String updateProfileEndpoint = '$apiUrl/user/profile';
  static const String uploadProfileImageEndpoint =
      '$apiUrl/upload/profile-image';

  /// Storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String userEmailKey = 'user_email';
  static const String onboardingCompleteKey = 'has_completed_onboarding';
  static const String isLoggedInKey = 'is_logged_in';

  /// Testing mode flag
  static const bool testingMode = false; // Disable testing mode - always connect to real backend

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
  static const int minPasswordLength =
      6; // Updated to match backend requirement
  static const bool requirePasswordSpecialChar =
      false; // Simplified for development
  static const bool requirePasswordUppercase =
      false; // Simplified for development
  static const bool requirePasswordNumber = false; // Simplified for development

  /// Registration email verification settings
  static const bool requireEmailVerification =
      false; // Disabled for development
  static const int verificationCodeExpiryMinutes = 30;
  static const int maxResendVerificationAttempts = 5;

  /// Password reset settings
  static const int resetTokenExpiryMinutes = 15;
  static const int maxFailedLoginAttempts = 5;
  static const int accountLockoutMinutes = 15;
}
