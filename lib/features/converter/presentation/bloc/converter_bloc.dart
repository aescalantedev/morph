import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../services/notification_service.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../domain/entities/media_file.dart';
import '../../domain/usecases/convert_file_usecase.dart';
import '../../domain/usecases/get_media_duration_usecase.dart';
import 'converter_event.dart';
import 'converter_state.dart';

/// Business Logic Component (BLoC) that orchestrates the media conversion workspace.
///
/// Coordinates adding/removing files to/from the queue, modifying settings,
/// querying video metadata in the background, executing the FFmpeg conversion pipeline,
/// and streaming progress updates.
class ConverterBloc extends Bloc<ConverterEvent, ConverterState> {
  /// Use case for triggering file conversion.
  final ConvertFileUseCase convertFileUseCase;

  /// Use case for probing media duration.
  final GetMediaDurationUseCase getMediaDurationUseCase;

  /// Creates a [ConverterBloc] with required usecases and sets up event handlers.
  ConverterBloc({
    required this.convertFileUseCase,
    required this.getMediaDurationUseCase,
  }) : super(ConverterState.initial()) {
    on<AddFilesEvent>(_onAddFiles);
    on<RemoveFileEvent>(_onRemoveFile);
    on<ClearQueueEvent>(_onClearQueue);
    on<ChangeTargetFormatEvent>(_onChangeTargetFormat);
    on<ChangeQualityEvent>(_onChangeQuality);
    on<ChangeSavePathEvent>(_onChangeSavePath);
    on<ChangeActiveToolEvent>(_onChangeActiveTool);
    on<UpdateFileProgressEvent>(_onUpdateFileProgress);
    on<UpdateFileStatusEvent>(_onUpdateFileStatus);
    on<StartConversionEvent>(_onStartConversion);
    on<ResetConverterEvent>(_onResetConverter);
    on<ToggleShouldZipEvent>(_onToggleShouldZip);

    _initializeDefaultSavePath();
  }

