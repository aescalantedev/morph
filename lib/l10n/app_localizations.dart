import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Morph'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In es, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @convert.
  ///
  /// In es, this message translates to:
  /// **'Convertir'**
  String get convert;

  /// No description provided for @history.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settings;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Monitorea tus conversiones y recursos del sistema.'**
  String get dashboardSubtitle;

  /// No description provided for @totalConversions.
  ///
  /// In es, this message translates to:
  /// **'Total Conversiones'**
  String get totalConversions;

  /// No description provided for @spaceSaved.
  ///
  /// In es, this message translates to:
  /// **'Espacio Ahorrado'**
  String get spaceSaved;

  /// No description provided for @activeTasks.
  ///
  /// In es, this message translates to:
  /// **'Tareas Activas'**
  String get activeTasks;

  /// No description provided for @storage.
  ///
  /// In es, this message translates to:
  /// **'Almacenamiento'**
  String get storage;

  /// No description provided for @recentActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad Reciente'**
  String get recentActivity;

  /// No description provided for @viewAll.
  ///
  /// In es, this message translates to:
  /// **'Ver Todo'**
  String get viewAll;

  /// No description provided for @fileName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de Archivo'**
  String get fileName;

  /// No description provided for @format.
  ///
  /// In es, this message translates to:
  /// **'Formato'**
  String get format;

  /// No description provided for @date.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get date;

  /// No description provided for @status.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get status;

  /// No description provided for @newConversion.
  ///
  /// In es, this message translates to:
  /// **'Nueva Conversión'**
  String get newConversion;

  /// No description provided for @dragFiles.
  ///
  /// In es, this message translates to:
  /// **'Sube tu archivo para convertir'**
  String get dragFiles;

  /// No description provided for @dragFilesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Arrastra y suelta aquí o haz clic para buscar.'**
  String get dragFilesSubtitle;

  /// No description provided for @images.
  ///
  /// In es, this message translates to:
  /// **'Imágenes'**
  String get images;

  /// No description provided for @video.
  ///
  /// In es, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @audio.
  ///
  /// In es, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @targetFormat.
  ///
  /// In es, this message translates to:
  /// **'Formato de destino'**
  String get targetFormat;

  /// No description provided for @startConversion.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Conversión'**
  String get startConversion;

  /// No description provided for @processing.
  ///
  /// In es, this message translates to:
  /// **'Procesando'**
  String get processing;

  /// No description provided for @completed.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get completed;

  /// No description provided for @failed.
  ///
  /// In es, this message translates to:
  /// **'Fallido'**
  String get failed;

  /// No description provided for @downloadFile.
  ///
  /// In es, this message translates to:
  /// **'Descargar Archivo'**
  String get downloadFile;

  /// No description provided for @convertAnother.
  ///
  /// In es, this message translates to:
  /// **'Convertir otro archivo'**
  String get convertAnother;

  /// No description provided for @conversionSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Completado!'**
  String get conversionSuccess;

  /// No description provided for @globalSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes Globales'**
  String get globalSettings;

  /// No description provided for @qualityCompression.
  ///
  /// In es, this message translates to:
  /// **'Calidad / Compresión'**
  String get qualityCompression;

  /// No description provided for @saveLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación de guardado'**
  String get saveLocation;

  /// No description provided for @browse.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get browse;

  /// No description provided for @overwriteExisting.
  ///
  /// In es, this message translates to:
  /// **'Sobrescribir archivos existentes'**
  String get overwriteExisting;

  /// No description provided for @deleteOriginals.
  ///
  /// In es, this message translates to:
  /// **'Eliminar originales tras éxito'**
  String get deleteOriginals;

  /// No description provided for @convertAll.
  ///
  /// In es, this message translates to:
  /// **'Convertir Todo'**
  String get convertAll;

  /// No description provided for @packageInZip.
  ///
  /// In es, this message translates to:
  /// **'Empaquetar en ZIP'**
  String get packageInZip;

  /// No description provided for @packageInZipDesc.
  ///
  /// In es, this message translates to:
  /// **'Crea un archivo .zip único'**
  String get packageInZipDesc;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @systemLanguage.
  ///
  /// In es, this message translates to:
  /// **'Por defecto del sistema'**
  String get systemLanguage;

  /// No description provided for @notifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones de escritorio'**
  String get notifications;

  /// No description provided for @notificationsDesc.
  ///
  /// In es, this message translates to:
  /// **'Mostrar alertas al finalizar conversiones en segundo plano'**
  String get notificationsDesc;

  /// No description provided for @defaultOutputPath.
  ///
  /// In es, this message translates to:
  /// **'Ruta de salida por defecto'**
  String get defaultOutputPath;

  /// No description provided for @systemInfo.
  ///
  /// In es, this message translates to:
  /// **'Información del Sistema'**
  String get systemInfo;

  /// No description provided for @engineStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado del motor'**
  String get engineStatus;

  /// No description provided for @ffmpegActive.
  ///
  /// In es, this message translates to:
  /// **'FFmpeg activo (Pro-Convert Engine)'**
  String get ffmpegActive;

  /// No description provided for @activeCodecs.
  ///
  /// In es, this message translates to:
  /// **'Códecs activos'**
  String get activeCodecs;

  /// No description provided for @activeCodecsDesc.
  ///
  /// In es, this message translates to:
  /// **'H.264, MPEG-4, AAC, VP9, WebP, PNG, JPG, GIF'**
  String get activeCodecsDesc;

  /// No description provided for @platform.
  ///
  /// In es, this message translates to:
  /// **'Plataforma'**
  String get platform;

  /// No description provided for @morphVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión de Morph'**
  String get morphVersion;

  /// No description provided for @freeSoftware.
  ///
  /// In es, this message translates to:
  /// **'Software Libre'**
  String get freeSoftware;

  /// No description provided for @freeSoftwareDesc.
  ///
  /// In es, this message translates to:
  /// **'Herramienta gratuita sin registros ni límites de conversión'**
  String get freeSoftwareDesc;

  /// No description provided for @conversionCompleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Conversión Completada'**
  String get conversionCompleteTitle;

  /// No description provided for @conversionCompleteBody.
  ///
  /// In es, this message translates to:
  /// **'¡Todos tus archivos han sido procesados con éxito!'**
  String get conversionCompleteBody;

  /// No description provided for @settingsUpdated.
  ///
  /// In es, this message translates to:
  /// **'Ajustes actualizados'**
  String get settingsUpdated;

  /// No description provided for @windowsMenu.
  ///
  /// In es, this message translates to:
  /// **'Menú contextual de Windows'**
  String get windowsMenu;

  /// No description provided for @windowsMenuDesc.
  ///
  /// In es, this message translates to:
  /// **'Añadir opción \'Convertir con Morph\' al hacer clic derecho en archivos'**
  String get windowsMenuDesc;

  /// No description provided for @themeColor.
  ///
  /// In es, this message translates to:
  /// **'Color de tema'**
  String get themeColor;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
