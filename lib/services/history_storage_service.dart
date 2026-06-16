import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../features/converter/domain/entities/media_file.dart';

/// A service that handles persistence of media conversion history.
///
/// Saves and loads a list of [MediaFile] objects to/from a local JSON file
/// inside the application documents directory.
class HistoryStorageService {
  /// File name used for history persistence.
  static const String _fileName = 'conversion_history.json';

  /// Returns the local file instance where conversion history is stored.
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  /// Reads conversion history from the local storage file.
  ///
  /// Returns a list of [MediaFile] items. If the file does not exist
  /// or cannot be parsed, returns an empty list.
  Future<List<MediaFile>> readHistory() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents) as List<dynamic>;
        return jsonList
            .map((item) => MediaFile.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Return empty history on error
    }
    return [];
  }

  /// Writes conversion history to the local storage file.
  Future<void> writeHistory(List<MediaFile> history) async {
    try {
      final file = await _localFile;
      final jsonList = history.map((item) => item.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (_) {
      // Ignore write errors to guarantee no app crash
    }
  }
}
