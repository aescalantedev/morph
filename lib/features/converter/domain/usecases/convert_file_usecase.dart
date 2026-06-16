import '../entities/media_file.dart';
import '../repositories/conversion_repository.dart';

/// Usecase to trigger the file conversion pipeline.
///
/// Encapsulates the logic of calling the [ConversionRepository] for starting
/// file conversion and returning a progress stream.
class ConvertFileUseCase {
  /// The conversion repository dependency.
  final ConversionRepository repository;

  /// Creates a [ConvertFileUseCase] with its repository dependency.
  ConvertFileUseCase(this.repository);

  /// Executes the use case to convert a [file] to [outputPath] with specified [quality].
  ///
  /// Returns a stream of double values representing progress (0.0 to 1.0).
  Stream<double> call({
    required MediaFile file,
    required String outputPath,
    required int quality,
  }) {
    return repository.convertFile(
      file: file,
      outputPath: outputPath,
      quality: quality,
    );
  }
}
