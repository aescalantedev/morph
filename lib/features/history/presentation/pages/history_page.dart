import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../converter/domain/entities/media_file.dart';
import '../../../converter/presentation/bloc/converter_bloc.dart';
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
    Color color = AppTheme.primary;
    String text = localizations.processing;
    IconData icon = Icons.sync;

    if (status == ConversionStatus.completed) {
      color = AppTheme.success;
      text = localizations.completed;
      icon = Icons.check_circle;
    } else if (status == ConversionStatus.failed) {
      color = AppTheme.error;
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
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: history.isEmpty
                      ? const Center(
                          child: Text(
                            'El historial está vacío.',
                            style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          itemCount: history.length,
                          separatorBuilder: (context, index) => const Divider(color: AppTheme.border, height: 1),
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
                                  Icon(itemIcon, color: const Color(0xFFA1A1AA), size: 22),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFFFAFAF9),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.outputPath != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.outputPath!,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF71717A),
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
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.error,
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
                                      color: AppTheme.canvas,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.extension,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontFamily: 'monospace',
                                            color: Color(0xFFA1A1AA),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_right_alt, size: 10, color: Color(0xFF71717A)),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.targetFormat.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontFamily: 'monospace',
                                            color: AppTheme.primaryLight,
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
