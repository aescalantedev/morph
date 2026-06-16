import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// A reusable, minimalist header component for desktop layouts.
///
/// Displays the active page title on the left and a user profile/action
/// widget on the right.
class DesktopHeader extends StatelessWidget {
  /// The title text to display on the left.
  final String title;

  /// Optional trailing widget. If null, displays a styled profile circle.
  final Widget? trailing;

  /// Creates a [DesktopHeader].
  const DesktopHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56, // Modern, compact height (M3 AppBar standard)
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.background(context),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.border(context).withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  color: AppTheme.onSurface(context),
                  letterSpacing: -0.2,
                ),
          ),
          trailing ??
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    // Action when clicking profile (could navigate to settings, etc.)
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://api.dicebear.com/7.x/notionists/svg?seed=Felix&backgroundColor=6366f1',
                      width: 30,
                      height: 30,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 30,
                        height: 30,
                        color: AppTheme.primary(context),
                        alignment: Alignment.center,
                        child: const Text(
                          'U',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
