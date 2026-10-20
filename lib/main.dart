import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'models/nko_data.dart';
import 'models/story_data.dart';
import 'screens/auth_screen.dart';
import 'screens/episode_player_screen.dart';
import 'screens/failed_screen.dart';
import 'screens/home_screen.dart';
import 'screens/league_screen.dart';
import 'screens/lesson_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/story_list_screen.dart';
import 'screens/summary_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/social_service.dart';
import 'state/progress_store.dart';
import 'state/spaced_repetition.dart';
import 'theme/app_theme.dart';
import 'widgets/chest_dialog.dart';
import 'widgets/email_verification_banner.dart' show EmailVerificationGateScreen;

// Crashlytics only ships native implementations for Android/iOS/macOS —
// calling it on web/Windows/Linux throws MissingPluginException.
bool get _crashlyticsSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initError;
  try {
    // Timeout: on web the Firebase JS SDK is fetched from the network; offline
    // it would hang forever on a blank page instead of reaching the error screen.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).timeout(const Duration(seconds: 12));
    if (_crashlyticsSupported) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    // Unsupported platform (e.g. this build target has no Firebase config)
    // or unreachable project — surfaced as a blocking error screen instead
    // of a silent anonymous fallback, since auth is now mandatory.
    initError = e.toString();
  }
  // runZonedGuarded catches errors from fire-and-forget async calls (e.g.
  // unawaited _finishSession()) that would otherwise never reach
  // PlatformDispatcher.onError.
  runZonedGuarded(
    () => runApp(NkoKalanApp(initError: initError)),
    (error, stack) {
      if (_crashlyticsSupported) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } else {
        // ignore: avoid_print
        print('Unhandled error: $error\n$stack');
      }
    },
  );
}

class NkoKalanApp extends StatelessWidget {
  final String? initError;
  const NkoKalanApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "N'Ko Kalan",
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: initError != null ? _FirebaseUnavailableScreen(error: initError!) : const AuthGate(),
    );
  }
}

class _FirebaseUnavailableScreen extends StatelessWidget {
  final String error;
  const _FirebaseUnavailableScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 40, color: AppColors.clay),
                const SizedBox(height: 12),
                Text("Connexion indisponible", style: AppText.fraunces(fontSize: 18), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  "N'Ko Kalan a besoin d'un compte pour continuer, mais le service d'authentification "
                  "n'est pas disponible sur cet appareil.\n\n$error",
                  textAlign: TextAlign.center,
                  style: AppText.inter(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Blocks all app content behind a signed-in Firebase user — required since
/// authentication is now mandatory (previously only social features used a
/// silent anonymous sign-in via [SocialService]).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // authStateChanges doesn't fire when only emailVerified changes, so this
  // is flipped manually once EmailVerificationGateScreen confirms it.
  bool _verifiedOverride = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(child: CircularProgressIndicator(color: AppColors.indigo)),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }
        if (!user.emailVerified && !_verifiedOverride) {
          return EmailVerificationGateScreen(onVerified: () => setState(() => _verifiedOverride = true));
        }
        return const NkoKalanRoot();
      },
    );
  }
}

enum _Screen { home, lesson, summary, failed, episode }

enum _Tab { learn, practice, story, league, profile }

class NkoKalanRoot extends StatefulWidget {
  const NkoKalanRoot({super.key});

  @override
  State<NkoKalanRoot> createState() => _NkoKalanRootState();
}

class _NkoKalanRootState extends State<NkoKalanRoot> {
  bool _ready = false;
  Progress _progress = Progress();
  _Screen _screen = _Screen.home;
  _Tab _tab = _Tab.learn;
  Timer? _heartTimer;

