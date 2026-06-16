import '../entities/media_file.dart';

/// Contract interface for media conversion repository operations.
///
/// Defines the boundary for platform-specific multimedia conversion implementations.
abstract class ConversionRepository {
  /// Analyzes the file and retrieves its duration in seconds.
  ///
  /// Returns `null` if the duration could not be extracted or the file is invalid.
  Future<double?> getMediaDuration(String path);
  
  /// Performs the actual conversion from the input file to the destination path.
  ///
  /// Emits values between 0.0 and 1.0 representing progress, ending in a completion
  /// or error state.
  Stream<double> convertFile({
    required MediaFile file,
    required String outputPath,
    required int quality,
  });
}
