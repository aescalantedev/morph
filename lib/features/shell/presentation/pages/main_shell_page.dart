import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/presentation/widgets/unified_desktop_header.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../../settings/presentation/bloc/settings_event.dart';

/// The primary shell page that provides a responsive layout for the application.
///
/// Features a standard Material 3 [NavigationRail] on desktop/tablet screens (collapsing
/// to icon-only on tablets) and a [BottomNavigationBar] on mobile screens. Uses
/// [StatefulNavigationShell] to switch between sections without losing state.
class MainShellPage extends StatefulWidget {
  /// Navigation shell that manages nested routing branches.
  final StatefulNavigationShell navigationShell;

  /// Creates a [MainShellPage] containing the responsive shell.
  const MainShellPage({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  bool? _isSidebarExtended;

  /// Builds the custom minimalist sidebar for desktop/tablet layouts.
  Widget _buildCustomSidebar(BuildContext context, bool isExtended, AppLocalizations localizations) {
    final menuItems = [
      {'name': localizations.dashboard, 'icon': Icons.grid_view_outlined, 'selectedIcon': Icons.grid_view},
      {'name': localizations.convert, 'icon': Icons.sync_outlined, 'selectedIcon': Icons.sync},
      {'name': localizations.history, 'icon': Icons.history_outlined, 'selectedIcon': Icons.history},
      {'name': localizations.settings, 'icon': Icons.settings_outlined, 'selectedIcon': Icons.settings},
    ];

    final double width = isExtended ? 240 : 80;

    return Container(
      width: width,
      height: double.infinity,
      color: AppTheme.surface(context),
      child: Column(
        children: [
          // Logo & Title at the top of the sidebar
          if (isExtended) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  // Logo Block
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primary(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'M',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // App Title
                  Text(
                    localizations.appTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface(context),
                      fontFamily: 'Inter',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primary(context),
                    borderRadius: BorderRadius.circular(8),
                    ),
                  alignment: Alignment.center,
                  child: const Text(
                    'M',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          Divider(color: AppTheme.border(context).withValues(alpha: 0.5), height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 16),

          // Menu Items
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = widget.navigationShell.currentIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.navigationShell.goBranch(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isExtended ? 16 : 0,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary(context).withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isExtended
                            ? Row(
                                children: [
                                  Icon(
                                    isSelected ? item['selectedIcon'] as IconData : item['icon'] as IconData,
                                    color: isSelected ? AppTheme.primary(context) : AppTheme.onSurfaceVariant(context),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    item['name'] as String,
                                    style: TextStyle(
                                      color: isSelected ? AppTheme.primary(context) : AppTheme.onSurfaceVariant(context),
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      fontSize: 13,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Icon(
                                  isSelected ? item['selectedIcon'] as IconData : item['icon'] as IconData,
                                  color: isSelected ? AppTheme.primary(context) : AppTheme.onSurfaceVariant(context),
                                  size: 20,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Help & Support section
          if (isExtended) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 24),
              child: Row(
                children: [
                  Icon(Icons.help_outline, size: 16, color: AppTheme.onSurfaceVariant(context)),
                  const SizedBox(width: 10),
                  Text(
                    'Soporte & Ayuda',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant(context),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Icon(Icons.help_outline, size: 18, color: AppTheme.onSurfaceVariant(context)),
            ),
          ],

          // Theme Toggle at bottom of sidebar (Brainwave style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, settingsState) {
                final isDark = settingsState.themeMode == ThemeMode.dark ||
                    (settingsState.themeMode == ThemeMode.system &&
                        MediaQuery.platformBrightnessOf(context) == Brightness.dark);

                if (isExtended) {
                  // Expanded mode: pill switch
                  return Container(
                    height: 38,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Row(
                      children: [
                        // Light Mode Option
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.read<SettingsBloc>().add(const UpdateThemeModeEvent(ThemeMode.light));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: !isDark
                                    ? AppTheme.surface(context)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: !isDark
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.light_mode_outlined,
                                    size: 15,
                                    color: !isDark
                                        ? AppTheme.primary(context)
                                        : AppTheme.onSurfaceVariant(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Claro',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: !isDark ? FontWeight.w600 : FontWeight.normal,
                                      color: !isDark
                                          ? AppTheme.primary(context)
                                          : AppTheme.onSurfaceVariant(context),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Dark Mode Option
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.read<SettingsBloc>().add(const UpdateThemeModeEvent(ThemeMode.dark));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.surface(context)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isDark
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.dark_mode_outlined,
                                    size: 15,
                                    color: isDark
                                        ? AppTheme.primaryLight(context)
                                        : AppTheme.onSurfaceVariant(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Oscuro',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isDark ? FontWeight.w600 : FontWeight.normal,
                                      color: isDark
                                          ? AppTheme.primaryLight(context)
                                          : AppTheme.onSurfaceVariant(context),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Collapsed mode: single circular toggle button
                  return InkWell(
                    onTap: () {
                      final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
                      context.read<SettingsBloc>().add(UpdateThemeModeEvent(nextMode));
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Icon(
                        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        size: 18,
                        color: AppTheme.onSurfaceVariant(context),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDesktopPlatform = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTabletOrDesktop = constraints.maxWidth >= 640;

          if (isTabletOrDesktop) {
            final defaultExtended = constraints.maxWidth >= 950;
            final isExtended = _isSidebarExtended ?? defaultExtended;

            // Desktop & Tablet NavigationRail Layout (Sidebar starts at top y=0)
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: [
                    _buildCustomSidebar(context, isExtended, localizations),
                    VerticalDivider(thickness: 1, width: 1, color: AppTheme.border(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UnifiedDesktopHeader(
                            title: widget.navigationShell.currentIndex == 0
                                ? localizations.dashboard
                                : (widget.navigationShell.currentIndex == 1
                                    ? localizations.newConversion
                                    : (widget.navigationShell.currentIndex == 2
                                        ? localizations.history
                                        : localizations.settings)),
                          ),
                          Expanded(
                            child: widget.navigationShell,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: isExtended ? 240 - 14 : 80 - 14,
                  top: 18,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSidebarExtended = !isExtended;
                        });
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.surface(context),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border(context)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Icon(
                          isExtended ? Icons.chevron_left : Icons.chevron_right,
                          size: 16,
                          color: AppTheme.onSurface(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile layout with header and Bottom Navigation Bar
            final bool showDesktopHeader = isDesktopPlatform;
            return Scaffold(
              appBar: showDesktopHeader
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(40),
                      child: UnifiedDesktopHeader(
                        title: widget.navigationShell.currentIndex == 0
                            ? localizations.dashboard
                            : (widget.navigationShell.currentIndex == 1
                                ? localizations.newConversion
                                : (widget.navigationShell.currentIndex == 2
                                    ? localizations.history
                                    : localizations.settings)),
                      ),
                    )
                  : AppBar(
                      title: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primary(context),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'M',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(localizations.appTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      actions: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_none),
                        ),
                        const SizedBox(width: 8),
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(1),
                        child: Divider(color: AppTheme.border(context), height: 1),
                      ),
                    ),
              body: widget.navigationShell,
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: widget.navigationShell.currentIndex,
                onTap: (index) {
                  widget.navigationShell.goBranch(index);
                },
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.grid_view_outlined),
                    label: localizations.dashboard,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.sync_outlined),
                    label: localizations.convert,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.history_outlined),
                    label: localizations.history,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings_outlined),
                    label: localizations.settings,
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
