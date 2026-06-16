import 'package:get_it/get_it.dart';
import '../../services/ffmpeg_service.dart';
import '../../services/image_service.dart';
import '../../services/settings_storage_service.dart';
import '../../services/history_storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/windows_registry_service.dart';
import '../../services/file_opener_service.dart';
import '../../features/converter/data/repositories/conversion_repository_impl.dart';
import '../../features/converter/domain/repositories/conversion_repository.dart';
import '../../features/converter/domain/usecases/convert_file_usecase.dart';
import '../../features/converter/domain/usecases/get_media_duration_usecase.dart';
import '../../features/converter/presentation/bloc/converter_bloc.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';

/// Global service locator instance for dependency injection.
final sl = GetIt.instance;

/// Initializes the dependency injection container.
///
/// Registers all core services, repositories, use cases, and BLoC factories
/// to decouple components and allow easy testing.
Future<void> initDI() async {
  // Services
  sl.registerLazySingleton<FFmpegService>(() => FFmpegService());
  sl.registerLazySingleton<ImageService>(() => ImageService());
  sl.registerLazySingleton<SettingsStorageService>(() => SettingsStorageService());
  sl.registerLazySingleton<HistoryStorageService>(() => HistoryStorageService());
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<WindowsRegistryService>(() => WindowsRegistryService());
  sl.registerLazySingleton<FileOpenerService>(() => FileOpenerService());

  // Repositories
  sl.registerLazySingleton<ConversionRepository>(
    () => ConversionRepositoryImpl(
      ffmpegService: sl<FFmpegService>(),
      imageService: sl<ImageService>(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => ConvertFileUseCase(sl<ConversionRepository>()));
  sl.registerLazySingleton(() => GetMediaDurationUseCase(sl<ConversionRepository>()));

  // BLoCs
  sl.registerFactory(
    () => ConverterBloc(
      convertFileUseCase: sl<ConvertFileUseCase>(),
      getMediaDurationUseCase: sl<GetMediaDurationUseCase>(),
      historyStorage: sl<HistoryStorageService>(),
    ),
  );
  sl.registerLazySingleton(
    () => SettingsBloc(
      settingsStorage: sl<SettingsStorageService>(),
      windowsRegistry: sl<WindowsRegistryService>(),
    ),
  );
}
