import '../repositories/conversion_repository.dart';

/// Usecase to obtain a media file's duration.
///
/// Encapsulates the logic of calling the [ConversionRepository] to extract
/// duration metadata using FFprobe.
class GetMediaDurationUseCase {
  /// The conversion repository dependency.
  final ConversionRepository repository;

  /// Creates a [GetMediaDurationUseCase] with its repository dependency.
  GetMediaDurationUseCase(this.repository);

  /// Executes the use case to query the duration in seconds for the media file at [path].
  ///
  /// Returns `null` if the duration cannot be fetched or parsing fails.
  Future<double?> call(String path) {
    return repository.getMediaDuration(path);
  }
}
