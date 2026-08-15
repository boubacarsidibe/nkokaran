import 'package:flutter/material.dart';
import '../models/badges.dart';
import '../models/nko_data.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';
import 'club_screen.dart';
import 'glossary_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Progress progress;
  final VoidCallback onRefillHearts;
  final VoidCallback onBuyStreakFreeze;

  const ProfileScreen({
    super.key,
    required this.progress,
    required this.onRefillHearts,
    required this.onBuyStreakFreeze,
  });

  @override
  Widget build(BuildContext context) {
    final last7 = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return progress.xpHistory["${d.year}-${d.month}-${d.day}"] ?? 0;
    });
    final maxXp = (last7.fold<int>(0, (a, b) => a > b ? a : b)).clamp(1, 1 << 30);
    final level = levelForXp(progress.xp);
    final nextLevelXp = xpForNextLevel(progress.xp);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text("ߒ", style: AppText.nko(fontSize: 34, color: Colors.white)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.card, width: 2),
                        ),
                        child: Text("Niv. $level",
                            style: AppText.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Kalanden", style: AppText.fraunces(fontSize: 22)),
                        Text("${progress.completedUnits.length} / ${units.length} leçons terminées",
                            style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _StatTile(icon: Icons.local_fire_department, color: AppColors.clay, value: "${progress.streak}", label: "Série")),
                  const SizedBox(width: 10),
                  Expanded(child: _StatTile(icon: Icons.auto_awesome, color: AppColors.gold, value: "${progress.xp}", label: "XP total")),
                  const SizedBox(width: 10),
                  Expanded(child: _StatTile(icon: Icons.diamond, color: AppColors.indigo, value: "${progress.gems}", label: "Gemmes")),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: nextLevelXp == null ? "Niveau $level — maximum atteint" : "Niveau $level",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: nextLevelXp == null ? 1 : (progress.xp / nextLevelXp).clamp(0, 1),
                        minHeight: 10,
                        backgroundColor: AppColors.lockedNode,
                        valueColor: const AlwaysStoppedAnimation(AppColors.indigo),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nextLevelXp == null
                          ? "Tu as atteint le sommet de la courbe de niveaux."
                          : "${progress.xp} / $nextLevelXp XP pour le niveau ${level + 1}",
                      style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionCard(
                title: "Objectif du jour",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (progress.xpToday / dailyGoalXp).clamp(0, 1),
                        minHeight: 12,
                        backgroundColor: AppColors.lockedNode,
                        valueColor: AlwaysStoppedAnimation(
                            progress.dailyGoalReached ? AppColors.green : AppColors.gold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progress.dailyGoalReached
                          ? "Objectif atteint aujourd'hui ! (${progress.xpToday} XP)"
                          : "${progress.xpToday} / $dailyGoalXp XP aujourd'hui",
                      style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: "Cœurs",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        maxHearts,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            i < progress.hearts ? Icons.favorite : Icons.favorite_border,
                            color: i < progress.hearts ? AppColors.clay : AppColors.lockedNode,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      progress.hearts >= maxHearts
                          ? "Cœurs au maximum."
                          : "Régénération automatique avec le temps.",
                      style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.7)),
                    ),
                    if (progress.hearts < maxHearts) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: progress.gems >= heartRefillCost ? onRefillHearts : null,
                        icon: const Icon(Icons.diamond, size: 16, color: AppColors.indigo),
                        label: Text("Recharger — $heartRefillCost gemmes",
                            style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.line),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: "Série de jours",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Geler ta série protège un jour manqué.",
                        style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.7))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text("Gels disponibles : ${progress.streakFreezes}",
                            style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: progress.gems >= streakFreezeCost ? onBuyStreakFreeze : null,
                          icon: const Icon(Icons.ac_unit, size: 16, color: AppColors.indigo),
                          label: Text("$streakFreezeCost gemmes",
                              style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.line),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: "Activité (7 derniers jours)",
                child: SizedBox(
                  height: 90,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final v = last7[i];
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: 60 * (v / maxXp),
                                decoration: BoxDecoration(
                                  color: v > 0 ? AppColors.gold : AppColors.lockedNode,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text("$v", style: AppText.inter(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GlossaryScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book, color: AppColors.indigo, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text("Glossaire audio", style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w700))),
                        const Icon(Icons.chevron_right, color: AppColors.ink),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClubScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.groups, color: AppColors.indigo, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text("Club d'apprentissage", style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w700))),
                        const Icon(Icons.chevron_right, color: AppColors.ink),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: "Badges",
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: badgeCatalog.map((b) {
                    final earned = progress.badges.contains(b.id);
                    return Tooltip(
                      message: b.description,
                      child: Opacity(
                        opacity: earned ? 1 : 0.35,
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: earned ? AppColors.gold : AppColors.lockedNode,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(b.icon, color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 70,
                              child: Text(b.label,
                                  textAlign: TextAlign.center,
                                  style: AppText.inter(fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatTile({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.clay)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
