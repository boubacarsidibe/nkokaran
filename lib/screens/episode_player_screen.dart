import 'package:flutter/material.dart';
import '../models/culture_data.dart';
import '../models/story_data.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';

/// Visual-novel-style episode reader: one dialogue line at a time, with a
/// toggle for bilingual (N'Ko + French) vs. N'Ko-only subtitles, branching
/// choices where the script calls for them, then a comprehension quiz.
class EpisodePlayerScreen extends StatefulWidget {
  final StoryEpisode episode;
  final VoidCallback onFinished;
  final VoidCallback onQuit;

  const EpisodePlayerScreen({
    super.key,
    required this.episode,
    required this.onFinished,
    required this.onQuit,
  });

  @override
  State<EpisodePlayerScreen> createState() => _EpisodePlayerScreenState();
}

class _EpisodePlayerScreenState extends State<EpisodePlayerScreen> {
  late String _currentId;
  late List<ComprehensionQuestion> _quiz;
  bool _bilingual = true;
  bool _inQuiz = false;
  int _quizIndex = 0;
  String? _quizSelected;
  bool _quizChecked = false;
  int _quizCorrectCount = 0;

  @override
  void initState() {
    super.initState();
    _currentId = widget.episode.startId;
    // Comprehension questions first, then a vocab drill built from the
    // episode's own vocabulary — feature "episode-vocab exercises".
    _quiz = [...widget.episode.quiz, ...buildVocabQuestions(widget.episode)];
  }

  void _advance(String nextId) {
    setState(() => _currentId = nextId);
  }

  void _startQuiz() {
    setState(() {
      _inQuiz = true;
      _quizIndex = 0;
      _quizSelected = null;
      _quizChecked = false;
      _quizCorrectCount = 0;
    });
  }

  void _selectQuizOption(String opt) {
    if (_quizChecked) return;
    setState(() => _quizSelected = opt);
  }

  void _checkQuiz() {
    final q = _quiz[_quizIndex];
    setState(() {
      _quizChecked = true;
      if (_quizSelected == q.correctLabel) _quizCorrectCount += 1;
    });
  }

  Future<void> _nextQuizQuestion() async {
    if (_quizIndex + 1 >= _quiz.length) {
      final total = _quiz.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Compréhension : $_quizCorrectCount / $total bonnes réponses")),
      );
      final card = cultureCardForEpisode(widget.episode.id);
      if (card != null) await _showCultureCard(card);
      widget.onFinished();
      return;
    }
    setState(() {
      _quizIndex += 1;
      _quizSelected = null;
      _quizChecked = false;
    });
  }

  /// Feature 22 — short culture note shown once the episode wraps up.
  Future<void> _showCultureCard(CultureCard card) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.public, color: AppColors.clay),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Le sais-tu ?", style: AppText.fraunces(fontSize: 18))),
                ],
              ),
              const SizedBox(height: 10),
              Text(card.title, style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(card.body, style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.75)).copyWith(height: 1.5)),
              const SizedBox(height: 18),
              PrimaryButtonWide(label: "Continuer", icon: Icons.check, onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _Header(
                  title: widget.episode.title,
                  bilingual: _bilingual,
                  onToggleBilingual: () => setState(() => _bilingual = !_bilingual),
                  onQuit: widget.onQuit,
                ),
                Expanded(
                  child: _inQuiz ? _buildQuiz() : _buildDialogue(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogue() {
    final line = widget.episode.lines[_currentId]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.indigo,
                    child: Text(line.speaker.name[0],
                        style: AppText.fraunces(fontSize: 24, color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  Text(line.speaker.name, style: AppText.fraunces(fontSize: 18)),
                  Text("dialecte ${line.speaker.dialect.label}",
                      style: AppText.inter(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.55))),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(line.nko, textDirection: TextDirection.rtl, style: AppText.nko(fontSize: 26)),
                if (_bilingual) ...[
                  const SizedBox(height: 8),
                  Text(line.french, style: AppText.inter(fontSize: 14, color: AppColors.ink.withValues(alpha: 0.75))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (line.choices != null)
            Column(
              children: [
                for (var i = 0; i < line.choices!.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  SecondaryButton(
                    label: line.choices![i].label,
                    icon: Icons.forum,
                    onPressed: () => _advance(line.choices![i].nextId),
                  ),
                ],
              ],
            )
          else if (line.nextId != null)
            PrimaryButton(label: "Continuer", onPressed: () => _advance(line.nextId!))
          else
            PrimaryButton(label: "Vérifier ta compréhension", onPressed: _startQuiz),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final q = _quiz[_quizIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Question ${_quizIndex + 1} / ${_quiz.length}",
              style: AppText.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.clay)),
          const SizedBox(height: 10),
          Text(q.question, style: AppText.inter(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          for (final opt in q.options) ...[
            _QuizOption(
              label: opt,
              selected: _quizSelected == opt,
              checked: _quizChecked,
              correct: opt == q.correctLabel,
              onTap: () => _selectQuizOption(opt),
            ),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          PrimaryButton(
            label: _quizChecked ? "Continuer" : "Vérifier",
            background: _quizChecked
                ? (_quizSelected == q.correctLabel ? AppColors.green : AppColors.red)
                : AppColors.indigo,
            onPressed: _quizChecked
                ? _nextQuizQuestion
                : (_quizSelected == null ? null : _checkQuiz),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final bool bilingual;
  final VoidCallback onToggleBilingual;
  final VoidCallback onQuit;

  const _Header({required this.title, required this.bilingual, required this.onToggleBilingual, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Row(
        children: [
          GestureDetector(onTap: onQuit, child: const Icon(Icons.close, size: 22, color: AppColors.ink)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                overflow: TextOverflow.ellipsis, style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          TextButton.icon(
            onPressed: onToggleBilingual,
            icon: Icon(bilingual ? Icons.subtitles : Icons.subtitles_off, size: 18, color: AppColors.indigo),
            label: Text(bilingual ? "FR + N'Ko" : "N'Ko seul",
                style: AppText.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.indigo)),
          ),
        ],
      ),
    );
  }
}

class _QuizOption extends StatelessWidget {
  final String label;
  final bool selected;
  final bool checked;
  final bool correct;
  final VoidCallback onTap;

  const _QuizOption({
    required this.label,
    required this.selected,
    required this.checked,
    required this.correct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.card;
    Color border = AppColors.line;
    if (checked && correct) {
      bg = AppColors.correctBg;
      border = AppColors.green;
    } else if (checked && selected && !correct) {
      bg = AppColors.wrongBg;
      border = AppColors.red;
    } else if (!checked && selected) {
      bg = AppColors.selectedBg;
      border = AppColors.gold;
    }
    return GestureDetector(
      onTap: checked ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 2), borderRadius: BorderRadius.circular(14)),
        child: Text(label, style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
