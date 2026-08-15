import 'package:flutter/material.dart';
import '../models/nko_data.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';

/// Duolingo's "Practice hub" — drill any unit you've already unlocked,
/// outside the main path, without it affecting unit-completion state.
class PracticeScreen extends StatelessWidget {
  final Progress progress;
  final void Function(NkoUnit unit) onPractice;
  final VoidCallback onPracticeMistakes;
  final VoidCallback onPracticeReview;
  final int dueReviewCount;

  const PracticeScreen({
    super.key,
    required this.progress,
    required this.onPractice,
    required this.onPracticeMistakes,
    required this.onPracticeReview,
    required this.dueReviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final completed = progress.completedUnits;
    final practicable = units.where((u) => u.letters != null).toList();
    final mistakeCount = progress.weakLetters.length;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Entraînement", style: AppText.fraunces(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text("Révise librement, sans perdre ta progression sur le parcours.",
                        style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65))),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                  children: [
                    if (mistakeCount > 0) ...[
                      _MistakesRow(count: mistakeCount, onTap: onPracticeMistakes),
                      const SizedBox(height: 14),
                    ],
                    if (dueReviewCount > 0) ...[
                      _ReviewRow(count: dueReviewCount, onTap: onPracticeReview),
                      const SizedBox(height: 14),
                    ],
                    for (var i = 0; i < practicable.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      Builder(builder: (context) {
                        final unit = practicable[i];
                        final unlocked = completed.contains(unit.id) ||
                            (i == 0) ||
                            completed.contains(practicable[i - 1].id);
                        return _PracticeRow(
                          unit: unit,
                          unlocked: unlocked,
                          mastered: completed.contains(unit.id),
                          onTap: unlocked ? () => onPractice(unit) : null,
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MistakesRow extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _MistakesRow({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.wrongBg,
        border: Border.all(color: AppColors.red),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.replay_circle_filled, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Réviser tes erreurs", style: AppText.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text("$count lettre${count > 1 ? 's' : ''} à retravailler",
                          style: AppText.inter(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _ReviewRow({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.indigo.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.indigo),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.schedule, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Révision espacée", style: AppText.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text("$count lettre${count > 1 ? 's' : ''} à réviser aujourd'hui",
                          style: AppText.inter(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PracticeRow extends StatelessWidget {
  final NkoUnit unit;
  final bool unlocked;
  final bool mastered;
  final VoidCallback? onTap;

  const _PracticeRow({required this.unit, required this.unlocked, required this.mastered, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: mastered ? AppColors.green : AppColors.indigo,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      mastered ? Icons.bolt : (unlocked ? Icons.fitness_center : Icons.lock),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(unit.title, style: AppText.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(unit.subtitle,
                            style: AppText.inter(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  if (unlocked) const Icon(Icons.chevron_right, color: AppColors.ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
