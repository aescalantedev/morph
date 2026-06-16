import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as img;

/// Service to perform high-performance image conversions in a secondary isolate.
///
/// Uses the pure-Dart 'image' package to read and write formats like WebP, PNG, JPG, and GIF,
/// ensuring 100% reliability and cross-platform compatibility on Windows, Linux, and Android.
class ImageService {
  /// Converts an image from [inputPath] to [outputPath] in a background isolate.
  ///
  /// Emits `0.0` on start and `1.0` upon successful completion.
  /// Throws an exception if the image cannot be decoded or encoded.
  Stream<double> convertImage({
    required String inputPath,
    required String outputPath,
    required String targetFormat,
    required int quality,
  }) {
    final controller = StreamController<double>();

    // Start by emitting 0% progress
    controller.add(0.0);

    _runConversionInIsolate(
      inputPath: inputPath,
      outputPath: outputPath,
      targetFormat: targetFormat,
      quality: quality,
    ).then((_) {
      if (!controller.isClosed) {
        controller.add(1.0);
        controller.close();
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
        controller.close();
      }
    });

    return controller.stream;
  }

  /// Runs the CPU-bound decoding and encoding in a separate isolate to keep the UI responsive.
  static Future<void> _runConversionInIsolate({
    required String inputPath,
    required String outputPath,
    required String targetFormat,
    required int quality,
  }) async {
    await Isolate.run(() async {
      final file = File(inputPath);
      if (!await file.exists()) {
        throw Exception('Input file does not exist at path: $inputPath');
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image from path: $inputPath');
      }

      List<int> encodedBytes;
      final format = targetFormat.toLowerCase();

      switch (format) {
        case 'png':
          encodedBytes = img.encodePng(image);
          break;
        case 'jpg':
        case 'jpeg':
          encodedBytes = img.encodeJpg(image, quality: quality);
          break;
        case 'webp':
          encodedBytes = img.encodeWebP(image);
          break;
        case 'gif':
          encodedBytes = img.encodeGif(image);
          break;
        default:
          throw Exception('Unsupported image format: $targetFormat');
      }

      final outputFile = File(outputPath);
      // Ensure the parent directory exists
      final parentDir = outputFile.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      await outputFile.writeAsBytes(encodedBytes);
    });
  }
}
