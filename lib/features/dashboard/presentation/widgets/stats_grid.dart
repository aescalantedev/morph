import 'package:flutter/material.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

/// A grid layout displaying key conversion and system resource metrics.
///
/// Features Material 3 style telemetry cards with glowing sidebars,
/// custom-drawn sparkline indicators, and technical secondary metadata.
class StatsGrid extends StatelessWidget {
  /// The running total count of all converted files.
  final int totalConversions;

  /// The number of files currently undergoing active processing.
  final int activeTasksCount;

  /// Human-readable total space saved (e.g. '142 MB').
  final String spaceSaved;

  /// Human-readable storage space metrics (e.g. '2.4 GB').
  final String storageUsed;

  /// Creates a [StatsGrid] widget.
  const StatsGrid({
    super.key,
    required this.totalConversions,
    required this.activeTasksCount,
    required this.spaceSaved,
    required this.storageUsed,
  });

  /// Helper builder for individual metric card containers.
  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
    required String subtitle,
    required List<double> sparklineValues,
    required String secondaryMetric,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Left color stripe
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: Container(color: color),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.outline,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                fontFamily: 'Inter',
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  fontFamily: 'JetBrains Mono',
                                  color: AppTheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 10,
                                  color: AppTheme.onSurfaceVariant,
                                  fontFamily: 'Inter',
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      // Mini Sparkline
                      SizedBox(
                        width: 70,
                        height: 28,
                        child: CustomPaint(
                          painter: _SparklinePainter(
                            values: sparklineValues,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AppTheme.surfaceContainerLow, height: 1),
                  const SizedBox(height: 8),
                  Text(
                    secondaryMetric,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Dynamically calculate columns based on available width
        final int columns;
        if (width >= 720) {
          columns = 4;
        } else if (width >= 480) {
          columns = 2;
        } else {
          columns = 1;
        }

        // Calculate card width and aspect ratio to enforce a fixed height of 145px
        const double spacing = 16.0;
        final double cardWidth = (width - (spacing * (columns - 1))) / columns;
        const double cardHeight = 145.0;
        final double aspectRatio = cardWidth / cardHeight;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              context: context,
              title: localizations.totalConversions,
              value: totalConversions.toString(),
              icon: Icons.trending_up,
              color: AppTheme.primary,
              bg: AppTheme.primary.withValues(alpha: 0.08),
              subtitle: '+12% esta semana',
              sparklineValues: const [2.0, 4.0, 3.0, 7.0, 5.0, 8.0, 10.0],
              secondaryMetric: 'TASA ÉXITO: 98.4%',
            ),
            _buildStatCard(
              context: context,
              title: localizations.spaceSaved,
              value: spaceSaved,
              icon: Icons.storage_outlined,
              color: AppTheme.secondary,
              bg: AppTheme.secondary.withValues(alpha: 0.08),
              subtitle: 'Vía compresión',
              sparklineValues: const [3.0, 2.0, 4.0, 6.0, 8.0, 7.0, 9.0],
              secondaryMetric: 'COMPRESIÓN: 3.4x',
            ),
            _buildStatCard(
              context: context,
              title: localizations.activeTasks,
              value: activeTasksCount.toString(),
              icon: Icons.sync,
              color: AppTheme.info,
              bg: AppTheme.info.withValues(alpha: 0.08),
              subtitle: activeTasksCount > 0 ? 'Procesando...' : 'Sistema inactivo',
              sparklineValues: [0.0, 1.0, 0.0, 2.0, 1.0, 0.0, activeTasksCount.toDouble()],
              secondaryMetric: activeTasksCount > 0 ? 'COLA: $activeTasksCount ARCHIVOS' : 'COLA: VACÍA',
            ),
            _buildStatCard(
              context: context,
              title: localizations.storage,
              value: storageUsed,
              icon: Icons.cloud_queue,
              color: AppTheme.warning,
              bg: AppTheme.warning.withValues(alpha: 0.08),
              subtitle: 'De 100GB disponibles',
              sparklineValues: const [2.1, 2.2, 2.2, 2.3, 2.3, 2.4, 2.4],
              secondaryMetric: 'USO: 2.4% TOTAL',
            ),
          ],
        );
      },
    );
  }
}

/// A custom painter for the mini sparkline inside the stat cards.
class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double xStep = size.width / (values.length - 1);
    final double maxVal = values.reduce((curr, next) => curr > next ? curr : next);
    final double minVal = values.reduce((curr, next) => curr < next ? curr : next);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    path.moveTo(0, size.height - ((values[0] - minVal) / range * size.height));

    for (int i = 1; i < values.length; i++) {
      path.lineTo(i * xStep, size.height - ((values[i] - minVal) / range * size.height));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
