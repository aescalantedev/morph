import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/constants/app_constants.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/history_storage_service.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
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

  /// Service that manages the persistence of conversion history.
  final HistoryStorageService historyStorage;

  /// Creates a [ConverterBloc] with required usecases and sets up event handlers.
  ConverterBloc({
    required this.convertFileUseCase,
    required this.getMediaDurationUseCase,
    required this.historyStorage,
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
    on<LoadHistoryEvent>(_onLoadHistory);
    on<ClearHistoryEvent>(_onClearHistory);
    on<ToggleKeepOriginalFilesEvent>(_onToggleKeepOriginalFiles);
    on<ToggleMergeIntoSingleFileEvent>(_onToggleMergeIntoSingleFile);
    on<UpdateFileTargetFormatEvent>(_onUpdateFileTargetFormat);

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
      // Ensure targetFormat is initialized to the current global targetFormat if not set
      String targetFormat = file.targetFormat.isEmpty ? state.targetFormat : file.targetFormat;
      
      // If targetFormat matches the file's source extension, pick a different one
      if (targetFormat.toLowerCase() == file.extension.toLowerCase()) {
        final formats = AppConstants.formatsByCategory[file.category] ?? [];
        targetFormat = formats.firstWhere(
          (fmt) => fmt.toLowerCase() != file.extension.toLowerCase(),
          orElse: () => targetFormat,
        );
      }

      final updatedFile = file.copyWith(targetFormat: targetFormat);
      updatedQueue.add(updatedFile);
      newFilesToProcess.add(updatedFile);
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

  /// Event handler to update target format for a specific file in the queue.
  void _onUpdateFileTargetFormat(UpdateFileTargetFormatEvent event, Emitter<ConverterState> emit) {
    final updatedQueue = state.queue.map((file) {
      if (file.id == event.id) {
        return file.copyWith(targetFormat: event.targetFormat);
      }
      return file;
    }).toList();
    emit(state.copyWith(queue: updatedQueue));
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
    final updatedQueue = state.queue.map((file) {
      if (event.format.toLowerCase() == file.extension.toLowerCase()) {
        // Keep the file's current targetFormat since the new global format is identical to its source format
        return file;
      }
      return file.copyWith(targetFormat: event.format);
    }).toList();
    emit(state.copyWith(targetFormat: event.format, queue: updatedQueue));
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
  Future<void> _onUpdateFileStatus(UpdateFileStatusEvent event, Emitter<ConverterState> emit) async {
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
    final fileTargetFormat = fileInQueue.targetFormat.isNotEmpty ? fileInQueue.targetFormat.toLowerCase() : state.targetFormat.toLowerCase();

    // Map target format to category for completed history items
    String finalCategory = fileInQueue.category;
    if (event.status == ConversionStatus.completed) {
      if (AppConstants.audioFormats.contains(fileTargetFormat)) {
        finalCategory = 'audio';
      } else if (AppConstants.imageFormats.contains(fileTargetFormat)) {
        finalCategory = 'image';
      } else {
        finalCategory = 'video';
      }
    }

    final updatedFile = fileInQueue.copyWith(
      status: event.status,
      outputPath: event.outputPath,
      errorMessage: event.errorMessage,
      category: finalCategory,
      progress: event.status == ConversionStatus.completed ? 1.0 : fileInQueue.progress,
    );

    List<MediaFile> updatedHistory = List<MediaFile>.from(state.history);
    if (event.status == ConversionStatus.completed || event.status == ConversionStatus.failed) {
      updatedHistory = List<MediaFile>.from(state.history)..insert(0, updatedFile);
    }

    // Emit synchronously so that sequential events get the latest state immediately
    emit(state.copyWith(queue: updatedQueue, history: updatedHistory));

    // Persist to storage asynchronously after emitting state
    if (event.status == ConversionStatus.completed || event.status == ConversionStatus.failed) {
      try {
        await historyStorage.writeHistory(updatedHistory);
      } catch (_) {}
    }
  }

  /// Event handler that initiates the sequential conversion pipeline of queued files.
  Future<void> _onStartConversion(StartConversionEvent event, Emitter<ConverterState> emit) async {
    if (state.isConverting || state.queue.isEmpty) return;

    final targetFormat = state.targetFormat.toLowerCase();

    // PDF merging routine
    if (state.mergeIntoSingleFile && targetFormat == 'pdf' && state.activeTool == 'image') {
      emit(state.copyWith(isConverting: true, generatedZipPath: null));

      final outputFileName = 'merged_document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outputPath = '${state.savePath}${Platform.pathSeparator}$outputFileName';

      final receivePort = ReceivePort();

      try {
        await Isolate.spawn<_PdfMergeMessage>(
          _pdfMergeWorker,
          (
            inputPaths: state.queue.map((f) => f.path).toList(),
            outputPath: outputPath,
            sendPort: receivePort.sendPort,
          ),
        );
      } catch (e) {
        receivePort.close();
        for (var file in state.queue) {
          add(UpdateFileStatusEvent(
            id: file.id,
            status: ConversionStatus.failed,
            errorMessage: 'Error al iniciar Isolate de combinación: $e',
          ));
        }
        emit(state.copyWith(isConverting: false));
        return;
      }

      final completer = Completer<void>();

      receivePort.listen(
        (message) async {
          if (message is int) {
            final file = state.queue[message];
            add(UpdateFileStatusEvent(id: file.id, status: ConversionStatus.processing));
            add(UpdateFileProgressEvent(id: file.id, progress: 0.5));
          } else if (message == 'saving') {
            for (var file in state.queue) {
              add(UpdateFileProgressEvent(id: file.id, progress: 0.9));
            }
          } else if (message == 'completed') {
            receivePort.close();

            final updatedQueue = List<MediaFile>.from(state.queue);
            final completedFilesForHistory = <MediaFile>[];

            for (var i = 0; i < updatedQueue.length; i++) {
              final file = updatedQueue[i];
              final completedFile = file.copyWith(
                status: ConversionStatus.completed,
                outputPath: outputPath,
                progress: 1.0,
              );
              updatedQueue[i] = completedFile;
              completedFilesForHistory.add(completedFile);

              // Delete original file if keepOriginalFiles is false
              if (!state.keepOriginalFiles) {
                try {
                  final fileIo = File(file.path);
                  if (await fileIo.exists()) {
                    await fileIo.delete();
                  }
                } catch (_) {}
              }
            }

            final updatedHistory = List<MediaFile>.from(state.history);
            updatedHistory.insertAll(0, completedFilesForHistory);
            await historyStorage.writeHistory(updatedHistory);

            emit(state.copyWith(
              queue: updatedQueue,
              history: updatedHistory,
              isConverting: false,
            ));
            completer.complete();
          } else if (message is String && message.startsWith('error:')) {
            receivePort.close();
            final errorMsg = message.replaceFirst('error:', '');
            for (var file in state.queue) {
              add(UpdateFileStatusEvent(
                id: file.id,
                status: ConversionStatus.failed,
                errorMessage: errorMsg,
              ));
            }
            emit(state.copyWith(isConverting: false));
            completer.complete();
          }
        },
        onError: (e) {
          receivePort.close();
          for (var file in state.queue) {
            add(UpdateFileStatusEvent(
              id: file.id,
              status: ConversionStatus.failed,
              errorMessage: 'Error en Isolate: $e',
            ));
          }
          emit(state.copyWith(isConverting: false));
          completer.complete();
        },
      );

      await completer.future;
      return;
    }

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

      final fileTargetFormat = file.targetFormat.isNotEmpty ? file.targetFormat.toLowerCase() : state.targetFormat.toLowerCase();
      final lastDotIdx = file.name.lastIndexOf('.');
      final inputFileName = lastDotIdx != -1 ? file.name.substring(0, lastDotIdx) : file.name;
      final outputFileName = '${inputFileName}_converted.$fileTargetFormat';
      final outputPath = '${state.savePath}${Platform.pathSeparator}$outputFileName';

      try {
        final stream = convertFileUseCase(
          file: file.copyWith(targetFormat: fileTargetFormat),
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

        // Delete original file if keepOriginalFiles is false
        if (!state.keepOriginalFiles) {
          try {
            final fileIo = File(file.path);
            if (await fileIo.exists()) {
              await fileIo.delete();
            }
          } catch (_) {}
        }
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

  /// Event handler for loading persisted history from local storage.
  Future<void> _onLoadHistory(LoadHistoryEvent event, Emitter<ConverterState> emit) async {
    if (state.isHistoryLoaded) return;
    final history = await historyStorage.readHistory();
    emit(state.copyWith(
      history: history,
      isHistoryLoaded: true,
    ));
  }

  /// Event handler for clearing conversion history in the state and storage.
  Future<void> _onClearHistory(ClearHistoryEvent event, Emitter<ConverterState> emit) async {
    await historyStorage.writeHistory([]);
    emit(state.copyWith(history: []));
  }

  void _onToggleKeepOriginalFiles(ToggleKeepOriginalFilesEvent event, Emitter<ConverterState> emit) {
    emit(state.copyWith(keepOriginalFiles: event.keep));
  }

  void _onToggleMergeIntoSingleFile(ToggleMergeIntoSingleFileEvent event, Emitter<ConverterState> emit) {
    emit(state.copyWith(mergeIntoSingleFile: event.merge));
  }

  /// Resets the converter queue and halts any active operations.
  void _onResetConverter(ResetConverterEvent event, Emitter<ConverterState> emit) {
    emit(state.copyWith(
      queue: [],
      isConverting: false,
      generatedZipPath: null,
    ));
  }

  static void _pdfMergeWorker(_PdfMergeMessage message) async {
    try {
      final pdfDoc = pw.Document();
      for (var i = 0; i < message.inputPaths.length; i++) {
        message.sendPort.send(i);
        final file = File(message.inputPaths[i]);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final image = img.decodeImage(bytes);
          if (image != null) {
            final pngBytes = img.encodePng(image);
            pdfDoc.addPage(
              pw.Page(
                pageFormat: PdfPageFormat(
                  image.width.toDouble(),
                  image.height.toDouble(),
                  marginAll: 0,
                ),
                build: (pw.Context context) {
                  return pw.Image(
                    pw.MemoryImage(pngBytes),
                    fit: pw.BoxFit.fill,
                  );
                },
              ),
            );
          } else {
            throw Exception('No se pudo decodificar la imagen: ${message.inputPaths[i]}');
          }
        } else {
          throw Exception('El archivo original no existe: ${message.inputPaths[i]}');
        }
      }

      message.sendPort.send('saving');
      final pdfBytes = await pdfDoc.save();

      final outputFile = File(message.outputPath);
      final parentDir = outputFile.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      await outputFile.writeAsBytes(pdfBytes);

      message.sendPort.send('completed');
    } catch (e) {
      message.sendPort.send('error: $e');
    }
  }
}

typedef _PdfMergeMessage = ({
  List<String> inputPaths,
  String outputPath,
  SendPort sendPort,
});
