import 'package:flutter/material.dart';
import '../models/nko_data.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';

/// Feature 30 — reads the accuracy/time tracking recorded by
/// [Progress.recordAnswer] and shows a global summary plus a per-unit
/// accuracy breakdown.
class StatsScreen extends StatelessWidget {
  final Progress progress;
  final void Function(NkoUnit unit) onPracticeUnit;
  const StatsScreen({super.key, required this.progress, required this.onPracticeUnit});

  @override
  Widget build(BuildContext context) {
    final totalMinutes = (progress.totalTimeMs / 60000).round();
    final unitStats = units.where((u) => (progress.unitAttempts[u.id] ?? 0) > 0).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text("Statistiques", style: AppText.fraunces(fontSize: 20)),
        foregroundColor: AppColors.ink,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.track_changes,
                        color: AppColors.green,
                        value: "${(progress.accuracy * 100).round()}%",
                        label: "Précision globale",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.timer,
                        color: AppColors.indigo,
                        value: "$totalMinutes min",
                        label: "Temps total",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle,
                        color: AppColors.gold,
                        value: "${progress.totalCorrect}",
                        label: "Réponses correctes",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.quiz,
                        color: AppColors.clay,
                        value: "${progress.totalAnswered}",
                        label: "Réponses données",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text("Précision par leçon", style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.clay)),
                const SizedBox(height: 12),
                if (unitStats.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Termine quelques exercices pour voir ta précision par leçon.",
                      style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65)),
                    ),
                  )
                else
                  for (var i = 0; i < unitStats.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _UnitAccuracyRow(
                      title: unitStats[i].title,
                      accuracy: progress.accuracyForUnit(unitStats[i].id),
                      attempts: progress.unitAttempts[unitStats[i].id] ?? 0,
                      onTap: unitStats[i].letters == null
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              onPracticeUnit(unitStats[i]);
                            },
                    ),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: AppText.fraunces(fontSize: 17)),
          Text(label, style: AppText.inter(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _UnitAccuracyRow extends StatelessWidget {
  final String title;
  final double accuracy;
  final int attempts;
  final VoidCallback? onTap;
  const _UnitAccuracyRow({required this.title, required this.accuracy, required this.attempts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w700))),
                  Text("${(accuracy * 100).round()}%",
                      style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.indigo)),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: AppColors.ink, size: 18),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: accuracy.clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: AppColors.lockedNode,
                  valueColor: AlwaysStoppedAnimation(accuracy >= 0.8 ? AppColors.green : AppColors.gold),
                ),
              ),
              const SizedBox(height: 6),
              Text("$attempts réponse${attempts > 1 ? 's' : ''}",
                  style: AppText.inter(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }
}
