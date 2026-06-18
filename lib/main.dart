import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:morph/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'core/di/injection_container.dart' as di;
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/notification_service.dart';
import 'features/converter/domain/entities/media_file.dart';
import 'features/converter/presentation/bloc/converter_bloc.dart';
import 'features/converter/presentation/bloc/converter_event.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event.dart';
import 'features/settings/presentation/bloc/settings_state.dart';

/// Global initial file variable captured from launch arguments.
MediaFile? _initialMediaFile;

/// Main entrypoint of the Morph application.
///
/// Ensures framework initialization, setups the dependency injection container,
/// parses operating system launch arguments (for context menu launches),
/// initializes system local notifications, and starts execution of the root application.
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDI();
  await di.sl<NotificationService>().initialize();

  // Initialize window manager for desktop platforms to hide native title bar
  final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  if (isDesktop) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1100, 750),
      minimumSize: Size(850, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Handle file argument if opened via Windows right-click context menu
  if (args.isNotEmpty) {
    try {
      final filePath = args.first;
      final file = File(filePath);
      if (await file.exists()) {
        final fileName = filePath.split(Platform.pathSeparator).last;
        final fileExt = fileName.contains('.') ? fileName.split('.').last : '';
        final sizeBytes = await file.length();

        // Categorize file based on its extension
        String category = 'image';
        const videoExts = {'mp4', 'webm', 'gif', 'mkv', 'avi', 'mov', 'flv', 'wmv'};
        const audioExts = {'mp3', 'wav', 'ogg', 'm4a', 'flac', 'aac'};

        final extLower = fileExt.toLowerCase();
        if (videoExts.contains(extLower)) {
          category = 'video';
        } else if (audioExts.contains(extLower)) {
          category = 'audio';
        }

        _initialMediaFile = MediaFile(
          id: '${DateTime.now().microsecondsSinceEpoch}_$filePath',
          name: fileName,
          path: filePath,
          sizeBytes: sizeBytes,
          extension: fileExt.toUpperCase(),
          category: category,
          targetFormat: '', // Will be configured dynamically in bloc
        );

        // Override default startup tab to open directly on the converter page
        initialLocationOverride = '/convert';
      }
    } catch (_) {
      // Safely catch launch argument parsing issues
    }
  }
  // Pre-load settings before running the app to ensure correct initial theme
  final settingsBloc = di.sl<SettingsBloc>();
  settingsBloc.add(const LoadSettingsEvent());
  await settingsBloc.stream.firstWhere((state) => state.isLoaded).timeout(
    const Duration(seconds: 2),
    onTimeout: () => settingsBloc.state,
  );

  runApp(const MyApp());
}

/// The root application widget.
///
/// Sets up the global BLoC providers (ConverterBloc and SettingsBloc),
/// listens to theme/locale changes, and declares the router configuration using GoRouter.
class MyApp extends StatefulWidget {
  /// Creates the [MyApp] widget.
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConverterBloc>(
          create: (context) {
            final bloc = di.sl<ConverterBloc>()..add(const LoadHistoryEvent());
            if (_initialMediaFile != null) {
              // Set corresponding active tool tab first
              bloc.add(ChangeActiveToolEvent(_initialMediaFile!.category));
              // Preload the target file in the conversion queue
              bloc.add(AddFilesEvent([_initialMediaFile!]));
            }
            return bloc;
          },
        ),
        BlocProvider<SettingsBloc>(
          create: (context) => di.sl<SettingsBloc>(),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (previous, current) {
          return previous.themeMode != current.themeMode ||
              previous.themeColor != current.themeColor ||
              previous.languageCode != current.languageCode;
        },
        builder: (context, settingsState) {
          // Determine dynamically if dark theme is active to update static AppTheme helpers
          final isSystemDark = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
          final isDark = settingsState.themeMode == ThemeMode.dark ||
              (settingsState.themeMode == ThemeMode.system && isSystemDark);
          AppTheme.isDark = isDark;

          return MaterialApp.router(
            title: 'Morph',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(settingsState.themeColor),
            darkTheme: AppTheme.darkTheme(settingsState.themeColor),
            themeMode: settingsState.themeMode,
            locale: settingsState.locale,
            routerConfig: appRouter,
            themeAnimationDuration: const Duration(milliseconds: 350),
            themeAnimationCurve: Curves.easeInOut,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es', ''), // Spanish
              Locale('en', ''), // English
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              if (settingsState.locale != null) {
                return settingsState.locale;
              }
              if (locale != null) {
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode) {
                    return supportedLocale;
                  }
                }
              }
              return supportedLocales.first; // Default to Spanish as configured in l10n.yaml
            },
          );
        },
      ),
    );
  }
}



