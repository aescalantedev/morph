import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A reusable widget that loads the vector SVG logo, dynamically replaces
/// the dark background path color with the active theme's primary color,
/// and renders it.
class AppLogo extends StatefulWidget {
  /// The size (width and height) of the logo.
  final double size;

  /// Optional custom color to use for the logo's background path.
  /// If not specified, defaults to the active theme's primary color.
  final Color? color;

  /// Creates an [AppLogo] widget.
  const AppLogo({
    super.key,
    this.size = 90,
    this.color,
  });

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> {
  static String? _rawSvgContent;
  static bool _isLoading = false;
  static final List<void Function()> _listeners = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  Future<void> _loadSvg() async {
    if (_rawSvgContent != null) {
      // SVG content is already loaded and cached, rebuild to show it
      if (mounted) setState(() {});
      return;
    }

    if (_isLoading) {
      // Another instance is already loading, listen for completion
      _listeners.add(() {
        if (mounted) {
          setState(() {
            if (_rawSvgContent == null) {
              _error = 'Failed to load SVG logo';
            }
          });
        }
      });
      return;
    }

    _isLoading = true;

    try {
      final svg = await rootBundle.loadString('assets/images/logo.svg');
      _rawSvgContent = svg;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      // Notify all listening instances
      final currentListeners = List<void Function()>.from(_listeners);
      _listeners.clear();
      for (final listener in currentListeners) {
        listener();
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_rawSvgContent == null) {
      if (_error != null) {
        // Fallback: simple text logo inside a colored box
        final fallbackColor = widget.color ?? Theme.of(context).colorScheme.primary;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: fallbackColor,
            borderRadius: BorderRadius.circular(widget.size * 28 / 90),
          ),
          child: Center(
            child: Text(
              'M',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: widget.size * 0.5,
              ),
            ),
          ),
        );
      }

      // Placeholder while loading
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: SizedBox(
            width: widget.size * 0.3,
            height: widget.size * 0.3,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Get the target color (defaulting to the primary theme color)
    final targetColor = widget.color ?? Theme.of(context).colorScheme.primary;
    
    // Extract 6-character hex representation of the color
    // ignore: deprecated_member_use
    final hexColor = '#${(targetColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    
    // Dynamically replace the dark background fill color path
    final modifiedSvg = _rawSvgContent!.replaceFirst('fill="#222327"', 'fill="$hexColor"');

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: SvgPicture.string(
        modifiedSvg,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}
