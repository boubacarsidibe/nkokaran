import 'package:flutter/material.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';

class FailedScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final int gems;
  final VoidCallback onRefillWithGems;

  const FailedScreen({
    super.key,
    required this.onRetry,
    required this.onHome,
    required this.gems,
    required this.onRefillWithGems,
  });

  @override
  Widget build(BuildContext context) {
    final canRefill = gems >= heartRefillCost;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 48, color: AppColors.red),
                const SizedBox(height: 8),
                Text("Plus de cœurs !", style: AppText.fraunces(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  "Recharge tes cœurs avec des gemmes, ou attends qu'ils se régénèrent.",
                  textAlign: TextAlign.center,
                  style: AppText.inter(fontSize: 14, color: AppColors.ink.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: canRefill ? onRefillWithGems : null,
                  icon: const Icon(Icons.diamond, size: 16, color: AppColors.indigo),
                  label: Text("Recharger tous les cœurs — $heartRefillCost gemmes",
                      style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.card,
                    side: const BorderSide(color: AppColors.line),
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SecondaryButton(label: "Accueil", icon: Icons.home, onPressed: onHome),
                    const SizedBox(width: 12),
                    PrimaryButtonWide(label: "Réessayer", icon: Icons.replay, onPressed: onRetry),
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
