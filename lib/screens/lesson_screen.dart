import 'package:flutter/material.dart';
import '../models/nko_data.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/dictation_card.dart';
import '../widgets/handwriting_canvas.dart';
import '../widgets/lesson_cards.dart';
import '../widgets/listening_card.dart';
import '../widgets/pronunciation_card.dart';

class LessonScreen extends StatelessWidget {
  final NkoUnit unit;
  final List<Exercise> exercises;
  final int exIndex;
  final int hearts;
  final int sessionXp;
  final dynamic selected;
  final bool checked;
  final bool isCorrect;
  final void Function(dynamic) onSelect;
  final VoidCallback onCheck;
  final VoidCallback onNext;
  final VoidCallback onQuit;
  final VoidCallback onMatchSolved;

  const LessonScreen({
    super.key,
    required this.unit,
    required this.exercises,
    required this.exIndex,
    required this.hearts,
    required this.sessionXp,
    required this.selected,
    required this.checked,
    required this.isCorrect,
    required this.onSelect,
    required this.onCheck,
    required this.onNext,
    required this.onQuit,
    required this.onMatchSolved,
  });

  @override
  Widget build(BuildContext context) {
    final cur = exercises[exIndex];
    final progressPct = exIndex / exercises.length;
    // intro/wordIntro: a plain "Continuer". quiz/wordBank: a manual
    // "Vérifier" step gated on a selection. match: auto-checks itself and
    // only unlocks "Continuer" once every pair is solved.
    final needsManualCheck = cur.type == ExerciseType.quiz ||
        cur.type == ExerciseType.wordBank ||
        cur.type == ExerciseType.listening ||
        cur.type == ExerciseType.dictation;
    final canContinue = !needsManualCheck && cur.type != ExerciseType.match;
    final canCheck = needsManualCheck && !checked;
    final buttonEnabled = canContinue || checked || (canCheck && selected != null);

    final footerBg = checked
        ? (isCorrect ? AppColors.correctBg : AppColors.wrongBg)
        : Colors.transparent;
    final buttonBg = checked ? (isCorrect ? AppColors.green : AppColors.red) : AppColors.indigo;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onQuit,
                        child: const Icon(Icons.close, size: 22, color: AppColors.ink),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressPct.clamp(0, 1),
                            minHeight: 10,
                            backgroundColor: AppColors.lockedNode,
                            valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Row(
                        children: List.generate(5, (i) {
                          final filled = i < hearts;
                          return Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Icon(
                              filled ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: filled ? AppColors.clay : AppColors.lockedNode,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
                    child: Center(
                      child: SingleChildScrollView(
                        child: _buildBody(cur),
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  color: footerBg,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (checked)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCorrect ? "Excellent !" : "Pas tout à fait — regarde bien la prochaine fois.",
                                style: AppText.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isCorrect ? AppColors.green : AppColors.red,
                                ),
                              ),
                              if (!isCorrect && cur.explanation != null) ...[
                                const SizedBox(height: 4),
                                Text(cur.explanation!,
                                    style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.75))),
                              ],
                            ],
                          ),
                        ),
                      PrimaryButton(
                        label: cur.type == ExerciseType.match
                            ? "Continuer"
                            : (canContinue || checked ? "Continuer" : "Vérifier"),
                        background: buttonBg,
                        onPressed: buttonEnabled ? (canCheck ? onCheck : onNext) : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Exercise cur) {
    switch (cur.type) {
      case ExerciseType.intro:
        return IntroCard(letter: cur.letter!);
      case ExerciseType.wordIntro:
        return const WordIntroCard();
      case ExerciseType.quiz:
        return QuizCard(exercise: cur, selected: selected, checked: checked, onSelect: onSelect);
      case ExerciseType.match:
        return MatchCard(letters: cur.matchLetters!, onSolved: onMatchSolved);
      case ExerciseType.wordBank:
        return WordBankCard(
          question: cur.question!,
          tiles: cur.wordTiles!,
          answer: cur.wordAnswer!,
          onChanged: (assembled) => onSelect(assembled),
        );
      case ExerciseType.listening:
        return ListeningCard(
          exercise: cur,
          selected: selected as NkoLetter?,
          checked: checked,
          onSelect: onSelect,
        );
      case ExerciseType.dictation:
        return DictationCard(exercise: cur, onChanged: (assembled) => onSelect(assembled));
      case ExerciseType.pronunciation:
        return PronunciationCard(exercise: cur);
      case ExerciseType.handwriting:
        return HandwritingCanvas(letter: cur.letter!);
    }
  }
}
