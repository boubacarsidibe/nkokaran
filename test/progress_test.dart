import 'package:flutter_test/flutter_test.dart';
import 'package:nko_kalan/state/progress_store.dart';
import 'package:nko_kalan/state/spaced_repetition.dart';
import 'package:nko_kalan/services/voice_service.dart';

void main() {
  final day1 = DateTime(2026, 10, 1, 9);

  group('streak', () {
    test('first study day starts the streak at 1', () {
      final p = Progress()..recordStudyDay(day1);
      expect(p.streak, 1);
    });

    test('studying twice the same day does not double count', () {
      final p = Progress()
        ..recordStudyDay(day1)
        ..recordStudyDay(day1.add(const Duration(hours: 5)));
      expect(p.streak, 1);
    });

    test('consecutive days extend the streak', () {
      final p = Progress()
        ..recordStudyDay(day1)
        ..recordStudyDay(day1.add(const Duration(days: 1)))
        ..recordStudyDay(day1.add(const Duration(days: 2)));
      expect(p.streak, 3);
    });

    test('merely opening the app on a new day does not advance the streak', () {
      final p = Progress()..recordStudyDay(day1);
      p.settleStreak(day1.add(const Duration(days: 1)));
      expect(p.streak, 1);
    });

    test('a missed day without a freeze resets the streak', () {
      final p = Progress()
        ..recordStudyDay(day1)
        ..recordStudyDay(day1.add(const Duration(days: 1)));
      p.settleStreak(day1.add(const Duration(days: 3)));
      expect(p.streak, 0);
      p.recordStudyDay(day1.add(const Duration(days: 3)));
      expect(p.streak, 1);
    });

    test('a freeze covers exactly one missed day', () {
      final p = Progress(streakFreezes: 1)
        ..recordStudyDay(day1)
        ..recordStudyDay(day1.add(const Duration(days: 1)));
      p.settleStreak(day1.add(const Duration(days: 3))); // missed day 3 only
      expect(p.streak, 2);
      expect(p.streakFreezes, 0);
      p.recordStudyDay(day1.add(const Duration(days: 3)));
      expect(p.streak, 3);
    });

    test('one freeze does not cover a multi-day gap', () {
      final p = Progress(streakFreezes: 1)
        ..recordStudyDay(day1)
        ..recordStudyDay(day1.add(const Duration(days: 1)));
      p.settleStreak(day1.add(const Duration(days: 6)));
      expect(p.streak, 0);
    });
  });

  group('hearts', () {
    test('regenerate over wall-clock time', () {
      final p = Progress()..loseHeart(day1);
      expect(p.hearts, maxHearts - 1);
      p.regenerateHearts(day1.add(heartRegenInterval));
      expect(p.hearts, maxHearts);
      expect(p.nextHeartAtMs, isNull);
    });
  });

  group('spaced repetition', () {
    test('a miss resets the interval, a hit grows it', () {
      final p = Progress();
      applyReview(p, 'ߊ', true, day1);
      applyReview(p, 'ߊ', true, day1);
      expect(ReviewState.fromJson(p.reviewStates['ߊ']!).intervalDays, 3);
      applyReview(p, 'ߊ', false, day1);
      expect(ReviewState.fromJson(p.reviewStates['ߊ']!).intervalDays, 1);
    });

    test('letters become due after their interval', () {
      final p = Progress();
      applyReview(p, 'ߊ', true, day1);
      expect(dueForReview(p, day1), isEmpty);
      expect(dueForReview(p, day1.add(const Duration(days: 2))), ['ߊ']);
    });
  });

  group('persistence', () {
    test('round-trips through JSON', () {
      final p = Progress(xp: 42, streak: 3)..recordStudyDay(day1);
      final back = Progress.fromJson(p.toJson());
      expect(back.xp, 42);
      expect(back.lastStudyDay, p.lastStudyDay);
    });
  });

  test('speech text drops pedagogical parentheses', () {
    expect(TtsService.cleanForSpeech('é (fermé)'), 'é');
    expect(TtsService.cleanForSpeech('n (nasale)'), 'n');
    expect(TtsService.cleanForSpeech('ba'), 'ba');
  });
}
