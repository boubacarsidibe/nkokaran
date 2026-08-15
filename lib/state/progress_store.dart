import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _storageKey = "nko_kalan_progress_v1";

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

  int gems;
  int hearts;
  int? nextHeartAtMs;

  int xpToday;
  String? xpTodayDate;

  /// day-key -> xp earned that day, kept for the profile activity view.
  Map<String, int> xpHistory;

  List<String> badges;
  int streakFreezes;

  Progress({
    List<String>? completedUnits,
    this.xp = 0,
    this.streak = 0,
    this.lastActive,
    this.gems = 20,
    int? hearts,
    this.nextHeartAtMs,
    this.xpToday = 0,
    this.xpTodayDate,
    Map<String, int>? xpHistory,
    List<String>? badges,
    this.streakFreezes = 0,
  })  : completedUnits = completedUnits ?? [],
        hearts = hearts ?? maxHearts,
        xpHistory = xpHistory ?? {},
        badges = badges ?? [];

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
        completedUnits: (json['completedUnits'] as List?)?.cast<String>() ?? [],
        xp: json['xp'] ?? 0,
        streak: json['streak'] ?? 0,
        lastActive: json['lastActive'],
        gems: json['gems'] ?? 20,
        hearts: json['hearts'] ?? maxHearts,
        nextHeartAtMs: json['nextHeartAtMs'],
        xpToday: json['xpToday'] ?? 0,
        xpTodayDate: json['xpTodayDate'],
        xpHistory: (json['xpHistory'] as Map?)?.map((k, v) => MapEntry(k as String, v as int)) ?? {},
        badges: (json['badges'] as List?)?.cast<String>() ?? [],
        streakFreezes: json['streakFreezes'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
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
      };

  Progress copy() => Progress.fromJson(toJson());

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

class ProgressStore {
  static Future<Progress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    var p = Progress();
    if (raw != null) {
      try {
        p = Progress.fromJson(jsonDecode(raw));
      } catch (_) {
        // no saved progress yet / corrupt — fall back to defaults
      }
    }

    final now = DateTime.now();
    final today = _dayKey(now);
    if (p.lastActive != today) {
      final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
      if (p.lastActive == yesterday) {
        p.streak = p.streak + 1;
      } else if (p.lastActive != null && p.streakFreezes > 0) {
        // A streak freeze silently covers exactly one missed day.
        p.streakFreezes -= 1;
        p.streak = p.streak + 1;
      } else if (p.lastActive != null) {
        p.streak = 1;
      }
      p.lastActive = today;
    }
    p.regenerateHearts(now);
    await save(p);
    return p;
  }

  static Future<void> save(Progress p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(p.toJson()));
  }
}
