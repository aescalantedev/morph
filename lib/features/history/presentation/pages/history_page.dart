import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../converter/domain/entities/media_file.dart';
import '../../../converter/presentation/bloc/converter_bloc.dart';
import '../../../converter/presentation/bloc/converter_event.dart';
import '../../../converter/presentation/bloc/converter_state.dart';
import '../../../../core/theme/app_theme.dart';

/// A page displaying all historical file conversions in the current session.
///
/// Subscribes to the [ConverterBloc] state and displays completed and failed
/// conversions, with source formats, output targets, file locations, and errors.
class HistoryPage extends StatelessWidget {
  /// Creates a [HistoryPage] widget.
  const HistoryPage({super.key});

  /// Builds a status badge representing the outcome of the conversion (completed/failed).
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
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ConverterBloc, ConverterState>(
      builder: (context, state) {
        final history = state.history;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (history.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.recentActivity,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface(context),
                        fontFamily: 'Inter',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        context.read<ConverterBloc>().add(const ClearHistoryEvent());
                      },
                      icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.error(context)),
                      label: Text(
                        localizations.clearHistory,
                        style: TextStyle(color: AppTheme.error(context), fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: history.isEmpty
                      ? Center(
                          child: Text(
                            localizations.historyEmpty,
                            style: TextStyle(color: AppTheme.onSurfaceVariant(context), fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          itemCount: history.length,
                          separatorBuilder: (context, index) => Divider(color: AppTheme.border(context), height: 1),
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
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Row(
                                children: [
                                  Icon(itemIcon, color: AppTheme.onSurfaceVariant(context), size: 22),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.onSurface(context),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.outputPath != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.outputPath!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.onSurfaceVariant(context),
                                              fontFamily: 'monospace',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        if (item.errorMessage != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.errorMessage!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.error(context),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Format badge (FROM -> TO)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.canvas(context),
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
                                            fontFamily: 'monospace',
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
                                            fontFamily: 'monospace',
                                            color: AppTheme.primaryLight(context),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildStatusBadge(context, item.status, localizations),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
