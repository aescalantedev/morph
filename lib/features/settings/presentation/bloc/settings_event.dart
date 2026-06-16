import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Base class for all events handled by the [SettingsBloc].
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event dispatched to load saved settings from local storage.
class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

/// Event dispatched to change the application visual theme mode.
class UpdateThemeModeEvent extends SettingsEvent {
  /// The target theme mode.
  final ThemeMode themeMode;

  /// Creates an [UpdateThemeModeEvent] with the given [themeMode].
  const UpdateThemeModeEvent(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

/// Event dispatched to change the application locale/language.
class UpdateLanguageEvent extends SettingsEvent {
  /// The target language code (e.g. 'es', 'en', 'system').
  final String languageCode;

  /// Creates an [UpdateLanguageEvent] with the given [languageCode].
  const UpdateLanguageEvent(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

/// Event dispatched to toggle background/completion notifications.
class ToggleNotificationsEvent extends SettingsEvent {
  /// Whether desktop/system notifications should be enabled.
  final bool enabled;

  /// Creates a [ToggleNotificationsEvent] with the given [enabled] status.
  const ToggleNotificationsEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event dispatched to toggle Windows Right-Click Explorer Context Menu integration.
class ToggleWindowsMenuEvent extends SettingsEvent {
  /// Whether context menu integration should be active.
  final bool enabled;

  /// Creates a [ToggleWindowsMenuEvent] with the given [enabled] status.
  const ToggleWindowsMenuEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event dispatched to change the application visual theme seed color.
class UpdateThemeColorEvent extends SettingsEvent {
  /// The target seed color.
  final Color themeColor;

  /// Creates an [UpdateThemeColorEvent] with the given [themeColor].
  const UpdateThemeColorEvent(this.themeColor);

  @override
  List<Object?> get props => [themeColor];
}
