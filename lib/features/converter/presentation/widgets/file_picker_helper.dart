import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/media_file.dart';
import '../bloc/converter_bloc.dart';
import '../bloc/converter_event.dart';

/// Helper class to open native platform file picker with filtered extensions.
///
/// Prevents issues where standard FileType.image/video/audio hides WebP or other
/// specific extensions on certain operating systems.
class FilePickerHelper {
  FilePickerHelper._();

  /// Prompts user to pick files matching the active tool and pushes them to BLoC.
  static Future<void> pickFiles({
    required BuildContext context,
    required String activeTool,
  }) async {
    List<String>? allowedExtensions;

    if (activeTool == 'image') {
      allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'tiff'];
    } else if (activeTool == 'video') {
      allowedExtensions = ['mp4', 'webm', 'gif', 'mkv', 'avi', 'mov', 'flv', 'wmv'];
    } else if (activeTool == 'audio') {
      allowedExtensions = ['mp3', 'wav', 'ogg', 'm4a', 'flac', 'aac'];
    }

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
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
}
