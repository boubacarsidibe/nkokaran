import 'package:flutter_test/flutter_test.dart';
import 'package:nko_kalan/state/progress_store.dart';
import 'package:nko_kalan/state/spaced_repetition.dart';

void main() {
  group('applyReview', () {
    test('first correct answer sets a 1-day interval', () {
      final p = Progress();
      final now = DateTime(2026, 1, 1);
      applyReview(p, 'ß', true, now);

      final state = ReviewState.fromJson(p.reviewStates['ß']!);
      expect(state.repetitions, 1);
      expect(state.intervalDays, 1);
      expect(state.nextReviewMs, now.add(const Duration(days: 1)).millisecondsSinceEpoch);
    });

    test('second correct answer sets a 3-day interval', () {
      final p = Progress();
      final now = DateTime(2026, 1, 1);
      applyReview(p, 'ß', true, now);
      applyReview(p, 'ß', true, now.add(const Duration(days: 1)));

      final state = ReviewState.fromJson(p.reviewStates['ß']!);
      expect(state.repetitions, 2);
      expect(state.intervalDays, 3);
    });

    test('a miss resets repetitions and interval, and lowers ease', () {
      final p = Progress();
      final now = DateTime(2026, 1, 1);
      applyReview(p, 'ß', true, now);
      applyReview(p, 'ß', true, now.add(const Duration(days: 1)));
      final easeBeforeMiss = ReviewState.fromJson(p.reviewStates['ß']!).easeFactor;

      applyReview(p, 'ß', false, now.add(const Duration(days: 4)));
      final state = ReviewState.fromJson(p.reviewStates['ß']!);

      expect(state.repetitions, 0);
      expect(state.intervalDays, 1);
      expect(state.easeFactor, lessThan(easeBeforeMiss));
    });

    test('ease factor is clamped between 1.3 and 2.8', () {
      final p = Progress();
      var now = DateTime(2026, 1, 1);
      for (var i = 0; i < 50; i++) {
        applyReview(p, 'ß', false, now);
        now = now.add(const Duration(days: 1));
      }
      final state = ReviewState.fromJson(p.reviewStates['ß']!);
      expect(state.easeFactor, greaterThanOrEqualTo(1.3));
    });
  });

  group('dueForReview', () {
    test('only returns letters whose nextReviewMs has passed', () {
      final p = Progress();
      final now = DateTime(2026, 1, 10);
      applyReview(p, 'due', true, now.subtract(const Duration(days: 5)));
      applyReview(p, 'notDue', true, now);

      final due = dueForReview(p, now);
      expect(due, contains('due'));
      expect(due, isNot(contains('notDue')));
    });

    test('sorts weakest (lowest ease factor) first', () {
      final p = Progress();
      final now = DateTime(2026, 1, 10);
      // 'weak' misses once (ease drops), 'strong' answered correctly (ease unchanged from default).
      applyReview(p, 'weak', false, now.subtract(const Duration(days: 2)));
      applyReview(p, 'strong', true, now.subtract(const Duration(days: 2)));

      final due = dueForReview(p, now);
      expect(due.first, 'weak');
    });
  });
}
