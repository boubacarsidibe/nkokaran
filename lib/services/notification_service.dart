import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Daily streak reminder — a single repeating local notification, nudging
/// the learner if they haven't studied yet today. Local-only (no server,
/// no push infra): `flutter_local_notifications` only ships real support for
/// Android/iOS/macOS/Linux, so this fails soft to a no-op everywhere else
/// (web, Windows — both platforms this app also targets).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _reminderId = 1;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get _supportedPlatform =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _ensureReady() async {
    if (_ready || !_supportedPlatform) return;
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
      _ready = true;
    } catch (_) {
      // Permission denied, unsupported OS version, etc. — reminder is a
      // nice-to-have, never worth crashing or blocking app startup over.
    }
  }

  /// Schedules (or re-schedules) a once-a-day reminder. Not tied to an exact
  /// wall-clock time — `RepeatInterval.daily` is an inexact ~24h repeat, which
  /// is plenty precise for a "don't lose your streak" nudge.
  Future<void> scheduleDailyReminder() async {
    await _ensureReady();
    if (!_ready) return;
    try {
      await _plugin.periodicallyShow(
        _reminderId,
        "N'oublie pas ta série !",
        "Prends 5 minutes pour continuer ton apprentissage du N'Ko aujourd'hui.",
        RepeatInterval.daily,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Rappel quotidien',
            channelDescription: "Rappel pour continuer ta série d'apprentissage",
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Fails soft — same reasoning as above.
    }
  }

  Future<void> cancelDailyReminder() async {
    if (!_supportedPlatform) return;
    try {
      await _plugin.cancel(_reminderId);
    } catch (_) {}
  }
}
