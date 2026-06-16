import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// A service to display local/desktop and mobile notifications.
///
/// Integrates with the [local_notifier] package on desktop platforms
/// (Windows, macOS, Linux) and [flutter_local_notifications] on mobile platforms (Android, iOS).
class NotificationService {
  /// Local notifier plugin instance for mobile platforms.
  final FlutterLocalNotificationsPlugin _mobileNotifier = FlutterLocalNotificationsPlugin();

  /// Initializes the local notification engine.
  ///
  /// This must be called during application startup.
  Future<void> initialize() async {
    try {
      if (kIsWeb) return;

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await localNotifier.setup(
          appName: 'Morph',
          shortcutPolicy: ShortcutPolicy.requireCreate,
        );
      } else if (Platform.isAndroid || Platform.isIOS) {
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const DarwinInitializationSettings initializationSettingsIOS =
            DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        final InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

        await _mobileNotifier.initialize(
          settings: initializationSettings,
        );

        // Request permissions for Android 13+ (API 33+)
        if (Platform.isAndroid) {
          await _mobileNotifier
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission();
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  /// Triggers a local toast/system notification with a [title] and [body].
  ///
  /// Safe to call on all platforms. On non-supported platforms, it defaults
  /// to a standard console log.
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    try {
      if (kIsWeb) {
        debugPrint('NOTIFICATION WEB FALLBACK: [$title] - $body');
        return;
      }

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final notification = LocalNotification(
          title: title,
          body: body,
        );

        notification.onShow = () {
          debugPrint('Desktop notification shown: $title');
        };

        await notification.show();
      } else if (Platform.isAndroid || Platform.isIOS) {
        const AndroidNotificationDetails androidNotificationDetails =
            AndroidNotificationDetails(
          'morph_conversion_channel',
          'Morph Conversions',
          channelDescription: 'Notifications for completed file conversions',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

        const DarwinNotificationDetails iosNotificationDetails =
            DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidNotificationDetails,
          iOS: iosNotificationDetails,
        );

        await _mobileNotifier.show(
          id: 0,
          title: title,
          body: body,
          notificationDetails: notificationDetails,
        );
      } else {
        // Fallback for mobile or web in-app logs
        debugPrint('NOTIFICATION FALLBACK: [$title] - $body');
      }
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }
}
