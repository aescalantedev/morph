import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:morph/l10n/app_localizations.dart';

import 'core/di/injection_container.dart' as di;
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/converter/presentation/bloc/converter_bloc.dart';

/// Main entrypoint of the Morph application.
///
/// Ensures framework initialization, setups the dependency injection container,
/// and starts execution of the root application widget.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDI();
  runApp(const MyApp());
}

/// The root application widget.
///
/// Sets up the global BLoC providers, localization, themes, and declares
/// the router configuration using GoRouter.
class MyApp extends StatelessWidget {
  /// Creates the [MyApp] widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConverterBloc>(
          create: (context) => di.sl<ConverterBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Morph',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
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
          if (locale != null) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
          }
          return supportedLocales.first; // Default to Spanish as configured in l10n.yaml
        },
      ),
    );
  }
}
