import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import '../features/converter/domain/entities/media_file.dart';

/// Local service wrapper that communicates directly with FFmpeg and FFprobe libraries.
///
/// Under desktop platforms (Windows, Linux, macOS), it spawns standard FFmpeg/FFprobe
/// CLI subprocesses to ensure stability, proper thread pooling, and to avoid issues
/// with file paths containing spaces. On mobile platforms, it uses ffmpeg-kit FFI bindings.
class FFmpegService {
  /// Probes the media file at [path] via FFprobe to retrieve its duration in seconds.
  ///
  /// Returns `null` if the duration could not be extracted or the file is invalid.
  Future<double?> getMediaDuration(String path) async {
    try {
      final normalizedPath = path.replaceAll('\\', '/');

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Run system ffprobe process to avoid FFI path escaping issues on desktop
        final result = await Process.run('ffprobe', [
          '-v', 'error',
          '-show_entries', 'format=duration',
          '-of', 'default=noprint_wrappers=1:nokey=1',
          normalizedPath,
        ]);
        if (result.exitCode == 0) {
          final output = result.stdout.toString().trim();
          return double.tryParse(output);
        }
      } else {
        // Fallback to FFprobeKit FFI wrapper on mobile
        final session = await FFprobeKit.getMediaInformation('"$normalizedPath"');
        final mediaInformation = session.getMediaInformation();
        if (mediaInformation != null) {
          final durationString = mediaInformation.getDuration();
          if (durationString != null) {
            return double.tryParse(durationString);
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting media duration: $e');
    }
    return null;
  }

  /// Triggers an asynchronous FFmpeg command to convert [file] to [outputPath].
  ///
  /// Calculates real-time progress using statistic timestamps divided by duration
  /// and streams the percentage back to listeners.
  Stream<double> convertFile({
    required MediaFile file,
    required String outputPath,
    required int quality,
  }) {
    final controller = StreamController<double>();
    final arguments = _buildFFmpegArguments(file.path, outputPath, file.targetFormat.toLowerCase(), quality);

    getMediaDuration(file.path).then((durationSeconds) {
      final totalDuration = durationSeconds ?? file.durationSeconds ?? 0.0;

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        _convertFileDesktop(arguments, totalDuration, controller);
      } else {
        _convertFileMobile(arguments, totalDuration, controller);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
        controller.close();
      }
    });

    return controller.stream;
  }

  /// Runs the conversion via system FFmpeg process (for desktop platforms).
  Future<void> _convertFileDesktop(
    List<String> arguments,
    double totalDuration,
    StreamController<double> controller,
  ) async {
    try {
      // Dart's Process.start handles spaces inside arguments automatically on all OSs
      final process = await Process.start('ffmpeg', arguments);

      // Listen to stderr as FFmpeg outputs its progress updates to stderr
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (totalDuration > 0.0 && line.contains('time=')) {
          final timeMatch = RegExp(r'time=(\d+):(\d+):(\d+\.\d+)').firstMatch(line);
          if (timeMatch != null) {
            final hours = int.parse(timeMatch.group(1)!);
            final minutes = int.parse(timeMatch.group(2)!);
            final seconds = double.parse(timeMatch.group(3)!);
            final timeInSeconds = hours * 3600 + minutes * 60 + seconds;

            double progress = timeInSeconds / totalDuration;
            if (progress > 0.99) progress = 0.99;
            if (progress < 0.0) progress = 0.0;

            if (!controller.isClosed) {
              controller.add(progress);
            }
          }
        }
      });

      final exitCode = await process.exitCode;
      if (exitCode == 0) {
        if (!controller.isClosed) {
          controller.add(1.0);
          controller.close();
        }
      } else {
        if (!controller.isClosed) {
          controller.addError('FFmpeg process failed with exit code $exitCode');
          controller.close();
        }
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(
          'Failed to run system FFmpeg: $e. Please make sure FFmpeg is installed and added to your system PATH.',
        );
        controller.close();
      }
    }
  }

  /// Runs the conversion via FFmpegKit (for mobile platforms).
  void _convertFileMobile(
    List<String> arguments,
    double totalDuration,
    StreamController<double> controller,
  ) {
    FFmpegKit.executeWithArgumentsAsync(
      arguments,
      (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          if (!controller.isClosed) {
            controller.add(1.0);
            controller.close();
          }
        } else {
          final failStackTrace = await session.getFailStackTrace();
          final String? output = await session.getOutput();
          final String logs = await session.getLogsAsString();

          String errorMessage = 'FFmpeg process failed';
          if (output != null && output.trim().isNotEmpty) {
            errorMessage = output.trim();
          } else if (logs.trim().isNotEmpty) {
            errorMessage = logs.trim();
          } else if (failStackTrace != null) {
            errorMessage = failStackTrace;
          }

          if (!controller.isClosed) {
            controller.addError(errorMessage);
            controller.close();
          }
        }
      },
      (log) {
        debugPrint('FFMPEG: ${log.getMessage()}');
      },
      (statistics) {
        if (totalDuration > 0.0) {
          // getTime() returns time in milliseconds
          final timeInSeconds = statistics.getTime() / 1000.0;
          double progress = timeInSeconds / totalDuration;
          if (progress > 0.99) progress = 0.99;
          if (progress < 0.0) progress = 0.0;
          if (!controller.isClosed) {
            controller.add(progress);
          }
        }
      },
    );
  }

  /// Constructs the list of command line arguments for FFmpeg.
  ///
  /// Automatically determines appropriate codecs, scale adjustments, quality levels,
  /// and outputs depending on the requested destination extension format.
  List<String> _buildFFmpegArguments(String inputPath, String outputPath, String targetFormat, int quality) {
    // Normalizing paths to use forward slashes for cross-platform safety
    final normalizedInput = inputPath.replaceAll('\\', '/');
    final normalizedOutput = outputPath.replaceAll('\\', '/');

    switch (targetFormat) {
      // --- IMAGES ---
      case 'webp':
        // WebP quality goes from 0-100. Using -quality for libwebp.
        return ['-hide_banner', '-y', '-i', normalizedInput, '-quality', '$quality', normalizedOutput];
      case 'jpg':
      case 'jpeg':
        // JPG quality can be mapped via scale factor (lower crf/qscale is higher quality)
        // In FFmpeg, -qscale:v 2 is excellent, 31 is worst.
        final qscale = ((100 - quality) / 100 * 30).clamp(2, 31).toInt();
        return ['-hide_banner', '-y', '-i', normalizedInput, '-q:v', '$qscale', normalizedOutput];
      case 'png':
        return ['-hide_banner', '-y', '-i', normalizedInput, normalizedOutput];
      case 'avif':
        // AVIF encoding: we use libaom-av1 and standard quality
        return ['-hide_banner', '-y', '-i', normalizedInput, '-c:v', 'libaom-av1', '-still-picture', '1', normalizedOutput];

      // --- VIDEO ---
      case 'mp4':
        // CRF goes from 0 (lossless) to 51 (worst). 18-28 is standard.
        final crf = ((100 - quality) / 100 * 30 + 18).clamp(18, 51).toInt();
        return [
          '-hide_banner',
          '-y',
          '-i',
          normalizedInput,
          '-c:v',
          'libx264',
          '-crf',
          '$crf',
          '-c:a',
          'aac',
          '-pix_fmt',
          'yuv420p',
          normalizedOutput
        ];
      case 'webm':
        // Convert to WebM using VP9
        return [
          '-hide_banner',
          '-y',
          '-i',
          normalizedInput,
          '-c:v',
          'libvpx-vp9',
          '-b:v',
          '1M',
          '-c:a',
          'libvorbis',
          normalizedOutput
        ];
      case 'gif':
        return [
          '-hide_banner',
          '-y',
          '-t',
          '30', // Limit output to a maximum of 30 seconds to prevent generating massive files
          '-i',
          normalizedInput,
          '-vf',
          'fps=12,scale=480:-1:flags=lanczos', // Optimized frame rate & high quality scaling
          normalizedOutput
        ];

      // --- AUDIO ---
      case 'mp3':
        // MP3 LAME quality scale (0 is best, 9 is worst)
        final aq = ((100 - quality) / 100 * 9).clamp(0, 9).toInt();
        return ['-hide_banner', '-y', '-i', normalizedInput, '-c:a', 'libmp3lame', '-q:a', '$aq', normalizedOutput];
      case 'wav':
        return ['-hide_banner', '-y', '-i', normalizedInput, normalizedOutput];
      case 'ogg':
        // OGG Vorbis quality scale (-1 to 10)
        final q = ((quality / 100 * 11) - 1).clamp(-1, 10).toInt();
        return ['-hide_banner', '-y', '-i', normalizedInput, '-c:a', 'libvorbis', '-q:a', '$q', normalizedOutput];

      default:
        return ['-hide_banner', '-y', '-i', normalizedInput, normalizedOutput];
    }
  }
}
