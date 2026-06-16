import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../converter/presentation/bloc/converter_bloc.dart';
import '../../../converter/presentation/bloc/converter_state.dart';
import '../../../converter/domain/entities/media_file.dart';
import '../widgets/activity_table.dart';
import '../widgets/stats_grid.dart';
import '../widgets/weekly_activity_chart.dart';
import '../../../../core/theme/app_theme.dart';

/// The dashboard page presenting stats, active conversion status, and recent history.
///
/// Displays a high-level summary of the user's conversion statistics and a list
/// of recent activities. Observes changes in [ConverterBloc].
class DashboardPage extends StatelessWidget {
  /// Creates a [DashboardPage] widget.
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ConverterBloc, ConverterState>(
      builder: (context, state) {
        final totalConversions = state.history.length;
        final activeTasksCount = state.queue.where((f) => f.status == ConversionStatus.processing).length;
        final spaceSaved = "142 MB"; // Mock calculated value for styling demo
        final storageUsed = "2.4 GB"; // Mock calculated value for styling demo

        // Generate dynamic mock data for chart that scales with history length
        final dailyConversions = [
          (totalConversions * 0.1).round() + 1,
          (totalConversions * 0.2).round() + 3,
          (totalConversions * 0.15).round() + 2,
          (totalConversions * 0.4).round() + 5,
          (totalConversions * 0.35).round() + 4,
          (totalConversions * 0.6).round() + 7,
          totalConversions + 10,
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final double horizontalPadding = constraints.maxWidth >= 640 ? 24.0 : 16.0;
            final bool isLargeScreen = constraints.maxWidth >= 768;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.dashboardSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'Inter',
                              color: AppTheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 20),
                      StatsGrid(
                        totalConversions: totalConversions,
                        activeTasksCount: activeTasksCount,
                        spaceSaved: spaceSaved,
                        storageUsed: storageUsed,
                      ),
                      const SizedBox(height: 24),
                      if (isLargeScreen)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: SizedBox(
                                height: 350,
                                child: WeeklyActivityChart(dailyConversions: dailyConversions),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 4,
                              child: ActivityTable(
                                history: state.history,
                                onViewAll: () {
                                  context.go('/history');
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            SizedBox(
                              height: 300,
                              child: WeeklyActivityChart(dailyConversions: dailyConversions),
                            ),
                            const SizedBox(height: 24),
                            ActivityTable(
                              history: state.history,
                              onViewAll: () {
                                context.go('/history');
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
