import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/media_file.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';
import '../bloc/converter_state.dart';
import '../widgets/dropzone_area.dart';
import '../widgets/file_card.dart';
import '../widgets/settings_panel.dart';
import '../widgets/expandable_settings_bottom_sheet.dart';
import '../widgets/conversion_progress.dart';
import '../widgets/file_picker_helper.dart';

/// The page containing the media converter queue, format settings, and dropzone.
///
/// Automatically switches between desktop (side-by-side) and mobile (stacked) layouts.
/// Displays a success recap screen once all conversions have finished.
class ConverterPage extends StatelessWidget {
  /// Creates a [ConverterPage] widget.
  const ConverterPage({super.key});

  /// Builds the top tabs to switch between conversion tools (Image, Video, Audio).
  Widget _buildToolTabs(BuildContext context, String activeTool, bool isConverting, AppLocalizations localizations) {
    final tools = [
      {'id': 'image', 'name': localizations.images, 'icon': Icons.image_outlined},
      {'id': 'video', 'name': localizations.video, 'icon': Icons.videocam_outlined},
      {'id': 'audio', 'name': localizations.audio, 'icon': Icons.volume_up_outlined},
    ];

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.background(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: tools.map((tool) {
          final isSelected = activeTool == tool['id'];
          return Expanded(
            child: MouseRegion(
              cursor: isConverting ? SystemMouseCursors.basic : SystemMouseCursors.click,
              child: GestureDetector(
                onTap: isConverting
                    ? null
                    : () {
                        context.read<ConverterBloc>().add(ChangeActiveToolEvent(tool['id'] as String));
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary(context).withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary(context).withValues(alpha: 0.2) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tool['icon'] as IconData,
                        size: 16,
                        color: isSelected ? AppTheme.primary(context) : AppTheme.onSurfaceVariant(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tool['name'] as String,
                        style: TextStyle(
                          color: isSelected ? AppTheme.primary(context) : AppTheme.onSurfaceVariant(context),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddMoreButton(BuildContext context, String activeTool, AppLocalizations localizations) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => FilePickerHelper.pickFiles(context: context, activeTool: activeTool),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primary(context).withValues(alpha: 0.25),
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 18,
                color: AppTheme.primary(context),
              ),
              const SizedBox(width: 6),
              Text(
                localizations.addMoreFiles,
                style: TextStyle(
                  color: AppTheme.primary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDroppedFiles(BuildContext context, List<dynamic> files, String activeTool) async {
    final List<MediaFile> selectedFiles = [];
    final defaultFormat = context.read<ConverterBloc>().state.targetFormat.toLowerCase();

    // Category extensions maps for validation
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'tiff', 'svg'};
    const videoExts = {'mp4', 'webm', 'gif', 'mkv', 'avi', 'mov', 'flv', 'wmv'};
    const audioExts = {'mp3', 'wav', 'ogg', 'm4a', 'flac', 'aac'};

    for (var file in files) {
      final path = file.path;
      if (path == null) continue;

      final fileName = file.name;
      final fileExt = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

      // Validate that the dropped file format matches the active tab tool
      bool matches = false;
      if (activeTool == 'image' && imageExts.contains(fileExt)) {
        matches = true;
      } else if (activeTool == 'video' && videoExts.contains(fileExt)) {
        matches = true;
      } else if (activeTool == 'audio' && audioExts.contains(fileExt)) {
        matches = true;
      }

      if (!matches) continue;

      try {
        final fileIo = File(path);
        if (await fileIo.exists()) {
          final length = await fileIo.length();
          selectedFiles.add(MediaFile(
            id: '${DateTime.now().microsecondsSinceEpoch}_$path',
            name: fileName,
            path: path,
            sizeBytes: length,
            extension: fileExt.toUpperCase(),
            category: activeTool,
            targetFormat: defaultFormat,
          ));
        }
      } catch (_) {}
    }

    if (selectedFiles.isNotEmpty && context.mounted) {
      context.read<ConverterBloc>().add(AddFilesEvent(selectedFiles));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<ConverterBloc, ConverterState>(
      builder: (context, state) {
        // Check if conversion completed successfully (queue not empty and all finished)
        final bool showSuccessScreen = state.queue.isNotEmpty &&
            !state.isConverting &&
            state.queue.every((f) => f.status == ConversionStatus.completed || f.status == ConversionStatus.failed);

        if (showSuccessScreen) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ConversionProgress(
              queue: state.queue,
              generatedZipPath: state.generatedZipPath,
              mergeIntoSingleFile: state.mergeIntoSingleFile,
              onReset: () {
                context.read<ConverterBloc>().add(ResetConverterEvent());
              },
            ),
          );
        }

        final Widget content = LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;

            final Widget activeWidget = state.queue.isEmpty
                ? DropzoneArea(activeTool: state.activeTool)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.queue.length,
                        itemBuilder: (context, index) {
                          final file = state.queue[index];
                          return FileCard(
                            file: file,
                            isConverting: state.isConverting,
                            onRemove: () {
                              context.read<ConverterBloc>().add(RemoveFileEvent(file.id));
                            },
                            onTargetFormatChanged: (newFormat) {
                              context.read<ConverterBloc>().add(UpdateFileTargetFormatEvent(
                                id: file.id,
                                targetFormat: newFormat,
                              ));
                            },
                          );
                        },
                      ),
                      if (!state.isConverting)
                        _buildAddMoreButton(context, state.activeTool, localizations),
                    ],
                  );

            if (isDesktop) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildToolTabs(context, state.activeTool, state.isConverting, localizations),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left queue list
                          Expanded(
                            flex: 3,
                            child: state.queue.isEmpty
                                ? activeWidget
                                : SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: activeWidget,
                                    ),
                                  ),
                          ),
                          if (state.queue.isNotEmpty) ...[
                            const SizedBox(width: 24),
                            // Right settings panel
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: SettingsPanel(
                                    activeTool: state.activeTool,
                                    targetFormat: state.targetFormat,
                                    quality: state.quality,
                                    savePath: state.savePath,
                                    isConverting: state.isConverting,
                                    queueLength: state.queue.length,
                                    shouldZip: state.shouldZip,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Mobile/Tablet stacked layout
              return Scaffold(
                backgroundColor: Colors.transparent,
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildToolTabs(context, state.activeTool, state.isConverting, localizations),
                      const SizedBox(height: 24),
                      activeWidget,
                      // Bottom padding so activeWidget items are not obscured by the collapsed bottom sheet
                      if (state.queue.isNotEmpty)
                        const SizedBox(height: 100),
                    ],
                  ),
                ),
                bottomNavigationBar: state.queue.isNotEmpty && !showSuccessScreen
                    ? ExpandableSettingsBottomSheet(
                        activeTool: state.activeTool,
                        targetFormat: state.targetFormat,
                        quality: state.quality,
                        savePath: state.savePath,
                        isConverting: state.isConverting,
                        queueLength: state.queue.length,
                        shouldZip: state.shouldZip,
                      )
                    : null,
              );
            }
          },
        );

        if (state.queue.isNotEmpty && !state.isConverting) {
          return DropTarget(
            onDragDone: (detail) {
              _handleDroppedFiles(context, detail.files, state.activeTool);
            },
            child: content,
          );
        }

        return content;
      },
    );
  }
}
