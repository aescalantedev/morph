import 'package:equatable/equatable.dart';
import '../../domain/entities/media_file.dart';

/// Base event class for the converter feature block.
abstract class ConverterEvent extends Equatable {
  /// Creates a base [ConverterEvent].
  const ConverterEvent();

  @override
  List<Object?> get props => [];
}

/// Event dispatched to add selected files to the conversion queue.
class AddFilesEvent extends ConverterEvent {
  /// The list of media files to queue.
  final List<MediaFile> files;

  /// Creates an [AddFilesEvent] with target files.
  const AddFilesEvent(this.files);

  @override
  List<Object?> get props => [files];
}

/// Event dispatched to remove a single file from the conversion queue.
class RemoveFileEvent extends ConverterEvent {
  /// The unique identifier of the file to remove.
  final String id;

  /// Creates a [RemoveFileEvent] for the target ID.
  const RemoveFileEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event dispatched to clear all files in the current conversion queue.
class ClearQueueEvent extends ConverterEvent {}

/// Event dispatched when the target format selection changes.
class ChangeTargetFormatEvent extends ConverterEvent {
  /// The newly selected target extension format (e.g. 'webp').
  final String format;

  /// Creates a [ChangeTargetFormatEvent] with the selected format.
  const ChangeTargetFormatEvent(this.format);

  @override
  List<Object?> get props => [format];
}

/// Event dispatched when the compression quality slider changes.
class ChangeQualityEvent extends ConverterEvent {
  /// The quality percentage (from 0 to 100).
  final int quality;

  /// Creates a [ChangeQualityEvent] with the selected quality level.
  const ChangeQualityEvent(this.quality);

  @override
  List<Object?> get props => [quality];
}

/// Event dispatched when the output storage save path is updated.
class ChangeSavePathEvent extends ConverterEvent {
  /// The absolute directory path where files will be stored.
  final String path;

  /// Creates a [ChangeSavePathEvent] with the new directory path.
  const ChangeSavePathEvent(this.path);

  @override
  List<Object?> get props => [path];
}

/// Event dispatched to switch the active converting tool (e.g. 'image', 'video').
class ChangeActiveToolEvent extends ConverterEvent {
  /// The newly selected tool category name.
  final String tool;

  /// Creates a [ChangeActiveToolEvent] with the selected tool type.
  const ChangeActiveToolEvent(this.tool);

  @override
  List<Object?> get props => [tool];
}

/// Event dispatched to start converting all files in the current queue.
class StartConversionEvent extends ConverterEvent {}

/// Internal event dispatched to update progress for a single file.
class UpdateFileProgressEvent extends ConverterEvent {
  /// The unique identifier of the file.
  final String id;

  /// The progress percentage value (0.0 to 1.0).
  final double progress;

  /// Creates an [UpdateFileProgressEvent] with the current file conversion progress.
  const UpdateFileProgressEvent({required this.id, required this.progress});

  @override
  List<Object?> get props => [id, progress];
}

/// Internal event dispatched to transition a file's state and attach outputs.
class UpdateFileStatusEvent extends ConverterEvent {
  /// The unique identifier of the file.
  final String id;

  /// The new conversion status.
  final ConversionStatus status;

  /// The resulting converted file output path.
  final String? outputPath;

  /// The failure error stacktrace or string if compilation failed.
  final String? errorMessage;

  /// Creates an [UpdateFileStatusEvent] to signal conversion completion or failure.
  const UpdateFileStatusEvent({
    required this.id,
    required this.status,
    this.outputPath,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [id, status, outputPath, errorMessage];
}

/// Event dispatched to reset the converter view back to idle after completion.
class ResetConverterEvent extends ConverterEvent {}

/// Event dispatched to toggle zipping of multiple converted files.
class ToggleShouldZipEvent extends ConverterEvent {
  /// The target value of the ZIP toggle.
  final bool shouldZip;

  /// Creates a [ToggleShouldZipEvent] with the target state.
  const ToggleShouldZipEvent(this.shouldZip);

  @override
  List<Object?> get props => [shouldZip];
}
