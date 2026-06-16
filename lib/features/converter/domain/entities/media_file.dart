import 'package:equatable/equatable.dart';

/// Defines the possible states of a file conversion process.
enum ConversionStatus {
  /// The file is queued and waiting to start converting.
  idle,

  /// The file is currently being processed by FFmpeg.
  processing,

  /// The conversion completed successfully.
  completed,

  /// The conversion failed due to an error.
  failed,
}

/// Represents a media file loaded into the converter queue.
///
/// Holds the current conversion status, properties of the source file,
/// the target format, and path outputs.
class MediaFile extends Equatable {
  /// Unique identifier of the queued file.
  final String id;

  /// The user-facing name of the file (including extension).
  final String name;

  /// The absolute local file path to the source file.
  final String path;

  /// The size of the source file in bytes.
  final int sizeBytes;

  /// The file extension of the source file (e.g. '.mp4').
  final String extension;

  /// Category of the media file (e.g., 'image', 'video', 'audio').
  final String category;

  /// The destination format chosen for conversion (e.g., 'MP3', 'WEBP').
  final String targetFormat;

  /// The current state of this file's conversion process.
  final ConversionStatus status;

  /// Progress of the conversion between 0.0 and 1.0.
  final double progress;

  /// Duration of the media file in seconds, retrieved via FFprobe.
  final double? durationSeconds;

  /// Description of the failure if [status] is [ConversionStatus.failed].
  final String? errorMessage;

  /// The output absolute file path where the converted file is stored.
  final String? outputPath;

  /// Creates a [MediaFile] with required properties.
  const MediaFile({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.extension,
    required this.category,
    required this.targetFormat,
    this.status = ConversionStatus.idle,
    this.progress = 0.0,
    this.durationSeconds,
    this.errorMessage,
    this.outputPath,
  });

  /// Returns a copy of this MediaFile with updated properties.
  MediaFile copyWith({
    String? id,
    String? name,
    String? path,
    int? sizeBytes,
    String? extension,
    String? category,
    String? targetFormat,
    ConversionStatus? status,
    double? progress,
    double? durationSeconds,
    String? errorMessage,
    String? outputPath,
  }) {
    return MediaFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      extension: extension ?? this.extension,
      category: category ?? this.category,
      targetFormat: targetFormat ?? this.targetFormat,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      errorMessage: errorMessage ?? this.errorMessage,
      outputPath: outputPath ?? this.outputPath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        path,
        sizeBytes,
        extension,
        category,
        targetFormat,
        status,
        progress,
        durationSeconds,
        errorMessage,
        outputPath,
      ];

  /// Creates a [MediaFile] from a JSON map.
  factory MediaFile.fromJson(Map<String, dynamic> json) {
    // Parse conversion status
    ConversionStatus status = ConversionStatus.idle;
    final statusStr = json['status'] as String?;
    if (statusStr != null) {
      status = ConversionStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => ConversionStatus.idle,
      );
    }

    return MediaFile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      extension: json['extension'] as String? ?? '',
      category: json['category'] as String? ?? '',
      targetFormat: json['targetFormat'] as String? ?? '',
      status: status,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble(),
      errorMessage: json['errorMessage'] as String?,
      outputPath: json['outputPath'] as String?,
    );
  }

  /// Converts this [MediaFile] instance into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'sizeBytes': sizeBytes,
      'extension': extension,
      'category': category,
      'targetFormat': targetFormat,
      'status': status.name,
      'progress': progress,
      'durationSeconds': durationSeconds,
      'errorMessage': errorMessage,
      'outputPath': outputPath,
    };
  }
}
