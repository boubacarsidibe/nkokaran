import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'models/nko_data.dart';
import 'models/story_data.dart';
import 'screens/episode_player_screen.dart';
import 'screens/failed_screen.dart';
import 'screens/home_screen.dart';
import 'screens/league_screen.dart';
import 'screens/lesson_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/story_list_screen.dart';
import 'screens/summary_screen.dart';
import 'state/progress_store.dart';
import 'theme/app_theme.dart';
import 'widgets/chest_dialog.dart';

void main() {
  runApp(const NkoKalanApp());
}

class NkoKalanApp extends StatelessWidget {
  const NkoKalanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "N'Ko Kalan",
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const NkoKalanRoot(),
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
    _heartTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _progress.regenerateHearts(DateTime.now()));
      ProgressStore.save(_progress);
    });
  }

  Future<void> _persist() async {
    await ProgressStore.save(_progress);
  }

  void _startUnit(NkoUnit unit, bool locked) {
    if (locked) return;
    if (_progress.hearts <= 0) {
      _showNoHeartsSnack();
      return;
    }
    setState(() {
      _activeUnit = unit;
      _isPractice = false;
      _isMistakesReview = false;
      _exercises = buildExercises(unit);
      _exIndex = 0;
      _sessionXp = 0;
      _sessionMistakes = 0;
      _selected = null;
      _checked = false;
      _isCorrect = false;
      _screen = _Screen.lesson;
    });
  }

  void _startPractice(NkoUnit unit) {
    if (_progress.hearts <= 0) {
      _showNoHeartsSnack();
      return;
    }
    setState(() {
      _activeUnit = unit;
      _isPractice = true;
      _isMistakesReview = false;
      _exercises = buildPracticeExercises(unit.letters!, unit.pool!, count: 8);
      _exIndex = 0;
      _sessionXp = 0;
      _sessionMistakes = 0;
      _selected = null;
      _checked = false;
      _isCorrect = false;
      _screen = _Screen.lesson;
    });
  }

  void _startMistakesPractice() {
    if (_progress.hearts <= 0) {
      _showNoHeartsSnack();
      return;
    }
    final letters = _progress.weakLetters.map(letterByChar).whereType<NkoLetter>().toList();
    if (letters.isEmpty) return;
    setState(() {
      _activeUnit = const NkoUnit(
        id: "mistakes",
        title: "Révision des erreurs",
        subtitle: "Tes lettres à retravailler",
        letters: null,
        pool: null,
      );
      _isPractice = true;
      _isMistakesReview = true;
      _exercises = buildPracticeExercises(letters, allLettersAndDigits, count: letters.length.clamp(4, 10));
      _exIndex = 0;
      _sessionXp = 0;
      _sessionMistakes = 0;
      _selected = null;
      _checked = false;
      _isCorrect = false;
      _screen = _Screen.lesson;
    });
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
    setState(() {
      _isCorrect = ok;
      _checked = true;
      if (ok) {
        _sessionXp += 10;
      } else {
        _sessionMistakes += 1;
        _progress.loseHeart(DateTime.now());
        if (cur.letter != null) _progress.addWeakLetter(cur.letter!.char);
      }
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
    final perfect = _sessionMistakes == 0;
    final gemsEarned = _isPractice
        ? 2
        : gemsPerLesson + (perfect ? gemsPerfectBonus : 0);

    _progress.addXp(_sessionXp, now);
    _progress.gems += gemsEarned;
    _progress.recordSessionCompletion(now);

    if (_isMistakesReview) {
      _progress.weakLetters.clear();
      _isMistakesReview = false;
    }

    var unitFirstClear = false;
    if (!_isPractice) {
      unitFirstClear = !_progress.completedUnits.contains(_activeUnit!.id);
      if (unitFirstClear) {
        _progress.completedUnits = [..._progress.completedUnits, _activeUnit!.id];
      }
      if (perfect) _progress.awardBadge("perfectionist");
      if (units.every((u) => _progress.completedUnits.contains(u.id))) {
        _progress.awardBadge("nko_graduate");
      }
      checkAndAwardBadges(_progress);
    }

    var chestGems = 0;
    var chestXp = 0;
    if (unitFirstClear && mounted) {
      final reward = ChestReward.random();
      chestGems = reward.gems;
      chestXp = reward.xp;
      _progress.gems += chestGems;
      _progress.addXp(chestXp, now);
      await showChestDialog(context, reward);
    }

    setState(() {
      _sessionGems = gemsEarned + chestGems;
      _sessionXp += chestXp;
      _sessionPerfect = perfect;
      _screen = _Screen.summary;
    });
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
        return _Shell(
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
          onRefillHearts: _refillHeartsWithGems,
          onBuyStreakFreeze: _buyStreakFreeze,
          onPlayEpisode: _startEpisode,
        );
      case _Screen.episode:
        return EpisodePlayerScreen(
          episode: _activeEpisode!,
          onFinished: _finishEpisode,
          onQuit: () => _returnToTab(_Tab.story),
        );
      case _Screen.lesson:
        return LessonScreen(
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
          onQuit: () => _returnToTab(_isPractice ? _Tab.practice : _Tab.learn),
        );
      case _Screen.summary:
        return SummaryScreen(
          sessionXp: _sessionXp,
          sessionGems: _sessionGems,
          unit: _activeUnit,
          perfect: _sessionPerfect,
          onHome: () => _returnToTab(_isPractice ? _Tab.practice : _Tab.learn),
          onReplay: () => _isPractice ? _startPractice(_activeUnit!) : _startUnit(_activeUnit!, false),
        );
      case _Screen.failed:
        return FailedScreen(
          gems: _progress.gems,
          onRefillWithGems: () {
            _refillHeartsWithGems();
            setState(() => _screen = _Screen.lesson);
          },
          onRetry: () => _isPractice ? _startPractice(_activeUnit!) : _startUnit(_activeUnit!, false),
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
  final VoidCallback onRefillHearts;
  final VoidCallback onBuyStreakFreeze;
  final void Function(StoryEpisode) onPlayEpisode;

  const _Shell({
    required this.tab,
    required this.onTabChanged,
    required this.progress,
    required this.onStart,
    required this.onHeartsTap,
    required this.onPractice,
    required this.onPracticeMistakes,
    required this.onRefillHearts,
    required this.onBuyStreakFreeze,
    required this.onPlayEpisode,
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
        );
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: body,
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
              _NavItem(icon: Icons.fitness_center, label: "Entraîner", selected: tab == _Tab.practice, onTap: () => onTabChanged(_Tab.practice)),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: AppText.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
