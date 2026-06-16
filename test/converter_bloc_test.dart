import 'package:flutter_test/flutter_test.dart';
import 'package:morph/features/converter/domain/entities/media_file.dart';
import 'package:morph/features/converter/domain/usecases/convert_file_usecase.dart';
import 'package:morph/features/converter/domain/usecases/get_media_duration_usecase.dart';
import 'package:morph/features/converter/presentation/bloc/converter_bloc.dart';
import 'package:morph/features/converter/presentation/bloc/converter_event.dart';
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
}
