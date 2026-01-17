import 'package:flutter/material.dart';

/// macOS Native Theme
///
/// Design principles:
/// - Glassmorphism with blur effects
/// - Subtle borders and shadows
/// - System gray colors for neutral UI
/// - Blue accent for interactive elements
/// - Proper contrast for accessibility
class MacOSTheme {
  MacOSTheme._();

  // ============== System Colors (SF Colors) ==============

  /// System Blue - Primary accent color
  static const Color systemBlue = Color(0xFF007AFF);

  /// System Gray colors
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);

  /// Background colors
  static const Color windowBackground = Color(0xFFFCFCFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFF5F5F7);

  /// Text colors
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF86868B);
  static const Color textTertiary = Color(0xFFAEAEB2);

  /// Border colors
  static const Color borderLight = Color(0xFFE5E5EA);
  static const Color borderMedium = Color(0xFFD1D1D6);

  /// Status colors
  static const Color successGreen = Color(0xFF34C759);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color errorRed = Color(0xFFFF3B30);

  // ============== Blur Effects ==============

  /// Glass effect for floating panels
  static const double glassBlurSigma = 20.0;
  static const double glassOpacity = 0.72;

  // ============== Border Radius ==============

  static const double radiusSmall = 6.0;
  static const double radiusMedium = 10.0;
  static const double radiusLarge = 14.0;

  // ============== Shadows ==============

  static List<BoxShadow> shadowSubtle = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  static List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  static List<BoxShadow> shadowFloating = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  // ============== Typography ==============

  /// Font sizes based on SF Pro typography scale
  static const double fontSizeCaption1 = 11.0;
  static const double fontSizeCaption2 = 12.0;
  static const double fontSizeFootnote = 13.0;
  static const double fontSizeSubheadline = 15.0;
  static const double fontSizeCallout = 16.0;
  static const double fontSizeBody = 17.0;
  static const double fontSizeHeadline = 17.0;
  static const double fontSizeTitle3 = 20.0;
  static const double fontSizeTitle2 = 22.0;
  static const double fontSizeTitle1 = 28.0;
  static const double fontSizeLargeTitle = 34.0;

  /// Font weights
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  // ============== Spacing ==============

  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingL = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 24.0;

  // ============== Light Theme Data ==============

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: systemBlue,
        secondary: systemGray,
        surface: cardBackground,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      // Scaffold background
      scaffoldBackgroundColor: secondaryBackground,

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: fontSizeTitle3,
          fontWeight: weightSemibold,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(
          color: systemBlue,
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(
            color: borderLight,
            width: 0.5,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: systemGray6,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingM,
          vertical: paddingS,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(
            color: borderLight,
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(
            color: systemBlue,
            width: 1.5,
          ),
        ),
        hintStyle: const TextStyle(
          color: textSecondary,
          fontSize: fontSizeBody,
        ),
      ),

      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: systemBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: paddingL,
            vertical: paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeBody,
            fontWeight: weightMedium,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: systemBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: paddingM,
            vertical: paddingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeBody,
            fontWeight: weightMedium,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: systemBlue,
          side: const BorderSide(
            color: systemBlue,
            width: 0.5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: paddingL,
            vertical: paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeBody,
            fontWeight: weightMedium,
          ),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: systemGray,
        size: 20,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeLargeTitle,
          fontWeight: weightBold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeTitle1,
          fontWeight: weightBold,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeTitle2,
          fontWeight: weightSemibold,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: fontSizeTitle3,
          fontWeight: weightSemibold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeHeadline,
          fontWeight: weightSemibold,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeSubheadline,
          fontWeight: weightMedium,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightSemibold,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightMedium,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: fontSizeSubheadline,
          fontWeight: weightMedium,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightRegular,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightRegular,
          color: textPrimary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeFootnote,
          fontWeight: weightRegular,
          color: textSecondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightMedium,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: fontSizeFootnote,
          fontWeight: weightMedium,
          color: textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: fontSizeCaption2,
          fontWeight: weightMedium,
          color: textSecondary,
        ),
      ),

      // Popup menu theme
      popupMenuTheme: PopupMenuThemeData(
        color: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(
            color: borderLight,
            width: 0.5,
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.15),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 0.5,
        space: paddingM,
      ),

      // Snack bar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: fontSizeBody,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        elevation: 8,
      ),
    );
  }

  // ============== Dark Theme Data ==============

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF0A84FF),
        secondary: systemGray2,
        surface: Color(0xFF1C1C1E),
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFFFFFFF),
        onError: Colors.white,
      ),

      // Scaffold background
      scaffoldBackgroundColor: const Color(0xFF000000),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: fontSizeTitle3,
          fontWeight: weightSemibold,
          color: Color(0xFFFFFFFF),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFF0A84FF),
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: const Color(0xFF1C1C1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(
            color: Color(0xFF38383A),
            width: 0.5,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: systemGray2,
        size: 20,
      ),

      // Text theme (same as light but with dark colors)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeLargeTitle,
          fontWeight: weightBold,
          color: Color(0xFFFFFFFF),
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeTitle1,
          fontWeight: weightBold,
          color: Color(0xFFFFFFFF),
          letterSpacing: -0.3,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeTitle2,
          fontWeight: weightSemibold,
          color: Color(0xFFFFFFFF),
        ),
        headlineLarge: TextStyle(
          fontSize: fontSizeTitle3,
          fontWeight: weightSemibold,
          color: Color(0xFFFFFFFF),
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeHeadline,
          fontWeight: weightSemibold,
          color: Color(0xFFFFFFFF),
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeSubheadline,
          fontWeight: weightMedium,
          color: Color(0xFFFFFFFF),
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightSemibold,
          color: Color(0xFFFFFFFF),
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightMedium,
          color: Color(0xFFFFFFFF),
        ),
        titleSmall: TextStyle(
          fontSize: fontSizeSubheadline,
          fontWeight: weightMedium,
          color: Color(0xFFFFFFFF),
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightRegular,
          color: Color(0xFFFFFFFF),
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightRegular,
          color: Color(0xFFFFFFFF),
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeFootnote,
          fontWeight: weightRegular,
          color: systemGray2,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightMedium,
          color: Color(0xFFFFFFFF),
        ),
        labelMedium: TextStyle(
          fontSize: fontSizeFootnote,
          fontWeight: weightMedium,
          color: Color(0xFFFFFFFF),
        ),
        labelSmall: TextStyle(
          fontSize: fontSizeCaption2,
          fontWeight: weightMedium,
          color: systemGray2,
        ),
      ),
    );
  }
}
