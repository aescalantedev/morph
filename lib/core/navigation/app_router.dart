import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/shell/presentation/pages/main_shell_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/converter/presentation/pages/converter_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

/// Global key for the root navigator of the application.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Global path override used to start the app on a specific tab (e.g. '/convert').
String initialLocationOverride = '/dashboard';

/// The declarative routing configuration for the application using GoRouter.
///
/// Implements [StatefulShellRoute.indexedStack] to maintain separate navigation
/// stacks and keep-alive states for the core tabs: Dashboard, Convert, History,
/// and Settings.
final GoRouter appRouter = GoRouter(
  initialLocation: initialLocationOverride,
  navigatorKey: rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/convert',
              builder: (context, state) => const ConverterPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
