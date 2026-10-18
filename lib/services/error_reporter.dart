import 'dart:developer' as developer;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Central sink for errors caught in "fail soft" paths (background sync,
/// notifications, cache loads) — previously silently dropped, which made
/// data-loss/sync bug reports impossible to diagnose. Always logs locally;
/// also forwards to Crashlytics as non-fatal when the platform supports it.
class ErrorReporter {
  ErrorReporter._();

  static bool get _crashlyticsSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static void report(String context, Object error, [StackTrace? stackTrace]) {
    developer.log('$context: $error', name: 'nko_kalan', error: error, stackTrace: stackTrace, level: 900);
    if (_crashlyticsSupported) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: context, fatal: false);
    }
  }
}
