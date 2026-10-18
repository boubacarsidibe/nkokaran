import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _storageKey = "nko_kalan_progress_v1";
const _corruptBackupKey = "nko_kalan_progress_corrupt_backup";

/// Bumped whenever the saved JSON shape changes in a way [Progress.fromJson]
/// can't absorb with defaults — lets a future migration branch on it.
const int progressSchemaVersion = 1;

const int maxHearts = 5;
// Compressed vs. Duolingo's real-world ~4h regen so the mechanic is
// actually observable during a normal session/demo.
const Duration heartRegenInterval = Duration(minutes: 30);

const int gemsPerLesson = 5;
const int gemsPerfectBonus = 5;
const int heartRefillCost = 100;
const int streakFreezeCost = 200;

const int dailyGoalXp = 30;

class Progress {
  List<String> completedUnits;
  int xp;
  int streak;
  String? lastActive;

  /// Last day a lesson/practice session was actually completed — the streak
  /// only moves on study, never on merely opening the app.
  String? lastStudyDay;

  int gems;
  int hearts;
  int? nextHeartAtMs;

  int xpToday;
  String? xpTodayDate;

  /// day-key -> xp earned that day, kept for the profile activity view.
  Map<String, int> xpHistory;

  List<String> badges;
  int streakFreezes;

  /// Chars of letters most recently missed in a lesson — backs the
  /// Practice hub's "review my mistakes" entry, mirroring Duolingo's
  /// mistakes inbox.
  List<String> weakLetters;

  /// Sessions (lesson or practice) completed today/this week — backs the
  /// daily/weekly challenge cards, independent of unit-completion state.
  int sessionsToday;
  String? sessionsTodayDate;
  int sessionsThisWeek;
  String? sessionsWeekKey;

  /// Episode ids finished in the narrative "Saison" track — kept separate
  /// from [completedUnits] since the two tracks don't gate each other.
  List<String> completedEpisodes;

  /// "maninka" / "bambara" / "dioula" — used to pick which dialect variant
  /// to surface when content offers more than one (feature 28).
  String preferredDialect;

  /// SM-2-lite spaced-repetition state per letter char — see
  /// lib/state/spaced_repetition.dart (feature 29).
  Map<String, Map<String, dynamic>> reviewStates;

  /// Cumulative time spent in lessons/practice, in milliseconds — feeds the
  /// stats screen (feature 30).
  int totalTimeMs;
  int totalAnswered;
  int totalCorrect;

  /// Time spent today, in milliseconds — backs the time-based daily
  /// challenge, reset like [xpToday] at local midnight.
  int timeTodayMs;
  String? timeTodayDate;

  /// unitId -> attempts/correct, for the per-unit accuracy breakdown.
  Map<String, int> unitAttempts;
  Map<String, int> unitCorrect;