  NkoUnit? _activeUnit;
  StoryEpisode? _activeEpisode;
  bool _isPractice = false;
  bool _isMistakesReview = false;
  List<Exercise> _exercises = [];
  int _exIndex = 0;
  int _sessionXp = 0;
  int _sessionMistakes = 0;
  DateTime? _sessionStart;
  dynamic _selected;
  bool _checked = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _heartTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final p = await ProgressStore.load();
    setState(() {
      _progress = p;
      _ready = true;
    });
    NotificationService.instance.scheduleDailyReminder(streak: p.streak, dailyGoalReached: p.dailyGoalReached);
    _heartTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_progress.hearts >= maxHearts) return;
      setState(() => _progress.regenerateHearts(DateTime.now()));
      ProgressStore.save(_progress);
    });
  }

  Future<void> _persist() async {
    await ProgressStore.save(_progress);
  }

  Future<bool> _manualSync() => ProgressStore.save(_progress);

  /// Re-runs whichever session was last started — used by "Rejouer" /
  /// "Réessayer" so every session kind (unit, practice, mistakes, review,
  /// translation) can be replayed, not just the ones backed by a letter list.
  VoidCallback? _restart;

  /// Single entry point for every kind of session. [build] is called again
  /// on replay so each run gets freshly shuffled exercises.
  void _beginSession(
    NkoUnit unit,
    List<Exercise> Function() build, {
    required bool practice,
    bool mistakes = false,
  }) {
    if (_progress.hearts <= 0) {
      _showNoHeartsSnack();
      return;
    }
    final exercises = build();
    if (exercises.isEmpty) return;
    _restart = () => _beginSession(unit, build, practice: practice, mistakes: mistakes);
    setState(() {
      _activeUnit = unit;
      _isPractice = practice;
      _isMistakesReview = mistakes;
      _exercises = exercises;
      _exIndex = 0;
      _sessionXp = 0;
      _sessionMistakes = 0;
      _sessionStart = DateTime.now();
      _selected = null;
      _checked = false;
      _isCorrect = false;
      _screen = _Screen.lesson;
    });
  }

  void _startUnit(NkoUnit unit, bool locked) {
    if (locked) return;
    _beginSession(unit, () => buildExercises(unit), practice: false);
  }

  void _startPractice(NkoUnit unit) {
    _beginSession(unit, () => buildPracticeExercises(unit.letters!, unit.pool!, count: 8), practice: true);
  }

  void _startMistakesPractice() {
    final letters = _progress.weakLetters.map(letterByChar).whereType<NkoLetter>().toList();
    if (letters.isEmpty) return;
    _beginSession(
      const NkoUnit(
        id: "mistakes",
        title: "Révision des erreurs",
        subtitle: "Tes lettres à retravailler",
        letters: null,
        pool: null,
      ),
      () => buildPracticeExercises(letters, allLettersAndDigits, count: letters.length.clamp(4, 10)),
      practice: true,
      mistakes: true,
    );
  }

  void _startDueReview() {
    final due = dueForReview(_progress, DateTime.now()).map(letterByChar).whereType<NkoLetter>().toList();
    if (due.isEmpty) return;
    _beginSession(
      const NkoUnit(
        id: "review",
        title: "Révision espacée",
        subtitle: "Tes lettres à réviser aujourd'hui",
        letters: null,
        pool: null,
      ),
      () => buildPracticeExercises(due, allLettersAndDigits, count: due.length.clamp(4, 10)),
      practice: true,
    );
  }

  void _startTranslationPractice() {
    _beginSession(
      const NkoUnit(
        id: "translation",
        title: "Traduction",
        subtitle: "Mots et phrases dans les deux sens",
        letters: null,
        pool: null,
      ),
      () => shuffle(translationExercises),
      practice: true,
    );
  }

  Future<void> _confirmQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Quitter la leçon ?"),
        content: const Text("Ta progression dans cette leçon sera perdue."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Continuer")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Quitter")),
        ],
      ),
    );
    if (quit == true && mounted) _returnToTab(_isPractice ? _Tab.practice : _Tab.learn);
  }

  void _showNoHeartsSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Plus de cœurs pour l'instant — attends qu'ils se régénèrent ou utilise des gemmes.")),
    );
  }

  void _selectOption(dynamic opt) {
    if (_checked) return;
    setState(() => _selected = opt);
  }

  void _checkAnswer() {
    final cur = _exercises[_exIndex];
    if (_selected == null) return;
    bool ok;
    if (cur.type == ExerciseType.wordBank || cur.type == ExerciseType.dictation) {
      ok = listEquals(_selected as List<String>, cur.wordAnswer);
    } else if (cur.direction == QuizDirection.text) {
      ok = _selected == cur.correctLabel;
    } else {
      ok = (_selected as NkoLetter).char == cur.letter!.char;
    }
    final now = DateTime.now();
    setState(() {
      _isCorrect = ok;
      _checked = true;
      if (ok) {
        // Practice pays half XP so drilling can't out-earn the main path.
        _sessionXp += _isPractice ? 5 : 10;
      } else {
        _sessionMistakes += 1;
        _progress.loseHeart(now);
        if (cur.letter != null) _progress.addWeakLetter(cur.letter!.char);
      }
      if (cur.letter != null) applyReview(_progress, cur.letter!.char, ok, now);
      if (_activeUnit != null) _progress.recordAnswer(unitId: _activeUnit!.id, correct: ok);
    });
    _persist();
  }

  void _completeMatch() {
    setState(() {
      _checked = true;
      _isCorrect = true;
      _sessionXp += 15;
    });
  }

  void _goNext() {
    final cur = _exercises[_exIndex];
    final needsHeart = cur.type == ExerciseType.quiz ||
        cur.type == ExerciseType.wordBank ||
        cur.type == ExerciseType.listening ||
        cur.type == ExerciseType.dictation;
    final failed = needsHeart && !_isCorrect && _progress.hearts <= 0;
    if (failed) {
      setState(() => _screen = _Screen.failed);
      return;
    }
    if (_exIndex + 1 >= _exercises.length) {
      _finishSession();
      return;
    }
    setState(() {
      _exIndex += 1;
      _selected = null;
      _checked = false;
      _isCorrect = false;
    });
  }

  Future<void> _finishSession() async {
    final now = DateTime.now();
    final outcome = applySessionCompletion(
      _progress,
      isPractice: _isPractice,
      isMistakesReview: _isMistakesReview,
      sessionXp: _sessionXp,
      sessionMistakes: _sessionMistakes,
      unitId: _activeUnit?.id,
      allUnitIds: units.map((u) => u.id).toList(),
      now: now,
      elapsed: _sessionStart != null ? now.difference(_sessionStart!) : null,
    );
    _isMistakesReview = false;

    var chestGems = 0;
    var chestXp = 0;
    if (outcome.unitFirstClear && mounted) {
      final reward = ChestReward.random();
      chestGems = reward.gems;
      chestXp = reward.xp;
      _progress.gems += chestGems;
      _progress.addXp(chestXp, now);
      await showChestDialog(context, reward);
      if (!mounted) return;
    }

    // Best-effort: feeds the shared club's weekly goal with real XP only.
    SocialService.instance.contributeToClub(defaultClubId, _sessionXp + chestXp).catchError((_) {});

    setState(() {
      _sessionGems = outcome.gemsEarned + chestGems;
      _sessionXp += chestXp;
      _sessionPerfect = outcome.perfect;
      _screen = _Screen.summary;
    });
    NotificationService.instance.scheduleDailyReminder(streak: _progress.streak, dailyGoalReached: _progress.dailyGoalReached);
    _persist();
  }

  int _sessionGems = 0;
  bool _sessionPerfect = false;

  void _refillHeartsWithGems() {
    if (_progress.gems < heartRefillCost) return;
    setState(() {
      _progress.gems -= heartRefillCost;
      _progress.hearts = maxHearts;
      _progress.nextHeartAtMs = null;
    });
    _persist();
  }

  void _setPreferredDialect(String dialect) {
    setState(() => _progress.preferredDialect = dialect);
    _persist();
  }

  void _buyStreakFreeze() {
    if (_progress.gems < streakFreezeCost) return;
    setState(() {
      _progress.gems -= streakFreezeCost;
      _progress.streakFreezes += 1;
    });
    _persist();
  }

  void _startEpisode(StoryEpisode episode) {
    setState(() {
      _activeEpisode = episode;
      _screen = _Screen.episode;
    });
  }

  Future<void> _finishEpisode() async {
    final episode = _activeEpisode!;
    if (!_progress.completedEpisodes.contains(episode.id)) {
      setState(() => _progress.completedEpisodes = [..._progress.completedEpisodes, episode.id]);
      await _persist();
    }
    _returnToTab(_Tab.story);
  }

  void _returnToTab(_Tab tab) {
    setState(() {
      _screen = _Screen.home;
      _tab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.indigo)),
      );
    }

    switch (_screen) {
      case _Screen.home:
        return PopScope(
          canPop: _tab == _Tab.learn,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) setState(() => _tab = _Tab.learn);
          },
          child: _Shell(
            tab: _tab,
            onTabChanged: (t) => setState(() => _tab = t),
            progress: _progress,
            onStart: _startUnit,
            onHeartsTap: () {
              if (_progress.hearts < maxHearts && _progress.gems >= heartRefillCost) {
                _refillHeartsWithGems();
              } else if (_progress.hearts >= maxHearts) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cœurs déjà au maximum.")),
                );
              } else {
                _showNoHeartsSnack();
              }
            },
            onPractice: _startPractice,
            onPracticeMistakes: _startMistakesPractice,
            onPracticeReview: _startDueReview,
            dueReviewCount: dueForReview(_progress, DateTime.now()).length,
            onPracticeTranslation: _startTranslationPractice,
            onRefillHearts: _refillHeartsWithGems,
            onBuyStreakFreeze: _buyStreakFreeze,
            onPlayEpisode: _startEpisode,
            onDialectChanged: _setPreferredDialect,
            onManualSync: _manualSync,
          ),
        );
      case _Screen.episode:
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _returnToTab(_Tab.story);
          },
          child: EpisodePlayerScreen(
            episode: _activeEpisode!,
            onFinished: _finishEpisode,
            onQuit: () => _returnToTab(_Tab.story),
          ),
        );
      case _Screen.lesson:
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmQuit();
          },
          child: LessonScreen(
            unit: _activeUnit!,
            exercises: _exercises,
            exIndex: _exIndex,
            hearts: _progress.hearts,
            sessionXp: _sessionXp,
            selected: _selected,
            checked: _checked,
            isCorrect: _isCorrect,
            onSelect: _selectOption,
            onCheck: _checkAnswer,
            onNext: _goNext,
            onMatchSolved: _completeMatch,
            onQuit: _confirmQuit,
          ),
        );
      case _Screen.summary:
        return SummaryScreen(
          sessionXp: _sessionXp,
          sessionGems: _sessionGems,
          unit: _activeUnit,
          perfect: _sessionPerfect,
          onHome: () => _returnToTab(_isPractice ? _Tab.practice : _Tab.learn),
          onReplay: () => _restart?.call(),
        );
      case _Screen.failed:
        return FailedScreen(
          gems: _progress.gems,
          onRefillWithGems: () {
            _refillHeartsWithGems();
            // Only resume once the refill actually went through.
            if (_progress.hearts > 0) setState(() => _screen = _Screen.lesson);
          },
          onRetry: () => _restart?.call(),
          onHome: () => _returnToTab(_isPractice ? _Tab.practice : _Tab.learn),
        );
    }
  }
}

