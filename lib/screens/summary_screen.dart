import 'package:flutter/material.dart';
import '../models/culture_data.dart';
import '../models/nko_data.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import 'lesson_thread_screen.dart';

class SummaryScreen extends StatelessWidget {
  final int sessionXp;
  final int sessionGems;
  final NkoUnit? unit;
  final bool perfect;
  final VoidCallback onHome;
  final VoidCallback onReplay;

  const SummaryScreen({
    super.key,
    required this.sessionXp,
    required this.sessionGems,
    required this.unit,
    required this.perfect,
    required this.onHome,
    required this.onReplay,
  });

  void _openThread(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LessonThreadScreen(unitId: unit!.id, unitTitle: unit!.title),
    ));
  }

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
                Text("ߛߊ߬ߥߊ߬ߣߊ߫", style: AppText.nko(fontSize: 56), textDirection: TextDirection.rtl),
                const SizedBox(height: 8),
                Text("Leçon terminée !", style: AppText.fraunces(fontSize: 28)),
                const SizedBox(height: 6),
                Text(unit?.title ?? "",
                    style: AppText.inter(fontSize: 14, color: AppColors.ink.withValues(alpha: 0.65))),
                if (perfect) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(14)),
                    child: Text("PARFAIT — sans faute !",
                        style: AppText.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Pill(icon: Icons.auto_awesome, color: AppColors.gold, label: "+$sessionXp XP"),
                    const SizedBox(width: 10),
                    _Pill(icon: Icons.diamond, color: AppColors.indigo, label: "+$sessionGems"),
                  ],
                ),
                if (unit != null && proverbForUnit(unit!.id) != null) ...[
                  const SizedBox(height: 22),
                  _ProverbCard(proverb: proverbForUnit(unit!.id)!),
                ],
                if (unit != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _openThread(context),
                    icon: const Icon(Icons.forum, size: 16, color: AppColors.indigo),
                    label: Text("Discuter de cette leçon",
                        style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.indigo)),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SecondaryButton(label: "Refaire", icon: Icons.replay, onPressed: onReplay),
                    const SizedBox(width: 12),
                    PrimaryButtonWide(label: "Continuer", icon: Icons.home, onPressed: onHome),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One proverb per unit (feature 23), shown when the summary screen closes
/// out a unit lesson.
class _ProverbCard extends StatelessWidget {
  final Proverb proverb;
  const _ProverbCard({required this.proverb});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("PROVERBE MANDING",
              style: AppText.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.clay, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(proverb.nko, textDirection: TextDirection.rtl, style: AppText.nko(fontSize: 20)),
          const SizedBox(height: 4),
          Text(proverb.transliteration,
              style: AppText.inter(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))
                  .copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 6),
          Text('« ${proverb.translation} »', style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(proverb.explanation, style: AppText.inter(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _Pill({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
