import 'dart:math';
import 'package:flutter/material.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';

const _botNames = [
  "Mariam", "Sekou", "Aïcha", "Lamine", "Fatou",
  "Boubacar", "Kadiatou", "Ismaël", "Djénéba", "Moussa",
  "Nabintou", "Yaya",
];

/// A local, offline stand-in for Duolingo's weekly leagues: there's no
/// backend here, so ranking is simulated against seeded bot scores rather
/// than real players — but the loop (weekly XP → rank → promotion zone)
/// is the same one Duolingo's league tab teaches.
class LeagueScreen extends StatelessWidget {
  final Progress progress;
  const LeagueScreen({super.key, required this.progress});

  int get _weeklyXp {
    final now = DateTime.now();
    var total = 0;
    for (var i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      total += progress.xpHistory["${d.year}-${d.month}-${d.day}"] ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final myXp = _weeklyXp;
    // Seeded so the board doesn't reshuffle on every rebuild this session.
    final rng = Random(myXp + progress.streak);
    final rows = <MapEntry<String, int>>[
      for (final name in _botNames) MapEntry(name, 8 + rng.nextInt(85)),
      MapEntry("Toi", myXp),
    ]..sort((a, b) => b.value.compareTo(a.value));

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emoji_events, color: AppColors.clay, size: 22),
                        const SizedBox(width: 8),
                        Text("Ligue Bronze", style: AppText.fraunces(fontSize: 24)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("Classement de la semaine — top 3 promus.",
                        style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final entry = rows[i];
                    final isMe = entry.key == "Toi";
                    final inPromotion = i < 3;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.selectedBg : AppColors.card,
                        border: Border.all(color: isMe ? AppColors.gold : AppColors.line, width: isMe ? 2 : 1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text("${i + 1}",
                                style: AppText.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: inPromotion ? AppColors.green : AppColors.ink.withValues(alpha: 0.6))),
                          ),
                          Expanded(
                            child: Text(entry.key,
                                style: AppText.inter(
                                    fontSize: 14, fontWeight: isMe ? FontWeight.w700 : FontWeight.w500)),
                          ),
                          Text("${entry.value} XP",
                              style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clay)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
