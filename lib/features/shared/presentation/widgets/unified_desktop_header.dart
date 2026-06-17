import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shell/presentation/widgets/custom_title_bar.dart';

/// A unified, compact header component for desktop layouts.
///
/// Serves as the window title bar (draggable) and displays the active page title
/// on the left and window controls (minimize, maximize, close) on Windows/Linux.
class UnifiedDesktopHeader extends StatelessWidget {
  /// The title text to display on the left.
  final String title;

  /// Creates a [UnifiedDesktopHeader].
  const UnifiedDesktopHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktopPlatform = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    final isWindowsOrLinux = !kIsWeb && (Platform.isWindows || Platform.isLinux);
    final onSurface = AppTheme.onSurface(context);
    final border = AppTheme.border(context);

    // Left side: Page Title
    final titleWidget = Container(
      padding: const EdgeInsets.only(left: 24),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              color: onSurface,
              letterSpacing: -0.2,
            ),
      ),
    );

    // Right side: Window controls
    final controlsWidget = isWindowsOrLinux 
        ? const WindowControls() 
        : const SizedBox(width: 24);

    return Container(
      height: 40, // Very compact height
      decoration: BoxDecoration(
        color: AppTheme.background(context),
        border: Border(
          bottom: BorderSide(
            color: border.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // Draggable area containing the title
          Expanded(
            child: isDesktopPlatform
                ? DragToMoveArea(
                    child: Container(
                      color: Colors.transparent, // required to capture mouse events on full area
                      child: titleWidget,
                    ),
                  )
                : titleWidget,
          ),
          // Controls area (not draggable so click/hover work)
          controlsWidget,
        ],
      ),
    );
  }
}
