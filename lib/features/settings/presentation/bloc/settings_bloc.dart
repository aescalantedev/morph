import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/settings_storage_service.dart';
import '../../../../services/windows_registry_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// Business Logic Component (BLoC) that manages global application preferences.
///
/// Orchestrates loading settings from local JSON storage and updating/persisting
/// the visual theme mode, notifications toggle, locale selection, theme seed color,
/// and Windows Explorer context menu integration status.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  /// The local settings storage service provider.
  final SettingsStorageService settingsStorage;

  /// The Windows registry integration service provider.
  final WindowsRegistryService windowsRegistry;

  /// Creates a [SettingsBloc] instance.
  SettingsBloc({
    required this.settingsStorage,
    required this.windowsRegistry,
  }) : super(SettingsState.initial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateThemeModeEvent>(_onUpdateThemeMode);
    on<UpdateLanguageEvent>(_onUpdateLanguage);
    on<ToggleNotificationsEvent>(_onToggleNotifications);
    on<ToggleWindowsMenuEvent>(_onToggleWindowsMenu);
    on<UpdateThemeColorEvent>(_onUpdateThemeColor);
  }

  /// Loads persisted configurations from local storage and queries the registry.
  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final settings = await settingsStorage.readSettings();

    // Parse ThemeMode
    ThemeMode themeMode = ThemeMode.system;
    final themeStr = settings['themeMode'] as String?;
    if (themeStr == 'light') {
      themeMode = ThemeMode.light;
    } else if (themeStr == 'dark') {
      themeMode = ThemeMode.dark;
    } else if (themeStr == 'system') {
      themeMode = ThemeMode.system;
    }

    // Parse languageCode
    final languageCode = settings['languageCode'] as String? ?? 'system';

    // Parse notificationsEnabled
    final notificationsEnabled = settings['notificationsEnabled'] as bool? ?? true;

    // Query Windows Registry to check if context menu is active
    final windowsMenuEnabled = await windowsRegistry.isContextMenuRegistered();

    // Parse ThemeColor
    final colorHex = settings['themeColor'] as String? ?? '#24389C';
    Color themeColor = const Color(0xFF24389C);
    try {
      themeColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {}

    emit(state.copyWith(
      themeMode: themeMode,
      languageCode: languageCode,
      notificationsEnabled: notificationsEnabled,
      windowsMenuEnabled: windowsMenuEnabled,
      themeColor: themeColor,
    ));
  }

  /// Updates and persists the theme mode.
  Future<void> _onUpdateThemeMode(
    UpdateThemeModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(themeMode: event.themeMode));
    await _saveToStorage();
  }

  /// Updates and persists the selected language locale.
  Future<void> _onUpdateLanguage(
    UpdateLanguageEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(languageCode: event.languageCode));
    await _saveToStorage();
  }

  /// Updates and persists notifications toggle status.
  Future<void> _onToggleNotifications(
    ToggleNotificationsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(notificationsEnabled: event.enabled));
    await _saveToStorage();
  }

  /// Registers or unregisters context menu in Windows registry.
  Future<void> _onToggleWindowsMenu(
    ToggleWindowsMenuEvent event,
    Emitter<SettingsState> emit,
  ) async {
    bool success = false;
    if (event.enabled) {
      success = await windowsRegistry.registerContextMenu();
    } else {
      success = await windowsRegistry.unregisterContextMenu();
    }

    if (success) {
      emit(state.copyWith(windowsMenuEnabled: event.enabled));
      await _saveToStorage();
    }
  }

  /// Updates and persists the visual theme seed color.
  Future<void> _onUpdateThemeColor(
    UpdateThemeColorEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(themeColor: event.themeColor));
    await _saveToStorage();
  }

  /// Syncs current state back to the storage service file.
  Future<void> _saveToStorage() async {
    String themeStr = 'system';
    if (state.themeMode == ThemeMode.light) {
      themeStr = 'light';
    } else if (state.themeMode == ThemeMode.dark) {
      themeStr = 'dark';
    }

    final themeColorHex = '#${state.themeColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    final data = {
      'themeMode': themeStr,
      'languageCode': state.languageCode,
      'notificationsEnabled': state.notificationsEnabled,
      'windowsMenuEnabled': state.windowsMenuEnabled,
      'themeColor': themeColorHex,
    };
    await settingsStorage.writeSettings(data);
  }
}
