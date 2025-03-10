import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// FreshTheme is a unified theme system based on the Pro-Grocery UI kit
/// It provides consistent styling across all three apps (Consumer, Farmer, and Driver)
class FreshTheme {
  // Primary colors for each app
  static const Color consumerPrimary =
      Color(0xFF6A8D73); // Sage green for consumer app
  static const Color farmerPrimary = Color(0xFF4CAF50); // Green for farmer app
  static const Color driverPrimary = Color(0xFF4CAF50); // Green for driver app

  // Secondary colors for each app
  static const Color consumerSecondary =
      Color(0xFFDBC9AD); // Light beige for consumer app
  static const Color farmerSecondary =
      Color(0xFF8BC34A); // Light green for farmer app
  static const Color driverSecondary =
      Color(0xFF8BC34A); // Light green for driver app

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);

  // Common colors
  static const Color primary = Color(0xFF00AD48); // Default primary
  static const Color accent = Color(0xFFFFC107); // Accent color
  static const Color scaffoldBackground = Color(0xFFFFFFFF);
  static const Color scaffoldWithBoxBackground = Color(0xFFF7F7F7);
  static const Color cardColor = Color(0xFFF2F2F2);
  static const Color coloredBackground = Color(0xFFE4F8EA);
  static const Color placeholder = Color(0xFF8B8B97);
  static const Color textInputBackground = Color(0xFFF7F7F7);
  static const Color separator = Color(0xFFFAFAFA);
  static const Color gray = Color(0xFFE1E1E1);

  // Dimensions
  static const double radius = 15;
  static const double margin = 15;
  static const double padding = 15;

  // Border radius
  static BorderRadius borderRadius = BorderRadius.circular(radius);
  static BorderRadius bottomSheetRadius = const BorderRadius.only(
    topLeft: Radius.circular(radius),
    topRight: Radius.circular(radius),
  );
  static BorderRadius topSheetRadius = const BorderRadius.only(
    bottomLeft: Radius.circular(radius),
    bottomRight: Radius.circular(radius),
  );

  // Shadows
  static List<BoxShadow> boxShadow = [
    BoxShadow(
      blurRadius: 10,
      spreadRadius: 0,
      offset: const Offset(0, 2),
      color: Colors.black.withOpacity(0.04),
    ),
  ];

  // Animation durations
  static Duration duration = const Duration(milliseconds: 300);

  // Input decoration
  static InputDecorationTheme _getInputDecorationTheme(Color primaryColor) {
    return InputDecorationTheme(
      fillColor: textInputBackground,
      filled: true,
      contentPadding: const EdgeInsets.all(padding),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: primaryColor, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  /// Get theme for Consumer App
  static ThemeData consumerTheme() {
    return _getBaseTheme(consumerPrimary, consumerSecondary);
  }

  /// Get theme for Farmer App
  static ThemeData farmerTheme() {
    return _getBaseTheme(farmerPrimary, farmerSecondary);
  }

  /// Get theme for Driver App
  static ThemeData driverTheme() {
    return _getBaseTheme(driverPrimary, driverSecondary);
  }

  /// Base theme with color customization
  static ThemeData _getBaseTheme(Color primaryColor, Color secondaryColor) {
    return ThemeData(
      colorSchemeSeed: primaryColor,
      fontFamily: "Gilroy",
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      brightness: Brightness.light,
      appBarTheme: AppBarTheme(
        elevation: 0.3,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontFamily: "Gilroy",
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
        ),
        // New style for AppBar
        centerTitle: true,
        foregroundColor: primaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(padding),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.all(padding),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
          side: BorderSide(color: primaryColor, width: 1),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Gilroy',
          ),
        ),
      ),
      inputDecorationTheme: _getInputDecorationTheme(primaryColor),
      sliderTheme: SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
        thumbColor: Colors.white,
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.3),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondary,
        labelPadding: const EdgeInsets.all(padding),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: textSecondary,
        ),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      dividerTheme: const DividerThemeData(
        color: separator,
        thickness: 1,
        space: 1,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return textSecondary;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
