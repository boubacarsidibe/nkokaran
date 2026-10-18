import 'package:flutter_test/flutter_test.dart';
import 'package:nko_kalan/state/challenges.dart';
import 'package:nko_kalan/state/progress_store.dart';

void main() {
  group('Challenge.progressFor', () {
    test('xp metric reads xpToday', () {
      final p = Progress()..xpToday = 42;
      const c = Challenge(title: 't', metric: ChallengeMetric.xp, target: 50);
      expect(c.progressFor(p), 42);
    });

    test('sessions metric reads sessionsToday', () {
      final p = Progress()..sessionsToday = 3;
      const c = Challenge(title: 't', metric: ChallengeMetric.sessions, target: 2);
      expect(c.progressFor(p), 3);
    });

    test('timeMinutes metric converts timeTodayMs to whole minutes', () {
      final p = Progress()..timeTodayMs = 125000; // 2m5s
      const c = Challenge(title: 't', metric: ChallengeMetric.timeMinutes, target: 5);
      expect(c.progressFor(p), 2);
    });
  });

  test('WeeklyChallenge.progressFor reads sessionsThisWeek', () {
    final p = Progress()..sessionsThisWeek = 4;
    const c = WeeklyChallenge(title: 't', target: 5);
    expect(c.progressFor(p), 4);
  });

  group('dailyChallengeFor', () {
    test('is deterministic for the same day', () {
      final day = DateTime(2026, 3, 15);
      expect(dailyChallengeFor(day).title, dailyChallengeFor(day).title);
    });

    test('cycles through the pool by day-of-year', () {
      final jan1 = dailyChallengeFor(DateTime(2026, 1, 1));
      final jan2 = dailyChallengeFor(DateTime(2026, 1, 2));
      // Adjacent days should generally differ (pool has 6 entries) — not a
      // strict guarantee for every index, but true for day 0 vs day 1.
      expect(jan1.title == jan2.title, isFalse);
    });
  });

  group('weeklyChallengeFor', () {
    test('is deterministic for the same week', () {
      final day = DateTime(2026, 3, 15);
      expect(weeklyChallengeFor(day).title, weeklyChallengeFor(day).title);
    });
  });
}
