import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import '../bloc/converter_state.dart';

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

  /// Signals whether to show the primary convert button.
  final bool showConvertButton;

  /// Signals whether to hide the outer card container background and border.
  final bool hideContainerBackground;

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
    this.showConvertButton = true,
    this.hideContainerBackground = false,
  });

  /// Opens the native directory chooser to select output folders.
  Future<void> _selectDirectory(BuildContext context) async {
    if (isConverting) return;
    try {
      final selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory != null && context.mounted) {
        context.read<ConverterBloc>().add(ChangeSavePathEvent(selectedDirectory));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final formats = AppConstants.formatsByCategory[activeTool] ?? [];
    final isAndroid = !kIsWeb && Platform.isAndroid;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.settings_outlined, size: 20, color: AppTheme.primaryLight(context)),
            const SizedBox(width: 8),
            Text(
              localizations.globalSettings,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Target Format selector
        Text(
          localizations.targetFormat,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: formats.map((format) {
              final isSelected = targetFormat.toLowerCase() == format.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(format.toUpperCase()),
                  selected: isSelected,
                  selectedColor: AppTheme.primary(context).withValues(alpha: 0.15),
                  backgroundColor: AppTheme.surface(context),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryLight(context) : const Color(0xFFA1A1AA),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary(context).withValues(alpha: 0.5) : AppTheme.border(context),
                    ),
                  ),
                  onSelected: isConverting
                      ? null
                      : (selected) {
                          if (selected) {
                            context.read<ConverterBloc>().add(ChangeTargetFormatEvent(format));
                          }
                        },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (!isAndroid) ...[
          // Save location input
          Text(
            localizations.saveLocation,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Text(
                    savePath.isEmpty ? '/' : savePath,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppTheme.onSurfaceVariant(context),
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
                  backgroundColor: AppTheme.surfaceContainerLow(context),
                  foregroundColor: AppTheme.primary(context),
                  elevation: 0,
                  side: BorderSide(color: AppTheme.border(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
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
              style: TextStyle(
                color: AppTheme.primaryLight(context),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary(context),
            inactiveTrackColor: AppTheme.border(context),
            thumbColor: AppTheme.primary(context),
            overlayColor: AppTheme.primary(context).withValues(alpha: 0.12),
            valueIndicatorColor: AppTheme.primary(context),
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
        if (showConvertButton && queueLength > 1) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined, size: 20, color: AppTheme.primaryLight(context)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              localizations.packageInZip,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurface(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              localizations.packageInZipDesc,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.onSurfaceVariant(context),
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
                  activeThumbColor: AppTheme.primary(context),
                ),
              ],
            ),
          ),
        ],
        // Collapsible Advanced Settings
        if (queueLength > 0) ...[
          const SizedBox(height: 12),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                localizations.advancedSettings,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface(context),
                ),
              ),
              leading: Icon(Icons.tune, size: 18, color: AppTheme.primaryLight(context)),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              tilePadding: EdgeInsets.zero,
              children: [
                // Keep original files switch
                BlocBuilder<ConverterBloc, ConverterState>(
                  builder: (context, state) {
                    return SwitchListTile(
                      title: Text(
                        localizations.keepOriginalFiles,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        localizations.localeName == 'es' 
                          ? 'No eliminar los archivos de origen tras convertirlos'
                          : "Do not delete source files after conversion",
                        style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant(context)),
                      ),
                      contentPadding: EdgeInsets.zero,
                      value: state.keepOriginalFiles,
                      onChanged: isConverting
                          ? null
                          : (val) {
                              context.read<ConverterBloc>().add(ToggleKeepOriginalFilesEvent(val));
                            },
                      activeThumbColor: AppTheme.primary(context),
                    );
                  },
                ),
                // Merge into single file switch
                if (activeTool == 'image' && targetFormat.toLowerCase() == 'pdf' && queueLength > 1)
                  BlocBuilder<ConverterBloc, ConverterState>(
                    builder: (context, state) {
                      return SwitchListTile(
                        title: Text(
                          localizations.mergeIntoSingleFile,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          localizations.mergeIntoSingleFileDesc,
                          style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant(context)),
                        ),
                        contentPadding: EdgeInsets.zero,
                        value: state.mergeIntoSingleFile,
                        onChanged: isConverting
                            ? null
                            : (val) {
                                context.read<ConverterBloc>().add(ToggleMergeIntoSingleFileEvent(val));
                              },
                        activeThumbColor: AppTheme.primary(context),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
        // Action Button
        if (showConvertButton) ...[
          const SizedBox(height: 16),
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
                backgroundColor: AppTheme.primary(context),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: AppTheme.primary(context).withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ],
    );

    if (hideContainerBackground) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: content,
    );
  }
}
