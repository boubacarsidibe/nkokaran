import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'error_reporter.dart';

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
    } catch (e, st) {
      // Permission denied, unsupported OS version, etc. — reminder is a
      // nice-to-have, never worth crashing or blocking app startup over.
      ErrorReporter.report('NotificationService._ensureReady', e, st);
    }
  }

  /// Schedules (or re-schedules) a once-a-day reminder, tailored to the
  /// learner's current state — a streak at risk gets a sharper nudge than a
  /// cold start, and no reminder is scheduled at all once today's goal is
  /// already met. Call again whenever [streak]/[dailyGoalReached] change
  /// (app launch, after finishing a session) so the pending notification
  /// stays in sync with the latest known state — re-registering just
  /// replaces the previous content under the same [_reminderId].
  ///
  /// Not tied to an exact wall-clock time — `RepeatInterval.daily` is an
  /// inexact ~24h repeat, which is plenty precise for this nudge and avoids
  /// pulling in a timezone dependency for exact scheduling.
  Future<void> scheduleDailyReminder({required int streak, required bool dailyGoalReached}) async {
    await _ensureReady();
    if (!_ready) return;
    if (dailyGoalReached) {
      // Already studied today — no need to nudge until tomorrow's state
      // resets and re-schedules this on the next app launch/session.
      await cancelDailyReminder();
      return;
    }
    final title = streak > 0 ? "Ta série de $streak jour${streak > 1 ? 's' : ''} est en danger !" : "N'oublie pas ta série !";
    final body = streak > 0
        ? "Termine une leçon aujourd'hui pour ne pas la perdre."
        : "Prends 5 minutes pour continuer ton apprentissage du N'Ko aujourd'hui.";
    try {
      await _plugin.periodicallyShow(
        _reminderId,
        title,
        body,
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
    } catch (e, st) {
      // Fails soft — same reasoning as above.
      ErrorReporter.report('NotificationService.scheduleDailyReminder', e, st);
    }
  }

  Future<void> cancelDailyReminder() async {
    if (!_supportedPlatform) return;
    try {
      await _plugin.cancel(_reminderId);
    } catch (e, st) {
      ErrorReporter.report('NotificationService.cancelDailyReminder', e, st);
    }
  }
}
