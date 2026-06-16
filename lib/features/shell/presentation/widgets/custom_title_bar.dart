import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/theme/app_theme.dart';

/// A custom dynamic window title bar for desktop platforms.
///
/// Integrates with the [window_manager] package to hide native title borders,
/// support window dragging via [DragToMoveArea], and present custom styled
/// minimize, maximize/restore, and close buttons that adapt to the application theme.
class CustomTitleBar extends StatefulWidget implements PreferredSizeWidget {
  /// Creates a [CustomTitleBar] widget.
  const CustomTitleBar({super.key});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();

  @override
  Size get preferredSize => const Size.fromHeight(40);
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximizedState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkMaximizedState() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (mounted) {
        setState(() {
          _isMaximized = maximized;
        });
      }
    } catch (_) {}
  }

  @override
  void onWindowMaximize() {
    if (mounted) {
      setState(() {
        _isMaximized = true;
      });
    }
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) {
      setState(() {
        _isMaximized = false;
      });
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? hoverColor,
    Color? iconColor,
    Color? iconHoverColor,
  }) {
    return _HoverButton(
      icon: icon,
      onTap: onTap,
      hoverColor: hoverColor,
      iconColor: iconColor,
      iconHoverColor: iconHoverColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only render on desktop platforms
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    if (!isDesktop) return const SizedBox.shrink();

    final onSurface = AppTheme.onSurface(context);
    final border = AppTheme.border(context);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Logo and Title draggable area
          Expanded(
            child: DragToMoveArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                color: Colors.transparent, // Required to capture mouse events on full area
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.primary(context),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'M',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Morph',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Window controls
          Row(
            children: [
              _buildControlButton(
                icon: Icons.remove,
                onTap: () => windowManager.minimize(),
                iconColor: onSurface,
              ),
              _buildControlButton(
                icon: _isMaximized ? Icons.filter_none_outlined : Icons.crop_square_outlined,
                onTap: () async {
                  if (_isMaximized) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
                iconColor: onSurface,
              ),
              _buildControlButton(
                icon: Icons.close,
                onTap: () => windowManager.close(),
                iconColor: onSurface,
                hoverColor: const Color(0xFFE11D48), // Rose red
                iconHoverColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HoverButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? hoverColor;
  final Color? iconColor;
  final Color? iconHoverColor;

  const _HoverButton({
    required this.icon,
    required this.onTap,
    this.hoverColor,
    this.iconColor,
    this.iconHoverColor,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final defaultHoverColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 46,
          height: 40,
          color: _isHovered
              ? (widget.hoverColor ?? defaultHoverColor)
              : Colors.transparent,
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: widget.icon == Icons.remove ? 18 : 16,
            color: _isHovered
                ? (widget.iconHoverColor ?? widget.iconColor)
                : widget.iconColor,
          ),
        ),
      ),
    );
  }
}
