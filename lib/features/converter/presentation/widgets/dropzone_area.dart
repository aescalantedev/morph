import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:morph/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/media_file.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';

/// A interactive landing area widget that prompts the user to select files.
///
/// Filters the picker options depending on the current active tool category
/// (image, video, audio) and parses picked metadata into [MediaFile] entities.
class DropzoneArea extends StatelessWidget {
  /// The active tool category filter ('image', 'video', 'audio').
  final String activeTool;

  /// Creates a [DropzoneArea] widget.
  const DropzoneArea({super.key, required this.activeTool});

  /// Opens the native platform file picker filtered by [activeTool].
  Future<void> _pickFiles(BuildContext context) async {
    FileType pickerType = FileType.any;

    if (activeTool == 'image') {
      pickerType = FileType.image;
    } else if (activeTool == 'video') {
      pickerType = FileType.video;
    } else if (activeTool == 'audio') {
      pickerType = FileType.audio;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: pickerType,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final List<MediaFile> selectedFiles = [];
        for (var file in result.files) {
          if (file.path != null) {
            final fileName = file.name;
            final fileExt = file.extension ?? fileName.split('.').last;
            
            selectedFiles.add(MediaFile(
              id: '${DateTime.now().microsecondsSinceEpoch}_${file.path!}',
              name: fileName,
              path: file.path!,
              sizeBytes: file.size,
              extension: fileExt.toUpperCase(),
              category: activeTool,
              targetFormat: '', 
            ));
          }
        }
        if (context.mounted) {
          context.read<ConverterBloc>().add(AddFilesEvent(selectedFiles));
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    IconData iconData = Icons.image_outlined;
    if (activeTool == 'video') {
      iconData = Icons.videocam_outlined;
    } else if (activeTool == 'audio') {
      iconData = Icons.volume_up_outlined;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _pickFiles(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                ),
                child: Icon(
                  iconData,
                  size: 44,
                  color: AppTheme.primary,
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
    );
  }
}
