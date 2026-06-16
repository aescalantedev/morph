import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Represents the state of user settings and preferences.
class SettingsState extends Equatable {
  /// The active visual appearance mode (light, dark, system).
  final ThemeMode themeMode;

  /// The active language configuration ('es', 'en', or 'system').
  final String languageCode;

  /// Indicates if system/completion notifications are active.
  final bool notificationsEnabled;

  /// Indicates if the Windows right-click Explorer context menu is active.
  final bool windowsMenuEnabled;

  /// The seed color used to dynamically generate the Material 3 ColorScheme.
  final Color themeColor;

  /// Creates a [SettingsState] instance.
  const SettingsState({
    required this.themeMode,
    required this.languageCode,
    required this.notificationsEnabled,
    required this.windowsMenuEnabled,
    required this.themeColor,
  });

  /// The initial settings state on application launch.
  factory SettingsState.initial() {
    return const SettingsState(
      themeMode: ThemeMode.system,
      languageCode: 'system',
      notificationsEnabled: true,
      windowsMenuEnabled: false,
      themeColor: Color(0xFF24389C),
    );
  }

  /// Maps the serialized [languageCode] string to a Flutter [Locale] object.
  ///
  /// Returns `null` if [languageCode] is set to 'system', indicating
  /// that Flutter should fall back to the operating system locale.
  Locale? get locale {
    if (languageCode == 'es') {
      return const Locale('es');
    } else if (languageCode == 'en') {
      return const Locale('en');
    }
    return null; // System default
  }

  /// Returns a copy of the current state with optionally overridden values.
  SettingsState copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? notificationsEnabled,
    bool? windowsMenuEnabled,
    Color? themeColor,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      windowsMenuEnabled: windowsMenuEnabled ?? this.windowsMenuEnabled,
      themeColor: themeColor ?? this.themeColor,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        languageCode,
        notificationsEnabled,
        windowsMenuEnabled,
        themeColor,
      ];
}
