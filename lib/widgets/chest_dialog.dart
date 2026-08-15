import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'buttons.dart';

/// Reward for finishing a unit for the first time — a small randomized
/// gems/XP bonus revealed in a chest dialog, mirroring Duolingo's unit chests.
class ChestReward {
  final int gems;
  final int xp;
  const ChestReward({required this.gems, required this.xp});

  static final _rng = Random();
  factory ChestReward.random() => ChestReward(
        gems: 5 + _rng.nextInt(11), // 5..15
        xp: 5 + _rng.nextInt(6), // 5..10
      );
}

Future<void> showChestDialog(BuildContext context, ChestReward reward) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard, size: 56, color: AppColors.gold),
            const SizedBox(height: 12),
            Text("Unité terminée !", style: AppText.fraunces(fontSize: 22)),
            const SizedBox(height: 4),
            Text("Un coffre s'ouvre pour toi",
                style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65))),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _rewardChip(icon: Icons.diamond, color: AppColors.indigo, label: "+${reward.gems}"),
                const SizedBox(width: 14),
                _rewardChip(icon: Icons.auto_awesome, color: AppColors.gold, label: "+${reward.xp} XP"),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButtonWide(
              label: "Super !",
              icon: Icons.check,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _rewardChip({required IconData icon, required Color color, required String label}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.bg,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(16),
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
