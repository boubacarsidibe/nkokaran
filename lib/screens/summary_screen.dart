import 'package:flutter/material.dart';
import '../models/nko_data.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';

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
                const SizedBox(height: 28),
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
