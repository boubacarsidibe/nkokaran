import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/error_reporter.dart';

/// Scoped per signed-in account so switching users on a shared device never
/// shows one account's local cache under another account.
String _storageKey() {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? "anon";
  return "nko_kalan_progress_v1_$uid";
}

const int maxHearts = 5;
// Compressed vs. Duolingo's real-world ~4h regen so the mechanic is
// actually observable during a normal session/demo.
const Duration heartRegenInterval = Duration(minutes: 30);

const int gemsPerLesson = 5;
const int gemsPerfectBonus = 5;
const int heartRefillCost = 100;
const int streakFreezeCost = 200;

const int dailyGoalXp = 30;

/// Multi-tier weekly league (Duolingo-style Bronze→Diamond ladder) — see
/// [ProgressStore.load] for the promotion/demotion rule. Simplified vs. the
/// real product: it's a fixed weekly-XP threshold per tier rather than
/// rank-based top-N/bottom-N among the tier's actual cohort, since that
/// would need a server-side weekly cron job we don't have infra for here.
const leagueTierNames = ["Bronze", "Argent", "Or", "Saphir", "Diamant"];
const int leaguePromotionXp = 150;
const int leagueDemotionXp = 20;

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

  /// Epoch ms of the last local save — used by [ProgressStore] to decide
  /// whether the on-device copy or the cloud copy is newer when syncing
  /// across devices for the same account.
  int updatedAtMs;

  /// Index into [leagueTierNames] — Bronze (0) upward. [leagueWeekXp] is
  /// this calendar week's running total, evaluated for promotion/demotion
  /// by [ProgressStore.load] whenever [leagueWeekKey] rolls over.
  int leagueTier;
  int leagueWeekXp;
  String? leagueWeekKey;

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
    int? updatedAtMs,
    this.leagueTier = 0,
    this.leagueWeekXp = 0,
    this.leagueWeekKey,
  })  : updatedAtMs = updatedAtMs ?? 0,
        completedUnits = completedUnits ?? [],
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
        updatedAtMs: json['updatedAtMs'] ?? 0,
        leagueTier: json['leagueTier'] ?? 0,
        leagueWeekXp: json['leagueWeekXp'] ?? 0,
        leagueWeekKey: json['leagueWeekKey'],
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
        'updatedAtMs': updatedAtMs,
        'leagueTier': leagueTier,
        'leagueWeekXp': leagueWeekXp,
        'leagueWeekKey': leagueWeekKey,
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
    leagueWeekXp += amount;
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

/// Coarse year+week key (week = day-of-year / 7) — good enough to detect
/// "new week" for the weekly challenge without pulling in an ISO-8601 lib.
String _weekKey(DateTime d) {
  final startOfYear = DateTime(d.year, 1, 1);
  final week = d.difference(startOfYear).inDays ~/ 7;
  return "${d.year}-W$week";
}

/// Result of [applySessionCompletion] — the effects the UI layer (chest
/// dialog, summary screen) needs to react to, separate from the mutation
/// itself so the logic can be unit tested without a widget tree.
class SessionOutcome {
  final int gemsEarned;
  final bool perfect;
  final bool unitFirstClear;
  const SessionOutcome({required this.gemsEarned, required this.perfect, required this.unitFirstClear});
}

