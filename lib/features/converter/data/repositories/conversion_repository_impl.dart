import '../../domain/entities/media_file.dart';
import '../../domain/repositories/conversion_repository.dart';
import '../../../../services/ffmpeg_service.dart';
import '../../../../services/image_service.dart';

/// Concrete implementation of the [ConversionRepository] using local providers.
///
/// Routes image conversions to [ImageService] and audio/video conversions to [FFmpegService].
class ConversionRepositoryImpl implements ConversionRepository {
  /// The local FFmpeg service wrapper.
  final FFmpegService ffmpegService;

  /// The local image conversion service wrapper.
  final ImageService imageService;

  /// Creates a [ConversionRepositoryImpl] with its service dependencies.
  ConversionRepositoryImpl({
    required this.ffmpegService,
    required this.imageService,
  });

  @override
  Future<double?> getMediaDuration(String path) {
    return ffmpegService.getMediaDuration(path);
  }

  @override
  Stream<double> convertFile({
    required MediaFile file,
    required String outputPath,
    required int quality,
  }) {
    final targetFormat = file.targetFormat.toLowerCase();

    // Pure Dart 'image' package handles these formats directly
    const dartSupportedImageFormats = {'png', 'jpg', 'jpeg', 'gif', 'pdf'};

    if (file.category == 'image' && dartSupportedImageFormats.contains(targetFormat)) {
      return imageService.convertImage(
        inputPath: file.path,
        outputPath: outputPath,
        targetFormat: targetFormat,
        quality: quality,
      );
    }

    // Default fallback to FFmpeg for video, audio, and specialized formats (like AVIF)
    return ffmpegService.convertFile(
      file: file,
      outputPath: outputPath,
      quality: quality,
    );
  }
}
