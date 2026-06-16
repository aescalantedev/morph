import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

/// The primary shell page that provides a responsive layout for the application.
///
/// Features a standard Material 3 [NavigationRail] on desktop/tablet screens (collapsing
/// to icon-only on tablets) and a [BottomNavigationBar] on mobile screens. Uses
/// [StatefulNavigationShell] to switch between sections without losing state.
class MainShellPage extends StatelessWidget {
  /// Navigation shell that manages nested routing branches.
  final StatefulNavigationShell navigationShell;

  /// Creates a [MainShellPage] containing the responsive shell.
  const MainShellPage({
    super.key,
    required this.navigationShell,
  });

  /// Builds the [NavigationRail] for large/medium layouts.
  Widget _buildNavigationRail(BuildContext context, bool isExtended, AppLocalizations localizations) {
    final menuItems = [
      {'name': localizations.dashboard, 'icon': Icons.grid_view_outlined, 'selectedIcon': Icons.grid_view},
      {'name': localizations.convert, 'icon': Icons.sync_outlined, 'selectedIcon': Icons.sync},
      {'name': localizations.history, 'icon': Icons.history_outlined, 'selectedIcon': Icons.history},
      {'name': localizations.settings, 'icon': Icons.settings_outlined, 'selectedIcon': Icons.settings},
    ];

    return NavigationRail(
      extended: isExtended,
      minWidth: 72,
      minExtendedWidth: 250,
      backgroundColor: AppTheme.background(context),
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        navigationShell.goBranch(index);
      },
      indicatorColor: AppTheme.primary(context).withValues(alpha: 0.12),
      leading: isExtended
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'M',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'morph',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: AppTheme.onSurface(context)),
                  ),
                  Text(
                    '.dev',
                    style: TextStyle(fontSize: 20, color: AppTheme.onSurfaceVariant(context), fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'M',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
      destinations: menuItems.map((item) {
        return NavigationRailDestination(
          icon: Icon(item['icon'] as IconData),
          selectedIcon: Icon(item['selectedIcon'] as IconData),
          label: Text(item['name'] as String),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTabletOrDesktop = constraints.maxWidth >= 640;

          if (isTabletOrDesktop) {
            final isDesktop = constraints.maxWidth >= 1024;

            // Desktop & Tablet NavigationRail Layout
            return Row(
              children: [
                _buildNavigationRail(context, isDesktop, localizations),
                VerticalDivider(thickness: 1, width: 1, color: AppTheme.border(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Desktop Header
                      Container(
                        height: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: AppTheme.background(context),
                          border: Border(bottom: BorderSide(color: AppTheme.border(context))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              navigationShell.currentIndex == 0
                                  ? localizations.dashboard
                                  : (navigationShell.currentIndex == 1
                                      ? localizations.newConversion
                                      : (navigationShell.currentIndex == 2
                                          ? localizations.history
                                          : localizations.settings)),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            // Profile circle
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                'https://api.dicebear.com/7.x/notionists/svg?seed=Felix&backgroundColor=6366f1',
                                width: 38,
                                height: 38,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 38,
                                  height: 38,
                                  color: AppTheme.primary(context),
                                  alignment: Alignment.center,
                                  child: const Text('U', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: navigationShell,
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Mobile layout with header and Bottom Navigation Bar
            return Scaffold(
              appBar: AppBar(
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
              body: navigationShell,
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: navigationShell.currentIndex,
                onTap: (index) {
                  navigationShell.goBranch(index);
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
