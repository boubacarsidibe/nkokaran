import 'package:flutter_test/flutter_test.dart';
import 'package:nko_kalan/state/progress_store.dart';

void main() {
  group('Progress.addXp', () {
    test('accumulates xp and resets the daily counter on a new day', () {
      final p = Progress();
      final day1 = DateTime(2026, 1, 1, 10);
      final day2 = DateTime(2026, 1, 2, 9);

      p.addXp(20, day1);
      p.addXp(10, day1);
      expect(p.xp, 30);
      expect(p.xpToday, 30);

      p.addXp(5, day2);
      expect(p.xp, 35);
      expect(p.xpToday, 5, reason: 'xpToday resets when the day key changes');
    });
  });

  group('Progress.regenerateHearts', () {
    test('does nothing when already full', () {
      final p = Progress();
      final now = DateTime(2026, 1, 1);
      p.regenerateHearts(now);
      expect(p.hearts, maxHearts);
      expect(p.nextHeartAtMs, isNull);
    });

    test('refills one heart per elapsed interval, capped at max', () {
      final p = Progress()..hearts = 2;
      final start = DateTime(2026, 1, 1, 0, 0);
      p.nextHeartAtMs = start.millisecondsSinceEpoch;

      final muchLater = start.add(heartRegenInterval * 10);
      p.regenerateHearts(muchLater);

      expect(p.hearts, maxHearts);
      expect(p.nextHeartAtMs, isNull);
    });
  });

  group('Progress.loseHeart', () {
    test('never goes below zero', () {
      final p = Progress()..hearts = 0;
      p.loseHeart(DateTime(2026, 1, 1));
      expect(p.hearts, 0);
    });

    test('starts the regen timer on the first loss', () {
      final p = Progress();
      final now = DateTime(2026, 1, 1);
      p.loseHeart(now);
      expect(p.hearts, maxHearts - 1);
      expect(p.nextHeartAtMs, now.millisecondsSinceEpoch + heartRegenInterval.inMilliseconds);
    });
  });

  group('applySessionCompletion', () {
    test('a perfect lesson awards base + bonus gems and clears the unit', () {
      final p = Progress();
      final now = DateTime(2026, 1, 1);

      final outcome = applySessionCompletion(
        p,
        isPractice: false,
        isMistakesReview: false,
        sessionXp: 40,
        sessionMistakes: 0,
        unitId: 'u1',
        allUnitIds: ['u1', 'u2'],
        now: now,
      );

      expect(outcome.perfect, isTrue);
      expect(outcome.unitFirstClear, isTrue);
      expect(outcome.gemsEarned, gemsPerLesson + gemsPerfectBonus);
      expect(p.xp, 40);
      expect(p.gems, 20 + gemsPerLesson + gemsPerfectBonus);
      expect(p.completedUnits, contains('u1'));
      expect(p.badges, contains('perfectionist'));
      expect(p.badges, contains('first_lesson'));
    });

    test('a lesson with mistakes gets no perfect bonus and no perfectionist badge', () {
      final p = Progress();
      final outcome = applySessionCompletion(
        p,
        isPractice: false,
        isMistakesReview: false,
        sessionXp: 10,
        sessionMistakes: 2,
        unitId: 'u1',
        allUnitIds: ['u1', 'u2'],
        now: DateTime(2026, 1, 1),
      );

      expect(outcome.perfect, isFalse);
      expect(outcome.gemsEarned, gemsPerLesson);
      expect(p.badges, isNot(contains('perfectionist')));
    });

    test('replaying an already-completed unit is not a first clear', () {
      final p = Progress()..completedUnits = ['u1'];
      final outcome = applySessionCompletion(
        p,
        isPractice: false,
        isMistakesReview: false,
        sessionXp: 10,
        sessionMistakes: 0,
        unitId: 'u1',
        allUnitIds: ['u1', 'u2'],
        now: DateTime(2026, 1, 1),
      );
      expect(outcome.unitFirstClear, isFalse);
      expect(p.completedUnits, ['u1']);
    });

    test('finishing every unit awards the graduate badge', () {
      final p = Progress()..completedUnits = ['u1'];
      applySessionCompletion(
        p,
        isPractice: false,
        isMistakesReview: false,
        sessionXp: 10,
        sessionMistakes: 0,
        unitId: 'u2',
        allUnitIds: ['u1', 'u2'],
        now: DateTime(2026, 1, 1),
      );
      expect(p.badges, contains('nko_graduate'));
    });

    test('practice sessions earn a flat 2 gems and never touch completedUnits', () {
      final p = Progress();
      final outcome = applySessionCompletion(
        p,
        isPractice: true,
        isMistakesReview: false,
        sessionXp: 10,
        sessionMistakes: 0,
        unitId: 'u1',
        allUnitIds: ['u1'],
        now: DateTime(2026, 1, 1),
      );
      expect(outcome.gemsEarned, 2);
      expect(outcome.unitFirstClear, isFalse);
      expect(p.completedUnits, isEmpty);
    });

    test('a mistakes-review session clears weakLetters', () {
      final p = Progress()..weakLetters = ['ß', 'ß'];
      applySessionCompletion(
        p,
        isPractice: true,
        isMistakesReview: true,
        sessionXp: 0,
        sessionMistakes: 0,
        unitId: null,
        allUnitIds: [],
        now: DateTime(2026, 1, 1),
      );
      expect(p.weakLetters, isEmpty);
    });

    test('elapsed time is added to totalTimeMs and timeTodayMs', () {
      final p = Progress();
      applySessionCompletion(
        p,
        isPractice: true,
        isMistakesReview: false,
        sessionXp: 0,
        sessionMistakes: 0,
        unitId: null,
        allUnitIds: [],
        now: DateTime(2026, 1, 1),
        elapsed: const Duration(minutes: 3),
      );
      expect(p.totalTimeMs, const Duration(minutes: 3).inMilliseconds);
      expect(p.timeTodayMs, const Duration(minutes: 3).inMilliseconds);
    });
  });

  group('checkAndAwardBadges', () {
    test('awards the week-streak badge at 7 days', () {
      final p = Progress()..streak = 7;
      checkAndAwardBadges(p);
      expect(p.badges, contains(badgeWeekStreak[0]));
    });

    test('awards the alphabet badge once all alphabet units are complete', () {
      final p = Progress()..completedUnits = ['u1', 'u2', 'u3', 'u4', 'u5', 'u6'];
      checkAndAwardBadges(p);
      expect(p.badges, contains(badgeAlphabet[0]));
    });
  });

  group('levelForXp / xpForNextLevel', () {
    test('level 1 at 0 xp, increases with thresholds', () {
      expect(levelForXp(0), 1);
      expect(levelForXp(49), 1);
      expect(levelForXp(50), 2);
    });

    test('xpForNextLevel returns the next threshold, null past the curve', () {
      expect(xpForNextLevel(0), 50);
      expect(xpForNextLevel(1000000), isNull);
    });
  });
}
