import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';

/// A panel containing configuration controls for target formats, compression quality, and folders.
///
/// Triggers directory pickers and commits parameter updates back to the [ConverterBloc].
class SettingsPanel extends StatelessWidget {
  /// The active tool category ('image', 'video', 'audio').
  final String activeTool;

  /// The currently selected target format.
  final String targetFormat;

  /// The currently selected compression quality percentage (0-100).
  final int quality;

  /// The output directory path where files are written.
  final String savePath;

  /// Signals whether a conversion process is active (disables controls).
  final bool isConverting;

  /// Number of files currently loaded in the queue.
  final int queueLength;

  /// Signals whether multiple converted files should be bundled into a ZIP file.
  final bool shouldZip;

  /// Creates a [SettingsPanel] widget.
  const SettingsPanel({
    super.key,
    required this.activeTool,
    required this.targetFormat,
    required this.quality,
    required this.savePath,
    required this.isConverting,
    required this.queueLength,
    required this.shouldZip,
  });

  /// Opens the native directory chooser to select output folders.
  Future<void> _selectDirectory(BuildContext context) async {
    if (isConverting) return;
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null && context.mounted) {
        context.read<ConverterBloc>().add(ChangeSavePathEvent(selectedDirectory));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final formats = AppConstants.formatsByCategory[activeTool] ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_outlined, size: 20, color: AppTheme.primaryLight),
              const SizedBox(width: 8),
              Text(
                localizations.globalSettings,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Target Format selector
          Text(
            localizations.targetFormat,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: formats.map((format) {
              final isSelected = targetFormat.toLowerCase() == format.toLowerCase();
              return ChoiceChip(
                label: Text(format.toUpperCase()),
                selected: isSelected,
                selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                backgroundColor: AppTheme.surface,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryLight : const Color(0xFFA1A1AA),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.border,
                  ),
                ),
                onSelected: isConverting
                    ? null
                    : (selected) {
                        if (selected) {
                          context.read<ConverterBloc>().add(ChangeTargetFormatEvent(format));
                        }
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          // Save location input
          Text(
            localizations.saveLocation,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    savePath.isEmpty ? '/' : savePath,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppTheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isConverting ? null : () => _selectDirectory(context),
                icon: const Icon(Icons.folder_open_outlined, size: 16),
                label: Text(localizations.browse, style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceContainerLow,
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Quality / Compression slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.qualityCompression,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '$quality%',
                style: const TextStyle(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.border,
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primary.withValues(alpha: 0.12),
              valueIndicatorColor: AppTheme.primary,
              trackHeight: 4,
            ),
            child: Slider(
              value: quality.toDouble(),
              min: 10,
              max: 100,
              divisions: 18,
              onChanged: isConverting
                  ? null
                  : (val) {
                      context.read<ConverterBloc>().add(ChangeQualityEvent(val.toInt()));
                    },
            ),
          ),
          // Zip toggle
          if (queueLength > 1) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.archive_outlined, size: 20, color: AppTheme.primaryLight),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                localizations.packageInZip,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                localizations.packageInZipDesc,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: shouldZip,
                    onChanged: isConverting
                        ? null
                        : (val) {
                            context.read<ConverterBloc>().add(ToggleShouldZipEvent(val));
                          },
                    activeThumbColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 36),
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isConverting || queueLength == 0
                  ? null
                  : () {
                      context.read<ConverterBloc>().add(StartConversionEvent());
                    },
              icon: isConverting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.flash_on, size: 18),
              label: Text(
                isConverting
                    ? localizations.processing
                    : '${localizations.convertAll} ($queueLength)',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
