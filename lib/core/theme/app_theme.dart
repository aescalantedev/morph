import 'package:flutter/material.dart';

/// The central theme configurations for the Morph application.
///
/// Implements standard Material 3 dynamic color scheme derivation.
class AppTheme {
  AppTheme._();

  /// Flag indicating whether dark mode is currently active.
  /// Kept for backward compatibility references.
  static bool isDark = false;

  // --- DYNAMIC COLOR METHODS ---

  /// Layout background color.
  static Color background(BuildContext context) => Theme.of(context).colorScheme.surface;

  /// Canvas background color.
  static Color canvas(BuildContext context) => Theme.of(context).colorScheme.surface;

  /// Primary surface color for standard modules.
  static Color surface(BuildContext context) => Theme.of(context).colorScheme.surfaceContainer;

  /// Tonal layer: Dimmed surface.
  static Color surfaceDim(BuildContext context) => Theme.of(context).colorScheme.surfaceDim;

  /// Tonal layer: Lowest container elevation.
  static Color surfaceContainerLowest(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerLowest;

  /// Tonal layer: Low container elevation.
  static Color surfaceContainerLow(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerLow;

  /// Tonal layer: Standard container elevation.
  static Color surfaceContainer(BuildContext context) => Theme.of(context).colorScheme.surfaceContainer;

  /// Tonal layer: High container elevation.
  static Color surfaceContainerHigh(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHigh;

  /// Tonal layer: Highest container elevation.
  static Color surfaceContainerHighest(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;

  /// Default text color on surface.
  static Color onSurface(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  /// Muted text color on surface.
  static Color onSurfaceVariant(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;

  /// Standard border color.
  static Color border(BuildContext context) => Theme.of(context).colorScheme.outlineVariant;

  /// Outline color for high-contrast borders.
  static Color outline(BuildContext context) => Theme.of(context).colorScheme.outline;

  /// Accent primary color.
  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;

  /// Lighter variant of primary color.
  static Color primaryLight(BuildContext context) => Theme.of(context).colorScheme.primaryContainer;

  /// Text/icon color on primary elements.
  static Color get onPrimary => const Color(0xFFFFFFFF);

  /// Primary container color.
  static Color primaryContainer(BuildContext context) => Theme.of(context).colorScheme.primaryContainer;

  /// Text/icon color on primary container elements.
  static Color onPrimaryContainer(BuildContext context) => Theme.of(context).colorScheme.onPrimaryContainer;

  /// Secondary color.
  static Color secondary(BuildContext context) => Theme.of(context).colorScheme.secondary;

  /// Text/icon color on secondary elements.
  static Color get onSecondary => const Color(0xFFFFFFFF);

  /// Secondary container color.
  static Color secondaryContainer(BuildContext context) => Theme.of(context).colorScheme.secondaryContainer;

  /// Text/icon color on secondary container elements.
  static Color onSecondaryContainer(BuildContext context) => Theme.of(context).colorScheme.onSecondaryContainer;

  /// Color used for indicating successful operations.
  static Color success(BuildContext context) => Theme.of(context).colorScheme.secondary;

  /// Color used for indicating failure/errors.
  static Color error(BuildContext context) => Theme.of(context).colorScheme.error;

  /// Color used for indicating warnings.
  static Color get warning => const Color(0xFFF59E0B);

  /// Color used for informational prompts.
  static Color info(BuildContext context) => Theme.of(context).colorScheme.tertiary;

  /// Generates the Light ThemeData config for the application.
  static ThemeData lightTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          fontFamily: 'Inter',
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'Inter'),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          fontSize: 22,
          fontFamily: 'Inter',
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
          fontSize: 16,
          fontFamily: 'Inter',
        ),
        bodyLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        bodyMedium: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 13,
          fontFamily: 'Inter',
        ),
        labelSmall: TextStyle(
          color: colorScheme.outline,
          fontSize: 11,
          fontFamily: 'JetBrains Mono',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Generates the Dark ThemeData config for the application.
  static ThemeData darkTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      // cardTheme: CardThemeData(
      //   color: colorScheme.surfaceContainerLowest,
      //   elevation: 0,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(16),
      //     side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      //   ),
      // ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          fontFamily: 'Inter',
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'Inter'),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          fontSize: 22,
          fontFamily: 'Inter',
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
          fontSize: 16,
          fontFamily: 'Inter',
        ),
        bodyLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        bodyMedium: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 13,
          fontFamily: 'Inter',
        ),
        labelSmall: TextStyle(
          color: colorScheme.outline,
          fontSize: 11,
          fontFamily: 'JetBrains Mono',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
