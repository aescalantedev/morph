import 'package:flutter/material.dart';

/// The central theme configurations for the Morph application.
///
/// Implements the "Pro-Convert System" design system, an efficient, precise,
/// and reliable corporate Material 3 light theme. Anchored by a Deep Indigo
/// primary color and a Teal secondary color, featuring clear boundaries,
/// systematic feedback, and structured typography.
class AppTheme {
  AppTheme._();

  /// Background color for layouts (Level 0: #FAF9F9).
  static const Color background = Color(0xFFFAF9F9);

  /// Canvas background color.
  static const Color canvas = Color(0xFFFAF9F9);

  /// Primary surface color for standard modules.
  static const Color surface = Color(0xFFFAF9F9);

  /// Tonal layer: Dimmed surface (#DADADA).
  static const Color surfaceDim = Color(0xFFDADADA);

  /// Tonal layer: Lowest container elevation (#FFFFFF).
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  /// Tonal layer: Low container elevation (#F4F3F3).
  static const Color surfaceContainerLow = Color(0xFFF4F3F3);

  /// Tonal layer: Standard container elevation (#EFEEED).
  static const Color surfaceContainer = Color(0xFFEFEEED);

  /// Tonal layer: High container elevation (#E9E8E8).
  static const Color surfaceContainerHigh = Color(0xFFE9E8E8);

  /// Tonal layer: Highest container elevation (#E3E2E2).
  static const Color surfaceContainerHighest = Color(0xFFE3E2E2);

  /// Default text color on surface (#1A1C1C).
  static const Color onSurface = Color(0xFF1A1C1C);

  /// Muted text color on surface (#454652).
  static const Color onSurfaceVariant = Color(0xFF454652);

  /// The standard border color (outline-variant: #C5C5D4).
  static const Color border = Color(0xFFC5C5D4);

  /// The outline color for high-contrast borders (#757684).
  static const Color outline = Color(0xFF757684);

  /// The accent primary color (Deep Indigo: #24389C).
  static const Color primary = Color(0xFF24389C);

  /// Lighter variant of primary color, mapped to primaryContainer (#3F51B5).
  static const Color primaryLight = Color(0xFF3F51B5);

  /// Text/icon color on primary elements (#FFFFFF).
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// The primary container color (Indigo: #3F51B5).
  static const Color primaryContainer = Color(0xFF3F51B5);

  /// Text/icon color on primary container elements (#CACFFF).
  static const Color onPrimaryContainer = Color(0xFFCACFFF);

  /// The secondary color (Teal: #006876).
  static const Color secondary = Color(0xFF006876);

  /// Text/icon color on secondary elements (#FFFFFF).
  static const Color onSecondary = Color(0xFFFFFFFF);

  /// The secondary container color (Cyan: #58E6FF).
  static const Color secondaryContainer = Color(0xFF58E6FF);

  /// Text/icon color on secondary container elements (#006573).
  static const Color onSecondaryContainer = Color(0xFF006573);

  /// Color used for indicating successful operations (Teal/Secondary: #006876).
  static const Color success = Color(0xFF006876);

  /// Color used for indicating failure/errors (Red: #BA1A1A).
  static const Color error = Color(0xFFBA1A1A);

  /// Color used for indicating warnings (Amber: #F59E0B).
  static const Color warning = Color(0xFFF59E0B);

  /// Color used for informational prompts (Cyan/Blue: #006876).
  static const Color info = Color(0xFF3F51B5);

  /// Generates the Light ThemeData config for the application.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: canvas,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        error: error,
        onError: onPrimary,
        surface: surface,
        onSurface: onSurface,
        outline: border,
        shadow: Color(0x1F000000),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
          fontFamily: 'Inter',
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: background,
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(color: primary, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        unselectedLabelTextStyle: TextStyle(color: onSurfaceVariant, fontFamily: 'Inter'),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: onSurface,
          fontSize: 22,
          fontFamily: 'Inter',
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
          color: onSurface,
          fontSize: 16,
          fontFamily: 'Inter',
        ),
        bodyLarge: TextStyle(
          color: onSurface,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        bodyMedium: TextStyle(
          color: onSurfaceVariant,
          fontSize: 13,
          fontFamily: 'Inter',
        ),
        labelSmall: TextStyle(
          color: outline,
          fontSize: 11,
          fontFamily: 'JetBrains Mono',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