  Progress({
    List<String>? completedUnits,
    this.xp = 0,
    this.streak = 0,
    this.lastActive,
    this.lastStudyDay,
    this.gems = 20,
    int? hearts,
    this.nextHeartAtMs,
    this.xpToday = 0,
    this.xpTodayDate,
    Map<String, int>? xpHistory,
    List<String>? badges,
    this.streakFreezes = 0,
    List<String>? weakLetters,
    this.sessionsToday = 0,
    this.sessionsTodayDate,
    this.sessionsThisWeek = 0,
    this.sessionsWeekKey,
    List<String>? completedEpisodes,
    this.preferredDialect = "maninka",
    Map<String, Map<String, dynamic>>? reviewStates,
    this.totalTimeMs = 0,
    this.totalAnswered = 0,
    this.totalCorrect = 0,
    this.timeTodayMs = 0,
    this.timeTodayDate,
    Map<String, int>? unitAttempts,
    Map<String, int>? unitCorrect,
  })  : completedUnits = completedUnits ?? [],
        hearts = hearts ?? maxHearts,
        xpHistory = xpHistory ?? {},
        badges = badges ?? [],
        weakLetters = weakLetters ?? [],
        completedEpisodes = completedEpisodes ?? [],
        reviewStates = reviewStates ?? {},
        unitAttempts = unitAttempts ?? {},
        unitCorrect = unitCorrect ?? {};

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
        completedUnits: (json['completedUnits'] as List?)?.cast<String>() ?? [],
        xp: json['xp'] ?? 0,
        streak: json['streak'] ?? 0,
        lastActive: json['lastActive'],
        // Saves from before this field existed: fall back to lastActive.
        lastStudyDay: json['lastStudyDay'] ?? json['lastActive'],
        gems: json['gems'] ?? 20,
        hearts: json['hearts'] ?? maxHearts,
        nextHeartAtMs: json['nextHeartAtMs'],
        xpToday: json['xpToday'] ?? 0,
        xpTodayDate: json['xpTodayDate'],
        xpHistory: (json['xpHistory'] as Map?)?.map((k, v) => MapEntry(k as String, v as int)) ?? {},
        badges: (json['badges'] as List?)?.cast<String>() ?? [],
        streakFreezes: json['streakFreezes'] ?? 0,
        weakLetters: (json['weakLetters'] as List?)?.cast<String>() ?? [],
        sessionsToday: json['sessionsToday'] ?? 0,
        sessionsTodayDate: json['sessionsTodayDate'],
        sessionsThisWeek: json['sessionsThisWeek'] ?? 0,
        sessionsWeekKey: json['sessionsWeekKey'],
        completedEpisodes: (json['completedEpisodes'] as List?)?.cast<String>() ?? [],
        preferredDialect: json['preferredDialect'] ?? "maninka",
        reviewStates: (json['reviewStates'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as Map).cast<String, dynamic>()),
            ) ??
            {},
        totalTimeMs: json['totalTimeMs'] ?? 0,
        totalAnswered: json['totalAnswered'] ?? 0,
        totalCorrect: json['totalCorrect'] ?? 0,
        timeTodayMs: json['timeTodayMs'] ?? 0,
        timeTodayDate: json['timeTodayDate'],
        unitAttempts: (json['unitAttempts'] as Map?)?.map((k, v) => MapEntry(k as String, v as int)) ?? {},
        unitCorrect: (json['unitCorrect'] as Map?)?.map((k, v) => MapEntry(k as String, v as int)) ?? {},
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': progressSchemaVersion,
        'lastStudyDay': lastStudyDay,
        'completedUnits': completedUnits,
        'xp': xp,
        'streak': streak,
        'lastActive': lastActive,
        'gems': gems,
        'hearts': hearts,
        'nextHeartAtMs': nextHeartAtMs,
        'xpToday': xpToday,
        'xpTodayDate': xpTodayDate,
        'xpHistory': xpHistory,
        'badges': badges,
        'streakFreezes': streakFreezes,
        'weakLetters': weakLetters,
        'sessionsToday': sessionsToday,
        'sessionsTodayDate': sessionsTodayDate,
        'sessionsThisWeek': sessionsThisWeek,
        'sessionsWeekKey': sessionsWeekKey,
        'completedEpisodes': completedEpisodes,
        'preferredDialect': preferredDialect,
        'reviewStates': reviewStates,
        'totalTimeMs': totalTimeMs,
        'totalAnswered': totalAnswered,
        'totalCorrect': totalCorrect,
        'timeTodayMs': timeTodayMs,
        'timeTodayDate': timeTodayDate,
        'unitAttempts': unitAttempts,
        'unitCorrect': unitCorrect,
      };

  Progress copy() => Progress.fromJson(toJson());

  /// Called when the app opens. Resolves missed days: each streak freeze
  /// covers exactly one missed day; if the gap is larger than the freezes
  /// available, the streak is lost.
  void settleStreak(DateTime now) {
    final last = lastStudyDay == null ? null : _parseDayKey(lastStudyDay!);
    if (last == null || streak == 0) return;
    final missed = _daysBetween(last, now) - 1;
    if (missed <= 0) return;
    if (streakFreezes >= missed) {
      streakFreezes -= missed;
      // Pretend yesterday was studied so the next session continues the run.
      lastStudyDay = _dayKey(now.subtract(const Duration(days: 1)));
    } else {
      streak = 0;
    }
  }

  /// Called once per finished session: advances the streak at most once a day.
  void recordStudyDay(DateTime now) {
    final today = _dayKey(now);
    if (lastStudyDay == today) return;
    final last = lastStudyDay == null ? null : _parseDayKey(lastStudyDay!);
    streak = (last != null && _daysBetween(last, now) == 1) ? streak + 1 : 1;
    lastStudyDay = today;
  }

  bool get dailyGoalReached => xpToday >= dailyGoalXp;

  /// Regenerates hearts against wall-clock time — hearts refill even while
  /// the app is closed, matching Duolingo's persistent-heart model instead
  /// of a per-lesson pool.
  void regenerateHearts(DateTime now) {
    if (hearts >= maxHearts) {
      nextHeartAtMs = null;
      return;
    }
    if (nextHeartAtMs == null) {
      nextHeartAtMs = now.millisecondsSinceEpoch + heartRegenInterval.inMilliseconds;
      return;
    }
    while (hearts < maxHearts && now.millisecondsSinceEpoch >= nextHeartAtMs!) {
      hearts += 1;
      nextHeartAtMs = nextHeartAtMs! + heartRegenInterval.inMilliseconds;
    }
    if (hearts >= maxHearts) nextHeartAtMs = null;
  }

  void loseHeart(DateTime now) {
    if (hearts <= 0) return;
    hearts -= 1;
    nextHeartAtMs ??= now.millisecondsSinceEpoch + heartRegenInterval.inMilliseconds;
  }

  void addXp(int amount, DateTime now) {
    final today = _dayKey(now);
    if (xpTodayDate != today) {
      xpTodayDate = today;
      xpToday = 0;
    }
    xp += amount;
    xpToday += amount;
    xpHistory[today] = (xpHistory[today] ?? 0) + amount;
  }

  void awardBadge(String id) {
    if (!badges.contains(id)) badges.add(id);
  }

  void addWeakLetter(String char) {
    weakLetters.remove(char);
    weakLetters.add(char);
    if (weakLetters.length > 30) weakLetters.removeAt(0);
  }

  /// Bumps the daily/weekly session counters that back the challenge cards.
  /// Called once per finished lesson or practice session.
  void recordSessionCompletion(DateTime now) {
    final today = _dayKey(now);
    if (sessionsTodayDate != today) {
      sessionsTodayDate = today;
      sessionsToday = 0;
    }
    sessionsToday += 1;

    final week = _weekKey(now);
    if (sessionsWeekKey != week) {
      sessionsWeekKey = week;
      sessionsThisWeek = 0;
    }
    sessionsThisWeek += 1;
  }

  /// Adds elapsed session time to both the cumulative total (stats screen)
  /// and today's running total (time-based daily challenge), resetting the
  /// latter at local midnight like [xpToday].
  void recordStudyTime(int ms, DateTime now) {
    totalTimeMs += ms;
    final today = _dayKey(now);
    if (timeTodayDate != today) {
      timeTodayDate = today;
      timeTodayMs = 0;
    }
    timeTodayMs += ms;
  }

  /// Records one answered exercise for the stats screen's global and
  /// per-unit accuracy breakdown.
  void recordAnswer({required String unitId, required bool correct}) {
    totalAnswered += 1;
    unitAttempts[unitId] = (unitAttempts[unitId] ?? 0) + 1;
    if (correct) {
      totalCorrect += 1;
      unitCorrect[unitId] = (unitCorrect[unitId] ?? 0) + 1;
    }
  }

  double get accuracy => totalAnswered == 0 ? 0 : totalCorrect / totalAnswered;

  double accuracyForUnit(String unitId) {
    final attempts = unitAttempts[unitId] ?? 0;
    if (attempts == 0) return 0;
    return (unitCorrect[unitId] ?? 0) / attempts;
  }
}

