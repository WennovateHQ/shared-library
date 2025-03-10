/// Authentication module for FreshFarmily apps
/// Contains all authentication related exports

// Services
export 'services/auth_service.dart';
export 'services/api_service.dart';

// Screens
export 'screens/login_screen.dart';
export 'screens/register_screen.dart';
export 'screens/forgot_password_screen.dart';
export 'screens/reset_password_screen.dart';
export 'screens/email_verification_screen.dart';
// Prevent duplicate StringExtension by only exporting one instance
// We need to choose either profile or register, not both
export 'screens/profile_screen.dart' hide StringExtension;
export 'screens/change_password_screen.dart';
export 'screens/onboarding_screen.dart';

// Widgets
export 'widgets/loading_overlay.dart';
export 'widgets/fresh_button.dart';
export 'widgets/fresh_textfield.dart';
export 'widgets/fresh_dropdown.dart';

// Configuration
export 'config.dart';

// Utilities
export 'utils/logging_utils.dart';
export 'utils/cache_manager.dart';

// Models
export 'models/onboarding_model.dart';