/// Applies the XP/gems/streak/badge effects of finishing a lesson or
/// practice session directly onto [p]. Pure mutation — no UI, no async, no
/// chest-reward roll (that stays in the caller since it needs a
/// [BuildContext] to show a dialog) — so this can be unit tested in
/// isolation from the widget tree.
SessionOutcome applySessionCompletion(
  Progress p, {
  required bool isPractice,
  required bool isMistakesReview,
  required int sessionXp,
  required int sessionMistakes,
  required String? unitId,
  required List<String> allUnitIds,
  required DateTime now,
  Duration? elapsed,
}) {
  final perfect = sessionMistakes == 0;
  final gemsEarned = isPractice ? 2 : gemsPerLesson + (perfect ? gemsPerfectBonus : 0);

  p.addXp(sessionXp, now);
  p.gems += gemsEarned;
  p.recordSessionCompletion(now);
  if (elapsed != null) {
    p.recordStudyTime(elapsed.inMilliseconds, now);
  }

  if (isMistakesReview) {
    p.weakLetters.clear();
  }

  var unitFirstClear = false;
  if (!isPractice && unitId != null) {
    unitFirstClear = !p.completedUnits.contains(unitId);
    if (unitFirstClear) {
      p.completedUnits = [...p.completedUnits, unitId];
    }
    if (perfect) p.awardBadge("perfectionist");
    if (allUnitIds.every((id) => p.completedUnits.contains(id))) {
      p.awardBadge("nko_graduate");
    }
    checkAndAwardBadges(p);
  }

  return SessionOutcome(gemsEarned: gemsEarned, perfect: perfect, unitFirstClear: unitFirstClear);
}

class ProgressStore {
  static DocumentReference<Map<String, dynamic>>? _cloudDoc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('progress').doc('data');
  }

  static Future<Progress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey());
    var p = Progress();
    if (raw != null) {
      try {
        p = Progress.fromJson(jsonDecode(raw));
      } catch (e, st) {
        // corrupt local cache — fall back to defaults; logged since this
        // means real progress may be lost if the cloud copy is also stale.
        ErrorReporter.report('ProgressStore.load: corrupt local cache', e, st);
      }
    }

    // Cloud merge: whichever copy — this device's or the account's cloud
    // copy from another device — was saved most recently wins, so signing
    // in on a second device picks up progress instead of resetting it.
    final doc = _cloudDoc();
    if (doc != null) {
      try {
        final snap = await doc.get();
        final data = snap.data();
        if (data != null) {
          final cloud = Progress.fromJson(data);
          if (cloud.updatedAtMs > p.updatedAtMs) p = cloud;
        }
      } catch (e, st) {
        // offline or Firestore unreachable — keep the local copy, next save
        // will push it back up once connectivity returns.
        ErrorReporter.report('ProgressStore.load: cloud fetch failed', e, st);
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

    final weekKey = _weekKey(now);
    if (p.leagueWeekKey != null && p.leagueWeekKey != weekKey) {
      // A full week elapsed since the last recorded league week — evaluate
      // last week's XP for promotion/demotion, then start the new week
      // clean. See [leagueTierNames]'s doc comment for why this is a fixed
      // threshold rather than rank-based.
      if (p.leagueWeekXp >= leaguePromotionXp && p.leagueTier < leagueTierNames.length - 1) {
        p.leagueTier += 1;
      } else if (p.leagueWeekXp < leagueDemotionXp && p.leagueTier > 0) {
        p.leagueTier -= 1;
      }
      p.leagueWeekXp = 0;
    }
    p.leagueWeekKey = weekKey;

    p.regenerateHearts(now);
    await save(p);
    return p;
  }

  /// Returns whether the cloud write succeeded (local save always does,
  /// short of disk failure) — most callers ignore this, but a manual
  /// "sync now" action uses it to give the user real feedback instead of
  /// silently swallowing an offline failure like the background saves do.
  static Future<bool> save(Progress p) async {
    p.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(), jsonEncode(p.toJson()));

    final doc = _cloudDoc();
    if (doc == null) return false;
    try {
      await doc.set(p.toJson());
      return true;
    } catch (e, st) {
      // offline — local save already succeeded; the next successful save
      // (or the next app launch) will push this snapshot to the cloud.
      ErrorReporter.report('ProgressStore.save: cloud write failed', e, st);
      return false;
    }
  }

  /// Clears the on-device cache for [uid] — called right before deleting an
  /// account, while the caller still knows its uid (once signed out,
  /// [_storageKey] can no longer resolve to it).
  static Future<void> clearLocalFor(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("nko_kalan_progress_v1_$uid");
  }
}