class _Shell extends StatelessWidget {
  final _Tab tab;
  final void Function(_Tab) onTabChanged;
  final Progress progress;
  final void Function(NkoUnit, bool) onStart;
  final VoidCallback onHeartsTap;
  final void Function(NkoUnit) onPractice;
  final VoidCallback onPracticeMistakes;
  final VoidCallback onPracticeReview;
  final int dueReviewCount;
  final VoidCallback onPracticeTranslation;
  final VoidCallback onRefillHearts;
  final VoidCallback onBuyStreakFreeze;
  final void Function(StoryEpisode) onPlayEpisode;
  final void Function(String) onDialectChanged;
  final Future<bool> Function() onManualSync;

  const _Shell({
    required this.tab,
    required this.onTabChanged,
    required this.progress,
    required this.onStart,
    required this.onHeartsTap,
    required this.onPractice,
    required this.onPracticeMistakes,
    required this.onPracticeReview,
    required this.dueReviewCount,
    required this.onPracticeTranslation,
    required this.onRefillHearts,
    required this.onBuyStreakFreeze,
    required this.onPlayEpisode,
    required this.onDialectChanged,
    required this.onManualSync,
  });

  @override
  Widget build(BuildContext context) {
    late Widget body;
    switch (tab) {
      case _Tab.learn:
        body = HomeScreen(progress: progress, onStart: onStart, onHeartsTap: onHeartsTap);
        break;
      case _Tab.practice:
        body = PracticeScreen(
          progress: progress,
          onPractice: onPractice,
          onPracticeMistakes: onPracticeMistakes,
          onPracticeReview: onPracticeReview,
          dueReviewCount: dueReviewCount,
          onPracticeTranslation: onPracticeTranslation,
        );
        break;
      case _Tab.story:
        body = StoryListScreen(progress: progress, onPlay: onPlayEpisode);
        break;
      case _Tab.league:
        body = LeagueScreen(progress: progress);
        break;
      case _Tab.profile:
        body = ProfileScreen(
          progress: progress,
          onRefillHearts: onRefillHearts,
          onBuyStreakFreeze: onBuyStreakFreeze,
          onDialectChanged: onDialectChanged,
          onPracticeUnit: onPractice,
          onManualSync: onManualSync,
        );
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: body,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(icon: Icons.route, label: "Parcours", selected: tab == _Tab.learn, onTap: () => onTabChanged(_Tab.learn)),
              _NavItem(
                  icon: Icons.fitness_center, label: "Entraîner", selected: tab == _Tab.practice, onTap: () => onTabChanged(_Tab.practice)),
              _NavItem(icon: Icons.auto_stories, label: "Histoires", selected: tab == _Tab.story, onTap: () => onTabChanged(_Tab.story)),
              _NavItem(icon: Icons.emoji_events, label: "Ligue", selected: tab == _Tab.league, onTap: () => onTabChanged(_Tab.league)),
              _NavItem(icon: Icons.person, label: "Profil", selected: tab == _Tab.profile, onTap: () => onTabChanged(_Tab.profile)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.indigo : AppColors.ink.withValues(alpha: 0.45);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(label, style: AppText.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
