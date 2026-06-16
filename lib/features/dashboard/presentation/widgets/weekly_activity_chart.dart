import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// A custom-drawn weekly activity line chart for conversions.
///
/// Uses [CustomPainter] to render a telemetry grid and a smooth bezier curve
/// with a gradient fill under the line, providing high-fidelity visual data.
class WeeklyActivityChart extends StatelessWidget {
  /// Daily conversion counts for the last 7 days (e.g., [4, 7, 3, 12, 5, 8, 14]).
  final List<int> dailyConversions;

  /// Creates a [WeeklyActivityChart] widget.
  const WeeklyActivityChart({
    super.key,
    required this.dailyConversions,
  });

  @override
  Widget build(BuildContext context) {
    // Generate default mock data if empty
    final data = dailyConversions.isEmpty ? [5, 8, 12, 7, 15, 20, 14] : dailyConversions;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RENDIMIENTO SEMANAL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primary(context),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Volumen de Conversión',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary(context).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary(context).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.primary(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Actividad',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary(context),
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _ChartPainter(
                    data: data,
                    primaryColor: AppTheme.primary(context),
                    borderColor: AppTheme.border(context),
                    onSurfaceVariantColor: AppTheme.onSurfaceVariant(context),
                    primaryContainerColor: AppTheme.primaryContainer(context),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<int> data;
  final Color primaryColor;
  final Color borderColor;
  final Color onSurfaceVariantColor;
  final Color primaryContainerColor;

  _ChartPainter({
    required this.data,
    required this.primaryColor,
    required this.borderColor,
    required this.onSurfaceVariantColor,
    required this.primaryContainerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final double paddingLeft = 32.0;
    final double paddingBottom = 24.0;
    final double chartWidth = size.width - paddingLeft;
    final double chartHeight = size.height - paddingBottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Determine max value for scaling
    final int maxVal = data.fold(10, (prev, element) => element > prev ? element : prev);
    final int gridSteps = 4;
    final double yStepVal = maxVal / gridSteps;

    // Draw horizontal grid lines and labels
    for (int i = 0; i <= gridSteps; i++) {
      final double y = chartHeight - (i * (chartHeight / gridSteps));
      final double val = i * yStepVal;

      // Grid line
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: val.toStringAsFixed(0),
          style: TextStyle(
            color: onSurfaceVariantColor,
            fontSize: 10,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Days labels mapping
    final List<String> days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final double xStep = chartWidth / (data.length - 1);

    // Draw vertical labels (Days)
    for (int i = 0; i < data.length; i++) {
      final double x = paddingLeft + (i * xStep);

      final textPainter = TextPainter(
        text: TextSpan(
          text: days[i % days.length],
          style: TextStyle(
            color: onSurfaceVariantColor,
            fontSize: 10,
            fontFamily: 'Inter',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - textPainter.height),
      );
    }

    // Build the bezier curve path
    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final double x = paddingLeft + (i * xStep);
      final double y = chartHeight - ((data[i] / maxVal) * chartHeight);
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    // Draw filling gradient under the path
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, chartHeight);
    fillPath.lineTo(points.first.dx, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.18),
          primaryColor.withValues(alpha: 0.00),
        ],
      ).createShader(Rect.fromLTRB(paddingLeft, 0, size.width, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw the main line path
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Draw data points with glowing effect
    final pointPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];

      // Draw normal points
      if (i < points.length - 1) {
        canvas.drawCircle(pt, 3.5, pointPaint);
      } else {
        // Highlighting the latest point
        canvas.drawCircle(pt, 8, glowPaint);
        canvas.drawCircle(pt, 4.5, pointPaint);

        // Tooltip text
        final tooltipTextPainter = TextPainter(
          text: TextSpan(
            text: '+${data[i]}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final tooltipRect = Rect.fromCenter(
          center: Offset(pt.dx, pt.dy - 18),
          width: tooltipTextPainter.width + 12,
          height: tooltipTextPainter.height + 6,
        );

        final tooltipPaint = Paint()
          ..color = primaryContainerColor
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          RRect.fromRectAndRadius(tooltipRect, const Radius.circular(6)),
          tooltipPaint,
        );

        tooltipTextPainter.paint(
          canvas,
          Offset(tooltipRect.left + 6, tooltipRect.top + 3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.onSurfaceVariantColor != onSurfaceVariantColor ||
      oldDelegate.primaryContainerColor != primaryContainerColor;
}
