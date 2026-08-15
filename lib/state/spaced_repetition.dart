import 'progress_store.dart';

/// Simplified SM-2 (SuperMemo-2) per letter — feature 29. Not a full
/// implementation (no quality-of-recall grading beyond right/wrong), but the
/// same shape: repetitions grow the interval, a miss resets it.
class ReviewState {
  int repetitions;
  double easeFactor;
  int intervalDays;
  int nextReviewMs;

  ReviewState({
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    required this.nextReviewMs,
  });

  factory ReviewState.fromJson(Map<String, dynamic> json) => ReviewState(
        repetitions: json['repetitions'] ?? 0,
        easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
        intervalDays: json['intervalDays'] ?? 0,
        nextReviewMs: json['nextReviewMs'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'repetitions': repetitions,
        'easeFactor': easeFactor,
        'intervalDays': intervalDays,
        'nextReviewMs': nextReviewMs,
      };
}

/// Updates [progress.reviewStates] for [char] after an answer, SM-2-lite.
void applyReview(Progress progress, String char, bool correct, DateTime now) {
  final existing = progress.reviewStates[char];
  final state = existing != null ? ReviewState.fromJson(existing) : ReviewState(nextReviewMs: now.millisecondsSinceEpoch);

  if (correct) {
    state.repetitions += 1;
    if (state.repetitions == 1) {
      state.intervalDays = 1;
    } else if (state.repetitions == 2) {
      state.intervalDays = 3;
    } else {
      state.intervalDays = (state.intervalDays * state.easeFactor).round().clamp(1, 180);
    }
    state.easeFactor = (state.easeFactor + 0.1).clamp(1.3, 2.8);
  } else {
    state.repetitions = 0;
    state.intervalDays = 1;
    state.easeFactor = (state.easeFactor - 0.25).clamp(1.3, 2.8);
  }
  state.nextReviewMs = now.add(Duration(days: state.intervalDays)).millisecondsSinceEpoch;
  progress.reviewStates[char] = state.toJson();
}

/// Letters due for review right now, weakest (lowest ease factor) first.
List<String> dueForReview(Progress progress, DateTime now) {
  final due = <MapEntry<String, ReviewState>>[];
  for (final entry in progress.reviewStates.entries) {
    final state = ReviewState.fromJson(entry.value);
    if (state.nextReviewMs <= now.millisecondsSinceEpoch) {
      due.add(MapEntry(entry.key, state));
    }
  }
  due.sort((a, b) => a.value.easeFactor.compareTo(b.value.easeFactor));
  return due.map((e) => e.key).toList();
}
