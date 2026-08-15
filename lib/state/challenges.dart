import 'progress_store.dart';

enum ChallengeMetric { xp, sessions }

/// A daily or weekly goal shown on Home. The catalog rotates deterministically
/// by date so it's stable within a day/week without needing server state.
class Challenge {
  final String title;
  final ChallengeMetric metric;
  final int target;
  const Challenge({required this.title, required this.metric, required this.target});

  int progressFor(Progress p) {
    switch (metric) {
      case ChallengeMetric.xp:
        return p.xpToday;
      case ChallengeMetric.sessions:
        return p.sessionsToday;
    }
  }
}

class WeeklyChallenge {
  final String title;
  final int target;
  const WeeklyChallenge({required this.title, required this.target});

  int progressFor(Progress p) => p.sessionsThisWeek;
}

const _dailyPool = [
  Challenge(title: "Gagne 50 XP aujourd'hui", metric: ChallengeMetric.xp, target: 50),
  Challenge(title: "Gagne 80 XP aujourd'hui", metric: ChallengeMetric.xp, target: 80),
  Challenge(title: "Termine 2 leçons aujourd'hui", metric: ChallengeMetric.sessions, target: 2),
  Challenge(title: "Termine 3 leçons aujourd'hui", metric: ChallengeMetric.sessions, target: 3),
];

const _weeklyPool = [
  WeeklyChallenge(title: "Termine 5 leçons cette semaine", target: 5),
  WeeklyChallenge(title: "Termine 8 leçons cette semaine", target: 8),
];

Challenge dailyChallengeFor(DateTime day) {
  final dayOfYear = day.difference(DateTime(day.year, 1, 1)).inDays;
  return _dailyPool[dayOfYear % _dailyPool.length];
}

WeeklyChallenge weeklyChallengeFor(DateTime day) {
  final week = day.difference(DateTime(day.year, 1, 1)).inDays ~/ 7;
  return _weeklyPool[week % _weeklyPool.length];
}
