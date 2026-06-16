import 'package:flutter/material.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../converter/domain/entities/media_file.dart';

/// A table widget displaying recent media conversion activities.
///
/// Presents a list of recent conversions with status badges and format changes,
/// styled with the light Pro-Convert System M3 specifications.
class ActivityTable extends StatelessWidget {
  /// The list of recent conversion files to display.
  final List<MediaFile> history;

  /// Callback when "View All" is tapped.
  final VoidCallback onViewAll;

  /// Creates an [ActivityTable] widget.
  const ActivityTable({
    super.key,
    required this.history,
    required this.onViewAll,
  });

  /// Builds a status badge indicating the conversion state.
  Widget _buildStatusBadge(BuildContext context, ConversionStatus status, AppLocalizations localizations) {
    Color color = AppTheme.primary(context);
    String text = localizations.processing;
    IconData icon = Icons.sync;

    if (status == ConversionStatus.completed) {
      color = AppTheme.success(context);
      text = localizations.completed;
      icon = Icons.check_circle;
    } else if (status == ConversionStatus.failed) {
      color = AppTheme.error(context);
      text = localizations.failed;
      icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.recentActivity,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: AppTheme.onSurface(context),
                      ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    localizations.viewAll,
                    style: TextStyle(
                      color: AppTheme.primary(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppTheme.surfaceContainerLow(context), height: 1),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 40, top: 40),
              child: Center(
                child: Text(
                  'No hay actividad reciente',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant(context),
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length.clamp(0, 5),
              separatorBuilder: (context, index) => Divider(color: AppTheme.surfaceContainerLow(context), height: 1),
              itemBuilder: (context, index) {
                final item = history[index];
                IconData itemIcon = Icons.insert_drive_file_outlined;
                if (item.category == 'image') {
                  itemIcon = Icons.image_outlined;
                } else if (item.category == 'video') {
                  itemIcon = Icons.videocam_outlined;
                } else if (item.category == 'audio') {
                  itemIcon = Icons.volume_up_outlined;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Icon(itemIcon, color: AppTheme.onSurfaceVariant(context), size: 20),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurface(context),
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Format badge (FROM -> TO)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow(context),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.extension,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontFamily: 'JetBrains Mono',
                                  color: AppTheme.onSurfaceVariant(context),
                                ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_right_alt, size: 10, color: AppTheme.outline(context)),
                            const SizedBox(width: 4),
                            Text(
                              item.targetFormat.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontFamily: 'JetBrains Mono',
                                color: AppTheme.primary(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      _buildStatusBadge(context, item.status, localizations),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
