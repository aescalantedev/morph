import 'dart:math';
import 'package:flutter/material.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/media_file.dart';

/// A card widget representing a single media file in the conversion queue.
///
/// Shows file details (name, size, type icon), current conversion status badge,
/// and a progress bar while active. Allows removing the file from the list.
class FileCard extends StatelessWidget {
  /// The media file details.
  final MediaFile file;

  /// Signals if a global conversion process is active.
  final bool isConverting;

  /// Callback when the close/remove button is pressed.
  final VoidCallback onRemove;

  /// Callback when the target format is modified.
  final ValueChanged<String>? onTargetFormatChanged;

  /// Creates a [FileCard] widget.
  const FileCard({
    super.key,
    required this.file,
    required this.isConverting,
    required this.onRemove,
    this.onTargetFormatChanged,
  });

  /// Formats byte size into readable string units (e.g. '3.5 MB').
  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    final i = (log(bytes) / log(1024)).floor().clamp(0, suffixes.length - 1);
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Builds a widget displaying the conversion progress status badge.
  Widget _buildStatusBadge(BuildContext context, AppLocalizations localizations) {
    switch (file.status) {
      case ConversionStatus.idle:
        return const SizedBox.shrink();
      case ConversionStatus.processing:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primary(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary(context).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary(context)),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                localizations.processing,
                style: TextStyle(
                  color: AppTheme.primaryLight(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case ConversionStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.success(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.success(context).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 14,
                color: AppTheme.success(context),
              ),
              const SizedBox(width: 4),
              Text(
                localizations.completed,
                style: TextStyle(
                  color: AppTheme.success(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case ConversionStatus.failed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.error(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.error(context).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error,
                size: 14,
                color: AppTheme.error(context),
              ),
              const SizedBox(width: 4),
              Text(
                localizations.failed,
                style: TextStyle(
                  color: AppTheme.error(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    IconData fileIcon = Icons.insert_drive_file_outlined;
    if (file.category == 'image') {
      fileIcon = Icons.image_outlined;
    } else if (file.category == 'video') {
      fileIcon = Icons.videocam_outlined;
    } else if (file.category == 'audio') {
      fileIcon = Icons.volume_up_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // File Type Icon Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.border(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    fileIcon,
                    color: AppTheme.primaryLight(context),
                  ),
                ),
                const SizedBox(width: 16),
                // File Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatBytes(file.sizeBytes),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Format Selector Dropdown
                if (file.status == ConversionStatus.idle && !isConverting) ...[
                  _buildFormatDropdown(context),
                  const SizedBox(width: 12),
                ],
                // Status Badge
                _buildStatusBadge(context, localizations),
                const SizedBox(width: 12),
                // Action/Remove Button
                if (!isConverting && file.status != ConversionStatus.processing)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close, size: 18),
                    color: const Color(0xFFA1A1AA),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
              ],
            ),
          ),
          // Progress Bar for processing state
          if (file.status == ConversionStatus.processing)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: file.progress,
                  backgroundColor: AppTheme.border(context),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary(context)),
                  minHeight: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormatDropdown(BuildContext context) {
    final formats = (AppConstants.formatsByCategory[file.category] ?? [])
        .where((format) => format.toLowerCase() != file.extension.toLowerCase())
        .toList();
    if (formats.isEmpty || onTargetFormatChanged == null) return const SizedBox.shrink();

    final currentTarget = file.targetFormat.toLowerCase();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'a ',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.onSurfaceVariant(context),
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(width: 4),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: formats.contains(currentTarget) ? currentTarget : formats.first,
              items: formats.map((format) {
                return DropdownMenuItem<String>(
                  value: format.toLowerCase(),
                  child: Text(
                    format.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight(context),
                      fontFamily: 'Inter',
                    ),
                  ),
                );
              }).toList(),
              onChanged: isConverting || file.status == ConversionStatus.processing
                  ? null
                  : (val) {
                      if (val != null) {
                        onTargetFormatChanged!(val);
                      }
                    },
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: AppTheme.onSurfaceVariant(context),
              ),
              dropdownColor: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(12),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
