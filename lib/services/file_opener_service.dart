import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';

/// A service that handles launching files or revealing them in the system's file manager.
class FileOpenerService {
  /// Opens a file using the default system handler.
  Future<void> openFile(String filePath) async {
    try {
      if (kIsWeb) {
        debugPrint('Cannot open file on Web: $filePath');
        return;
      }
      final file = File(filePath);
      if (await file.exists()) {
        await OpenFilex.open(filePath);
      } else {
        debugPrint('File does not exist: $filePath');
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  /// Opens the directory containing [filePath] and highlights the file if possible.
  Future<void> openFolder(String filePath) async {
    try {
      if (kIsWeb) return;

      final file = File(filePath);
      final bool isFile = await file.exists();
      final String absolutePath = isFile ? file.absolute.path : filePath;

      if (Platform.isWindows) {
        // Runs explorer.exe with /select to highlight the file
        if (isFile) {
          await Process.run('explorer.exe', ['/select,', absolutePath]);
        } else {
          await Process.run('explorer.exe', [absolutePath]);
        }
      } else if (Platform.isMacOS) {
        // Runs open with -R to reveal in Finder
        if (isFile) {
          await Process.run('open', ['-R', absolutePath]);
        } else {
          await Process.run('open', [absolutePath]);
        }
      } else if (Platform.isLinux) {
        // Standard Linux xdg-open. It doesn't support highlighting a file,
        // so we open the directory of the file.
        final String dirPath = isFile ? File(absolutePath).parent.path : absolutePath;
        await Process.run('xdg-open', [dirPath]);
      } else if (Platform.isAndroid || Platform.isIOS) {
        // For mobile, we open the file directory using OpenFilex
        final String dirPath = isFile ? File(absolutePath).parent.path : absolutePath;
        await OpenFilex.open(dirPath);
      }
    } catch (e) {
      debugPrint('Error opening folder: $e');
    }
  }
}
