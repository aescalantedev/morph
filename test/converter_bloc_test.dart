import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:morph/features/converter/domain/entities/media_file.dart';
import 'package:morph/features/converter/domain/usecases/convert_file_usecase.dart';
import 'package:morph/features/converter/domain/usecases/get_media_duration_usecase.dart';
import 'package:morph/features/converter/presentation/bloc/converter_bloc.dart';
import 'package:morph/features/converter/presentation/bloc/converter_event.dart';
import 'package:morph/features/converter/presentation/bloc/converter_state.dart';
import 'package:morph/services/history_storage_service.dart';

class FakeHistoryStorage extends HistoryStorageService {
  List<MediaFile> history = [];

  @override
  Future<List<MediaFile>> readHistory() async {
    return history;
  }

  @override
  Future<void> writeHistory(List<MediaFile> newHistory) async {
    history = newHistory;
  }
}

class FakeConvertFileUseCase extends Fake implements ConvertFileUseCase {
  @override
  Stream<double> call({
    required MediaFile file,
    required String outputPath,
    required int quality,
  }) {
    return Stream.fromIterable([0.5, 1.0]);
  }
}

class FakeGetMediaDurationUseCase extends Fake implements GetMediaDurationUseCase {
  @override
  Future<double?> call(String path) async {
    return 10.0;
  }
}

void main() {
  late FakeHistoryStorage fakeStorage;
  late FakeConvertFileUseCase fakeConvertFileUseCase;
  late FakeGetMediaDurationUseCase fakeGetMediaDurationUseCase;
  late ConverterBloc converterBloc;

  setUp(() {
    fakeStorage = FakeHistoryStorage();
    fakeConvertFileUseCase = FakeConvertFileUseCase();
    fakeGetMediaDurationUseCase = FakeGetMediaDurationUseCase();
    converterBloc = ConverterBloc(
      convertFileUseCase: fakeConvertFileUseCase,
      getMediaDurationUseCase: fakeGetMediaDurationUseCase,
      historyStorage: fakeStorage,
    );
  });

  tearDown(() {
    converterBloc.close();
  });

  test('initial state has empty history', () {
    expect(converterBloc.state.history, isEmpty);
  });

  test('LoadHistoryEvent loads history correctly from storage', () async {
    final mockFile = MediaFile(
      id: '1',
      name: 'test.mp4',
      path: '/path/test.mp4',
      sizeBytes: 1024,
      extension: 'MP4',
      category: 'video',
      targetFormat: 'MKV',
      status: ConversionStatus.completed,
    );
    fakeStorage.history = [mockFile];

    converterBloc.add(const LoadHistoryEvent());

    await expectLater(
      converterBloc.stream,
      emits(
        converterBloc.state.copyWith(history: [mockFile]),
      ),
    );
  });

  test('ClearHistoryEvent clears history from storage and state', () async {
    final mockFile = MediaFile(
      id: '1',
      name: 'test.mp4',
      path: '/path/test.mp4',
      sizeBytes: 1024,
      extension: 'MP4',
      category: 'video',
      targetFormat: 'MKV',
      status: ConversionStatus.completed,
    );
    fakeStorage.history = [mockFile];
    converterBloc.emit(converterBloc.state.copyWith(history: [mockFile]));

    converterBloc.add(const ClearHistoryEvent());

    await expectLater(
      converterBloc.stream,
      emits(
        converterBloc.state.copyWith(history: []),
      ),
    );
    expect(fakeStorage.history, isEmpty);
  });

  test('UpdateFileStatusEvent (completed) saves file to history in storage and state', () async {
    final mockFile = MediaFile(
      id: '1',
      name: 'test.mp4',
      path: '/path/test.mp4',
      sizeBytes: 1024,
      extension: 'MP4',
      category: 'video',
      targetFormat: 'MKV',
      status: ConversionStatus.idle,
    );

    // Setup queue with the file
    converterBloc.emit(converterBloc.state.copyWith(queue: [mockFile]));

    converterBloc.add(const UpdateFileStatusEvent(
      id: '1',
      status: ConversionStatus.completed,
      outputPath: '/path/test_converted.mkv',
    ));

    final expectedCompletedFile = mockFile.copyWith(
      status: ConversionStatus.completed,
      outputPath: '/path/test_converted.mkv',
      progress: 1.0,
    );

    await expectLater(
      converterBloc.stream,
      emits(
        converterBloc.state.copyWith(
          queue: [expectedCompletedFile],
          history: [expectedCompletedFile],
        ),
      ),
    );

    // Verify storage has the persisted record
    expect(fakeStorage.history, [expectedCompletedFile]);
  });

  test('StartConversionEvent with mergeIntoSingleFile creates a single merged PDF and completes all files', () async {
    final mockFile1 = MediaFile(
      id: '1',
      name: 'image1.png',
      path: 'test_resources/image1.png',
      sizeBytes: 100,
      extension: 'PNG',
      category: 'image',
      targetFormat: 'PDF',
      status: ConversionStatus.idle,
    );
    final mockFile2 = MediaFile(
      id: '2',
      name: 'image2.png',
      path: 'test_resources/image2.png',
      sizeBytes: 100,
      extension: 'PNG',
      category: 'image',
      targetFormat: 'PDF',
      status: ConversionStatus.idle,
    );

    // Write dummy image files to disk so the bloc can read them
    final dir = Directory('test_resources');
    if (!await dir.exists()) {
      await dir.create();
    }
    final cmdImg = img.Image(width: 1, height: 1);
    final pngBytes = img.encodePng(cmdImg);
    await File('test_resources/image1.png').writeAsBytes(pngBytes);
    await File('test_resources/image2.png').writeAsBytes(pngBytes);

    converterBloc.emit(converterBloc.state.copyWith(
      queue: [mockFile1, mockFile2],
      activeTool: 'image',
      targetFormat: 'pdf',
      mergeIntoSingleFile: true,
      savePath: 'test_resources',
    ));

    converterBloc.add(StartConversionEvent());

    // Wait for the conversion to finish
    await expectLater(
      converterBloc.stream,
      emitsThrough(
        predicate<ConverterState>((state) {
          return !state.isConverting &&
              state.queue.every((f) => f.status == ConversionStatus.completed);
        }),
      ),
    );

    // Verify that the files point to the same outputPath
    final q = converterBloc.state.queue;
    expect(q[0].outputPath, isNotNull);
    expect(q[1].outputPath, q[0].outputPath);

    // Clean up
    await File('test_resources/image1.png').delete();
    await File('test_resources/image2.png').delete();
    final mergedFile = File(q[0].outputPath!);
    if (await mergedFile.exists()) {
      await mergedFile.delete();
    }
    await dir.delete();
  });
}