/// Cumulative XP required to *reach* each level — level 1 starts at 0 XP.
/// Gaps grow so later levels take meaningfully longer, mirroring Duolingo's
/// account-level curve without needing a closed-form formula.
const List<int> _levelThresholds = [
  0, 50, 120, 220, 360, 550, 800, 1120, 1520, 2010,
  2600, 3300, 4120, 5070, 6160, 7400, 8800, 10370, 12120, 14060,
];

int levelForXp(int xp) {
  var level = 1;
  for (var i = 0; i < _levelThresholds.length; i++) {
    if (xp >= _levelThresholds[i]) {
      level = i + 1;
    } else {
      break;
    }
  }
  return level;
}

/// XP needed to reach the next level, or null once past the curve's tail.
int? xpForNextLevel(int xp) {
  final level = levelForXp(xp);
  if (level >= _levelThresholds.length) return null;
  return _levelThresholds[level];
}

const List<String> badgeFirstLesson = ["first_lesson", "Premiers pas", "Termine ta première leçon"];
const List<String> badgeWeekStreak = ["week_streak", "Une semaine", "7 jours de suite"];
const List<String> badgeAlphabet = ["alphabet_complete", "Alphabet complet", "Maîtrise toutes les lettres"];

/// Checks unlock conditions against the given progress snapshot and awards
/// any newly-earned badges in place. Called after every persisted change.
void checkAndAwardBadges(Progress p) {
  if (p.completedUnits.isNotEmpty) {
    p.awardBadge(badgeFirstLesson[0]);
  }
  if (p.streak >= 7) {
    p.awardBadge(badgeWeekStreak[0]);
  }
  const alphabetUnits = ["u1", "u2", "u3", "u4", "u5", "u6"];
  if (alphabetUnits.every((id) => p.completedUnits.contains(id))) {
    p.awardBadge(badgeAlphabet[0]);
  }
}

/// Day string in the same shape as JS `Date().toDateString()` — a stable
/// day key that only changes at local midnight.
String _dayKey(DateTime d) => "${d.year}-${d.month}-${d.day}";

DateTime? _parseDayKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]), m = int.tryParse(parts[1]), d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// Whole calendar days from [a] to [b] (DST-safe: compares date parts only).
int _daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// Coarse year+week key (week = day-of-year / 7) — good enough to detect
/// "new week" for the weekly challenge without pulling in an ISO-8601 lib.
String _weekKey(DateTime d) {
  final startOfYear = DateTime(d.year, 1, 1);
  final week = d.difference(startOfYear).inDays ~/ 7;
  return "${d.year}-W$week";
}

class ProgressStore {
  static Future<Progress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    var p = Progress();
    if (raw != null) {
      try {
        p = Progress.fromJson(jsonDecode(raw));
      } catch (_) {
        // Unreadable save: keep the raw text aside instead of letting the
        // fresh defaults overwrite (and permanently destroy) it.
        await prefs.setString(_corruptBackupKey, raw);
      }
    }

    final now = DateTime.now();
    p.lastActive = _dayKey(now);
    p.settleStreak(now);
    p.regenerateHearts(now);
    await save(p);
    return p;
  }

  static Future<void> save(Progress p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(p.toJson()));
  }
}