  /// Initializes the default export directory based on target platform.
  Future<void> _initializeDefaultSavePath() async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }
      if (directory != null) {
        add(ChangeSavePathEvent(directory.path));
      }
    } catch (_) {}
  }

  /// Event handler for adding files to the queue. Probes duration in the background.
  Future<void> _onAddFiles(AddFilesEvent event, Emitter<ConverterState> emit) async {
    final updatedQueue = List<MediaFile>.from(state.queue);
    final List<MediaFile> newFilesToProcess = [];

    for (var file in event.files) {
      if (updatedQueue.any((f) => f.path == file.path)) continue;
      updatedQueue.add(file);
      newFilesToProcess.add(file);
    }

    emit(state.copyWith(queue: updatedQueue));

    // Fetch duration in background for media files to calculate statistics
    for (var file in newFilesToProcess) {
      if (file.category == 'video' || file.category == 'audio') {
        try {
          final duration = await getMediaDurationUseCase(file.path);
          if (duration != null) {
            final currentQueue = List<MediaFile>.from(state.queue);
            final index = currentQueue.indexWhere((f) => f.id == file.id);
            if (index != -1) {
              currentQueue[index] = currentQueue[index].copyWith(durationSeconds: duration);
              emit(state.copyWith(queue: currentQueue));
            }
          }
        } catch (_) {}
      }
    }
  }

  /// Event handler for removing a file from the queue.
  void _onRemoveFile(RemoveFileEvent event, Emitter<ConverterState> emit) {
    final updatedQueue = state.queue.where((f) => f.id != event.id).toList();
    emit(state.copyWith(queue: updatedQueue));
  }

  /// Event handler for clearing the conversion queue.
  void _onClearQueue(ClearQueueEvent event, Emitter<ConverterState> emit) {
    emit(state.copyWith(queue: []));
  }

  /// Event handler for changing the target format extension.
  void _onChangeTargetFormat(ChangeTargetFormatEvent event, Emitter<ConverterState> emit) {
    emit(state.copyWith(targetFormat: event.format));
  }

  /// Event handler for changing compression quality.
  void _onChangeQuality(ChangeQualityEvent event, Emitter<ConverterState> emit) {
    emit(state.copyWith(quality: event.quality));
  }

  /// Event handler for changing the save output folder.
  void _onChangeSavePath(ChangeSavePathEvent event, Emitter<ConverterState> emit) {
    emit(state.copyWith(savePath: event.path, isInitialized: true));
  }

  /// Event handler for changing the active tool (resets queue and selects default output formats).
  void _onChangeActiveTool(ChangeActiveToolEvent event, Emitter<ConverterState> emit) {
    String defaultFormat = 'webp';
    if (event.tool == 'video') defaultFormat = 'mp4';
    if (event.tool == 'audio') defaultFormat = 'mp3';

    emit(state.copyWith(
      activeTool: event.tool,
      targetFormat: defaultFormat,
      queue: [],
    ));
  }

  /// Event handler for receiving progress updates for individual files.
  void _onUpdateFileProgress(UpdateFileProgressEvent event, Emitter<ConverterState> emit) {
    final updatedQueue = state.queue.map((file) {
      if (file.id == event.id) {
        return file.copyWith(progress: event.progress);
      }
      return file;
    }).toList();
    emit(state.copyWith(queue: updatedQueue));
  }

  /// Event handler for receiving final statuses for individual files.
  void _onUpdateFileStatus(UpdateFileStatusEvent event, Emitter<ConverterState> emit) {
    final updatedQueue = state.queue.map((file) {
      if (file.id == event.id) {
        final updatedFile = file.copyWith(
          status: event.status,
          outputPath: event.outputPath,
          errorMessage: event.errorMessage,
          progress: event.status == ConversionStatus.completed ? 1.0 : file.progress,
        );

        return updatedFile;
      }
      return file;
    }).toList();

    // Find the file that transitioned
    final fileInQueue = state.queue.firstWhere((f) => f.id == event.id);
    final updatedFile = fileInQueue.copyWith(
      status: event.status,
      outputPath: event.outputPath,
      errorMessage: event.errorMessage,
      progress: event.status == ConversionStatus.completed ? 1.0 : fileInQueue.progress,
    );

    List<MediaFile> updatedHistory = List<MediaFile>.from(state.history);
    if (event.status == ConversionStatus.completed || event.status == ConversionStatus.failed) {
      updatedHistory = List<MediaFile>.from(state.history)..insert(0, updatedFile);
    }

    emit(state.copyWith(queue: updatedQueue, history: updatedHistory));
  }

  /// Event handler that initiates the sequential conversion pipeline of queued files.
  Future<void> _onStartConversion(StartConversionEvent event, Emitter<ConverterState> emit) async {
    if (state.isConverting || state.queue.isEmpty) return;

    emit(state.copyWith(isConverting: true, generatedZipPath: null));

    final List<String> successfulPaths = [];

    // Process each file in the queue
    for (var i = 0; i < state.queue.length; i++) {
      final file = state.queue[i];
      if (file.status == ConversionStatus.completed) {
        if (file.outputPath != null) {
          successfulPaths.add(file.outputPath!);
        }
        continue;
      }

      add(UpdateFileStatusEvent(id: file.id, status: ConversionStatus.processing));

      final lastDotIdx = file.name.lastIndexOf('.');
      final inputFileName = lastDotIdx != -1 ? file.name.substring(0, lastDotIdx) : file.name;
      final outputFileName = '${inputFileName}_converted.${state.targetFormat.toLowerCase()}';
      final outputPath = '${state.savePath}${Platform.pathSeparator}$outputFileName';

      try {
        final stream = convertFileUseCase(
          file: file.copyWith(targetFormat: state.targetFormat),
          outputPath: outputPath,
          quality: state.quality,
        );

        await for (var progress in stream) {
          add(UpdateFileProgressEvent(id: file.id, progress: progress));
        }

        add(UpdateFileStatusEvent(
          id: file.id,
          status: ConversionStatus.completed,
          outputPath: outputPath,
        ));
        successfulPaths.add(outputPath);
      } catch (e) {
        add(UpdateFileStatusEvent(
          id: file.id,
          status: ConversionStatus.failed,
          errorMessage: e.toString(),
        ));
      }
    }

    // Package in a ZIP archive if option is enabled and there are successful conversions
    String? zipPath;
    if (state.shouldZip && successfulPaths.isNotEmpty) {
      try {
        // Wait a short delay to ensure files are fully written and locks released by the OS
        await Future.delayed(const Duration(milliseconds: 300));

        final zipFileName = 'converted_files_${DateTime.now().millisecondsSinceEpoch}.zip';
        final tempDir = await getTemporaryDirectory();
        final tempZipPath = '${tempDir.path}${Platform.pathSeparator}$zipFileName';
        zipPath = '${state.savePath}${Platform.pathSeparator}$zipFileName';

        final encoder = ZipFileEncoder();
        encoder.create(tempZipPath);
        for (final path in successfulPaths) {
          await encoder.addFile(File(path));
        }
        await encoder.close();

        // Copy the finished ZIP file from the temp directory to the final destination
        final tempZipFile = File(tempZipPath);
        if (await tempZipFile.exists()) {
          await tempZipFile.copy(zipPath);
          await tempZipFile.delete();
        } else {
          zipPath = null;
        }
      } catch (e) {
        debugPrint('Error zipping files: $e');
        zipPath = null;
      }
    }

    // Trigger desktop notification on background completion if enabled
    try {
      final settingsBloc = di.sl<SettingsBloc>();
      if (settingsBloc.state.notificationsEnabled) {
        final isSpanish = settingsBloc.state.languageCode == 'es' ||
            (settingsBloc.state.languageCode == 'system' && Platform.localeName.startsWith('es'));
        final title = isSpanish ? "Conversión Completada" : "Conversion Complete";
        final body = isSpanish
            ? "¡Todos tus archivos han sido procesados con éxito!"
            : "All your files have been successfully processed!";

        di.sl<NotificationService>().showNotification(title: title, body: body);
      }
    } catch (e) {
      debugPrint('Error triggering background notification: $e');
    }

    emit(state.copyWith(
      isConverting: false,
      generatedZipPath: zipPath,
    ));
  }

  /// Event handler to toggle whether multiple converted files should be bundled into a ZIP file.
  void _onToggleShouldZip(ToggleShouldZipEvent event, Emitter<ConverterState> emit) {
    emit(state.copyWith(shouldZip: event.shouldZip));
  }

  /// Resets the converter queue and halts any active operations.
  void _onResetConverter(ResetConverterEvent event, Emitter<ConverterState> emit) {
    emit(state.copyWith(
      queue: [],
      isConverting: false,
      generatedZipPath: null,
    ));
  }
}
