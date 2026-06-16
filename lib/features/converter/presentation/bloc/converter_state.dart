import 'package:equatable/equatable.dart';
import '../../domain/entities/media_file.dart';

/// Represents the overall state of the conversion workspace.
///
/// Contains the active files, selected quality, target extensions, system routes,
/// and complete history of previous conversions.
class ConverterState extends Equatable {
  /// The active queue of files to be converted.
  final List<MediaFile> queue;

  /// The active tool category ('image', 'video', 'audio').
  final String activeTool;

  /// The current targeted output format extension.
  final String targetFormat;

  /// Target compression quality (0-100).
  final int quality;

  /// The destination directory path for converted files.
  final String savePath;

  /// Signals whether a conversion process is active.
  final bool isConverting;

  /// Completed or failed conversions in the current session.
  final List<MediaFile> history;

  /// Signals if settings and folders have been initialized.
  final bool isInitialized;

  /// Signals whether multiple converted files should be bundled into a ZIP file.
  final bool shouldZip;

  /// The path to the generated ZIP archive, if any.
  final String? generatedZipPath;

  /// Creates a [ConverterState] configuration.
  const ConverterState({
    required this.queue,
    required this.activeTool,
    required this.targetFormat,
    required this.quality,
    required this.savePath,
    required this.isConverting,
    required this.history,
    this.isInitialized = false,
    this.shouldZip = false,
    this.generatedZipPath,
  });

  /// Factory for the initial state of the conversion queue.
  factory ConverterState.initial() {
    return const ConverterState(
      queue: [],
      activeTool: 'image',
      targetFormat: 'webp',
      quality: 85,
      savePath: '',
      isConverting: false,
      history: [],
      isInitialized: false,
      shouldZip: false,
      generatedZipPath: null,
    );
  }

  /// Creates a copy of the state with updated parameters.
  ConverterState copyWith({
    List<MediaFile>? queue,
    String? activeTool,
    String? targetFormat,
    int? quality,
    String? savePath,
    bool? isConverting,
    List<MediaFile>? history,
    bool? isInitialized,
    bool? shouldZip,
    String? generatedZipPath,
  }) {
    return ConverterState(
      queue: queue ?? this.queue,
      activeTool: activeTool ?? this.activeTool,
      targetFormat: targetFormat ?? this.targetFormat,
      quality: quality ?? this.quality,
      savePath: savePath ?? this.savePath,
      isConverting: isConverting ?? this.isConverting,
      history: history ?? this.history,
      isInitialized: isInitialized ?? this.isInitialized,
      shouldZip: shouldZip ?? this.shouldZip,
      generatedZipPath: generatedZipPath ?? this.generatedZipPath,
    );
  }

  @override
  List<Object?> get props => [
        queue,
        activeTool,
        targetFormat,
        quality,
        savePath,
        isConverting,
        history,
        isInitialized,
        shouldZip,
        generatedZipPath,
      ];
}
