import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'file_picker_helper.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/media_file.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';

/// An interactive landing area widget that prompts the user to select files.
///
/// Supports clicking to open a file picker or dragging-and-dropping files
/// from the operating system. Filters picked/dropped files depending on the
/// current active tool category ('image', 'video', 'audio').
class DropzoneArea extends StatefulWidget {
  /// The active tool category filter ('image', 'video', 'audio').
  final String activeTool;

  /// Creates a [DropzoneArea] widget.
  const DropzoneArea({super.key, required this.activeTool});

  @override
  State<DropzoneArea> createState() => _DropzoneAreaState();
}

class _DropzoneAreaState extends State<DropzoneArea> {
  bool _isDragging = false;

  /// Opens the native platform file picker filtered by [widget.activeTool].
  Future<void> _pickFiles(BuildContext context) async {
    await FilePickerHelper.pickFiles(
      context: context,
      activeTool: widget.activeTool,
    );
  }

  /// Handles files dropped into the area from the OS.
  Future<void> _handleDroppedFiles(BuildContext context, List<dynamic> files) async {
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
      if (widget.activeTool == 'image' && imageExts.contains(fileExt)) {
        matches = true;
      } else if (widget.activeTool == 'video' && videoExts.contains(fileExt)) {
        matches = true;
      } else if (widget.activeTool == 'audio' && audioExts.contains(fileExt)) {
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
            category: widget.activeTool,
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

    IconData iconData = Icons.image_outlined;
    if (widget.activeTool == 'video') {
      iconData = Icons.videocam_outlined;
    } else if (widget.activeTool == 'audio') {
      iconData = Icons.volume_up_outlined;
    }

    return DropTarget(
      onDragEntered: (detail) {
        setState(() {
          _isDragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _isDragging = false;
        });
      },
      onDragDone: (detail) {
        _handleDroppedFiles(context, detail.files);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _pickFiles(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
            decoration: BoxDecoration(
              color: _isDragging
                  ? AppTheme.primary(context).withValues(alpha: 0.08)
                  : AppTheme.surfaceContainerLow(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isDragging
                    ? AppTheme.primary(context)
                    : AppTheme.primary(context).withValues(alpha: 0.25),
                width: _isDragging ? 2.5 : 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? AppTheme.primary(context).withValues(alpha: 0.12)
                        : AppTheme.primary(context).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isDragging
                          ? AppTheme.primary(context).withValues(alpha: 0.3)
                          : AppTheme.primary(context).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Icon(
                    iconData,
                    size: 44,
                    color: AppTheme.primary(context),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  localizations.dragFiles,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.dragFilesSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
