import 'dart:io';
import 'package:flutter/foundation.dart';

/// A service to integrate Morph with the Windows Explorer right-click context menu.
///
/// Spawns system registry utility `reg.exe` subprocesses to add or remove keys
/// under `HKEY_CURRENT_USER\Software\Classes` (HKCU). This does not require administrator privileges.
class WindowsRegistryService {
  /// Registry key path for file-level context menu integration.
  static const String _registryKey = 'HKCU\\Software\\Classes\\*\\shell\\Convert with Morph';

  /// Checks if the "Convert with Morph" shell integration is currently registered in Windows.
  Future<bool> isContextMenuRegistered() async {
    if (kIsWeb || !Platform.isWindows) return false;
    try {
      final result = await Process.run('reg', [
        'query',
        _registryKey,
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Failed to query Windows registry: $e');
      return false;
    }
  }

  /// Registers the context menu command "Convert with Morph" for all file extensions.
  ///
  /// Automatically extracts the path of the currently running executable to bind it
  /// as the command runner and icon source.
  Future<bool> registerContextMenu() async {
    if (kIsWeb || !Platform.isWindows) return false;
    try {
      final executablePath = Platform.resolvedExecutable;

      // 1. Add context menu item title
      final titleResult = await Process.run('reg', [
        'add', _registryKey,
        '/ve', '/t', 'REG_SZ', '/d', 'Convert with Morph', '/f'
      ]);
      if (titleResult.exitCode != 0) return false;

      // 2. Bind application icon to context menu item
      final iconResult = await Process.run('reg', [
        'add', _registryKey,
        '/v', 'Icon', '/t', 'REG_SZ', '/d', '"$executablePath"', '/f'
      ]);
      if (iconResult.exitCode != 0) return false;

      // 3. Register launch command ("morph.exe" "%1")
      final commandResult = await Process.run('reg', [
        'add', '$_registryKey\\command',
        '/ve', '/t', 'REG_SZ', '/d', '"$executablePath" "%1"', '/f'
      ]);

      return commandResult.exitCode == 0;
    } catch (e) {
      debugPrint('Failed to write to Windows registry: $e');
      return false;
    }
  }

  /// Removes the context menu command "Convert with Morph" from Windows registry.
  Future<bool> unregisterContextMenu() async {
    if (kIsWeb || !Platform.isWindows) return false;
    try {
      final result = await Process.run('reg', [
        'delete', _registryKey,
        '/f',
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Failed to delete from Windows registry: $e');
      return false;
    }
  }
}
