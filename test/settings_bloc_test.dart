import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morph/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:morph/features/settings/presentation/bloc/settings_event.dart';
import 'package:morph/features/settings/presentation/bloc/settings_state.dart';
import 'package:morph/services/settings_storage_service.dart';
import 'package:morph/services/windows_registry_service.dart';

class FakeSettingsStorage extends SettingsStorageService {
  Map<String, dynamic> settings = {};

  @override
  Future<Map<String, dynamic>> readSettings() async {
    return settings;
  }

  @override
  Future<void> writeSettings(Map<String, dynamic> newSettings) async {
    settings = newSettings;
  }
}

class FakeWindowsRegistry extends WindowsRegistryService {
  bool registered = false;

  @override
  Future<bool> isContextMenuRegistered() async {
    return registered;
  }

  @override
  Future<bool> registerContextMenu() async {
    registered = true;
    return true;
  }

  @override
  Future<bool> unregisterContextMenu() async {
    registered = false;
    return true;
  }
}

void main() {
  late FakeSettingsStorage fakeStorage;
  late FakeWindowsRegistry fakeRegistry;
  late SettingsBloc settingsBloc;

  setUp(() {
    fakeStorage = FakeSettingsStorage();
    fakeRegistry = FakeWindowsRegistry();
    settingsBloc = SettingsBloc(
      settingsStorage: fakeStorage,
      windowsRegistry: fakeRegistry,
    );
  });

  tearDown(() {
    settingsBloc.close();
  });

  test('initial state is correct', () {
    expect(settingsBloc.state, SettingsState.initial());
  });

  test('LoadSettingsEvent loaded default values when storage is empty', () async {
    settingsBloc.add(const LoadSettingsEvent());
    await expectLater(
      settingsBloc.stream,
      emits(
        SettingsState.initial().copyWith(
          themeMode: ThemeMode.system,
          languageCode: 'system',
          notificationsEnabled: true,
          windowsMenuEnabled: false,
          isLoaded: true,
        ),
      ),
    );
  });

  test('LoadSettingsEvent loads themeColor correctly from hex string', () async {
    fakeStorage.settings = {
      'themeMode': 'dark',
      'languageCode': 'en',
      'notificationsEnabled': false,
      'themeColor': '#007A87',
    };

    settingsBloc.add(const LoadSettingsEvent());

    await expectLater(
      settingsBloc.stream,
      emits(
        const SettingsState(
          themeMode: ThemeMode.dark,
          languageCode: 'en',
          notificationsEnabled: false,
          windowsMenuEnabled: false,
          themeColor: Color(0xFF007A87),
          isLoaded: true,
        ),
      ),
    );
  });

  test('UpdateThemeColorEvent updates state and persists hex string to storage', () async {
    // 1. Initial load
    settingsBloc.add(const LoadSettingsEvent());
    await settingsBloc.stream.first;

    // 2. Dispatch update theme color event
    const newColor = Color(0xFFE11D48); // Rose
    settingsBloc.add(const UpdateThemeColorEvent(newColor));

    await expectLater(
      settingsBloc.stream,
      emits(
        SettingsState.initial().copyWith(
          themeColor: newColor,
          isLoaded: true,
        ),
      ),
    );

    // Verify storage has the updated key
    expect(fakeStorage.settings['themeColor'], '#E11D48');
  });
}
