import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// A service that handles persistence of application settings.
///
/// Saves settings (theme mode, notifications enabled status, language code)
/// to a local JSON file inside the application documents directory.
class SettingsStorageService {
  /// File name used for settings persistence.
  static const String _fileName = 'settings_config.json';

  /// Returns the local file instance where settings are stored.
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  /// Reads settings from the local storage file.
  ///
  /// Returns a map of key-value settings. If the file does not exist
  /// or cannot be parsed, returns an empty map.
  Future<Map<String, dynamic>> readSettings() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents) as Map<String, dynamic>;
      }
    } catch (_) {
      // Return empty configuration on error
    }
    return {};
  }

  /// Writes settings map to the local storage file.
  Future<void> writeSettings(Map<String, dynamic> settings) async {
    try {
      final file = await _localFile;
      await file.writeAsString(jsonEncode(settings));
    } catch (_) {
      // Ignore write errors to guarantee no app crash
    }
  }
}
