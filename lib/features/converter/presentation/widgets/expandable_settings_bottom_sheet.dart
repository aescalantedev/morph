import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import 'settings_panel.dart';

/// A persistent bottom sheet designed for mobile devices.
///
/// Anchors the primary "Convert All" button at the bottom of the screen, and
/// expands upwards with an animation to reveal the detailed settings controls.
class ExpandableSettingsBottomSheet extends StatefulWidget {
  /// The active tool category ('image', 'video', 'audio').
  final String activeTool;

  /// The currently selected target format.
  final String targetFormat;

  /// The currently selected compression quality percentage (0-100).
  final int quality;

  /// The output directory path where files are written.
  final String savePath;

  /// Signals whether a conversion process is active.
  final bool isConverting;

  /// Number of files currently loaded in the queue.
  final int queueLength;

  /// Signals whether multiple converted files should be bundled into a ZIP file.
  final bool shouldZip;

  /// Creates an [ExpandableSettingsBottomSheet] widget.
  const ExpandableSettingsBottomSheet({
    super.key,
    required this.activeTool,
    required this.targetFormat,
    required this.quality,
    required this.savePath,
    required this.isConverting,
    required this.queueLength,
    required this.shouldZip,
  });

  @override
  State<ExpandableSettingsBottomSheet> createState() => _ExpandableSettingsBottomSheetState();
}

class _ExpandableSettingsBottomSheetState extends State<ExpandableSettingsBottomSheet> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: AppTheme.border(context)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle and expand header (Tappable to toggle)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  // Small drag handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tune,
                              size: 18,
                              color: AppTheme.primaryLight(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              localizations.globalSettings,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                          size: 20,
                          color: AppTheme.onSurfaceVariant(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            
            // Expandable settings section
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SettingsPanel(
                          activeTool: widget.activeTool,
                          targetFormat: widget.targetFormat,
                          quality: widget.quality,
                          savePath: widget.savePath,
                          isConverting: widget.isConverting,
                          queueLength: widget.queueLength,
                          shouldZip: widget.shouldZip,
                          showConvertButton: false,
                          hideContainerBackground: true,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Convert All Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: widget.isConverting || widget.queueLength == 0
                      ? null
                      : () {
                          context.read<ConverterBloc>().add(StartConversionEvent());
                        },
                  icon: widget.isConverting
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
                    widget.isConverting
                        ? localizations.processing
                        : '${localizations.convertAll} (${widget.queueLength})',
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
            ),
          ],
        ),
      ),
    );
  }
}
