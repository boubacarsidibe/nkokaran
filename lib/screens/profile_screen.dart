import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/badges.dart';
import '../models/nko_data.dart';
import '../services/auth_service.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';
import 'club_screen.dart';
import 'glossary_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Progress progress;
  final VoidCallback onRefillHearts;
  final VoidCallback onBuyStreakFreeze;
  final void Function(String dialect) onDialectChanged;
  final void Function(NkoUnit unit) onPracticeUnit;
  final Future<bool> Function() onManualSync;

  const ProfileScreen({
    super.key,
    required this.progress,
    required this.onRefillHearts,
    required this.onBuyStreakFreeze,
    required this.onDialectChanged,
    required this.onPracticeUnit,
    required this.onManualSync,
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
    final displayName = FirebaseAuth.instance.currentUser?.displayName;
    final name = (displayName == null || displayName.isEmpty) ? "Kalanden" : displayName;

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
                        Text(name, style: AppText.fraunces(fontSize: 22)),
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
                title: "Dialecte préféré",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Utilisé pour mettre en avant le contenu qui correspond à ton dialecte.",
                        style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.7))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final d in const [
                          MapEntry("maninka", "Maninka"),
                          MapEntry("bambara", "Bambara"),
                          MapEntry("dioula", "Dioula"),
                        ])
                          ChoiceChip(
                            label: Text(d.value, style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                            selected: progress.preferredDialect == d.key,
                            onSelected: (_) => onDialectChanged(d.key),
                            selectedColor: AppColors.indigo,
                            labelStyle: AppText.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: progress.preferredDialect == d.key ? Colors.white : AppColors.ink,
                            ),
                            backgroundColor: AppColors.bg,
                            side: BorderSide(color: progress.preferredDialect == d.key ? AppColors.indigo : AppColors.line),
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
              _ProfileNavTile(
                icon: Icons.menu_book,
                label: "Glossaire audio",
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GlossaryScreen())),
              ),
              const SizedBox(height: 10),
              _ProfileNavTile(
                icon: Icons.auto_stories,
                label: "Histoire du N'Ko",
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
              ),
              const SizedBox(height: 10),
              _ProfileNavTile(
                icon: Icons.bar_chart,
                label: "Statistiques",
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => StatsScreen(progress: progress, onPracticeUnit: onPracticeUnit))),
              ),
              const SizedBox(height: 10),
              _ProfileNavTile(
                icon: Icons.groups,
                label: "Club d'apprentissage",
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClubScreen())),
              ),
              const SizedBox(height: 10),
              _SyncRow(progress: progress, onManualSync: onManualSync),
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
              const SizedBox(height: 16),
              _ProfileNavTile(
                icon: Icons.logout,
                iconColor: AppColors.clay,
                label: "Se déconnecter",
                showChevron: false,
                onTap: () => AuthService.instance.signOut(),
              ),
              const SizedBox(height: 10),
              _ProfileNavTile(
                icon: Icons.delete_forever,
                iconColor: AppColors.red,
                labelColor: AppColors.red,
                borderColor: AppColors.red,
                showChevron: false,
                label: "Supprimer mon compte",
                onTap: () => showDialog(context: context, builder: (_) => const _DeleteAccountDialog()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Manual "sync now" action — forces an immediate cloud write via
/// [ProgressStore.save] and reports whether it actually reached Firestore,
/// rather than the silent best-effort save every other mutation triggers.
class _SyncRow extends StatefulWidget {
  final Progress progress;
  final Future<bool> Function() onManualSync;
  const _SyncRow({required this.progress, required this.onManualSync});

  @override
  State<_SyncRow> createState() => _SyncRowState();
}

class _SyncRowState extends State<_SyncRow> {
  bool _syncing = false;
  String? _result;

  String _formatLastSync(int ms) {
    if (ms == 0) return "Jamais synchronisé";
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final time = "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
    return sameDay ? "Dernière sauvegarde aujourd'hui à $time" : "Dernière sauvegarde le ${d.day}/${d.month} à $time";
  }

  Future<void> _sync() async {
    setState(() {
      _syncing = true;
      _result = null;
    });
    final ok = await widget.onManualSync();
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _result = ok ? "Synchronisé ✓" : "Hors ligne — sauvegardé en local seulement";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_sync, color: AppColors.indigo, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Sauvegarde cloud", style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(
                  _result ?? _formatLastSync(widget.progress.updatedAtMs),
                  style: AppText.inter(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          _syncing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.indigo))
              : TextButton(
                  onPressed: _sync,
                  child: Text("Synchroniser", style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.indigo)),
                ),
        ],
      ),
    );
  }
}

/// Tappable card row used throughout the profile for navigation links and
/// account actions — extracted since the same Material/InkWell/Container
/// shape was previously repeated six times with only icon/label/color/tap
/// changing.
class _ProfileNavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? labelColor;
  final Color borderColor;
  final String label;
  final bool showChevron;
  final VoidCallback onTap;

  const _ProfileNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.indigo,
    this.labelColor,
    this.borderColor = AppColors.line,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w700, color: labelColor ?? AppColors.ink)),
              ),
              if (showChevron) const Icon(Icons.chevron_right, color: AppColors.ink),
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

/// Confirms with the account's password (Firebase requires a *recent*
/// sign-in for account deletion) before permanently deleting the Firebase
/// Auth account, its Firestore data, and the on-device progress cache.
/// Success just pops the dialog — [AuthGate] swaps to [AuthScreen]
/// automatically once the auth state changes to signed-out.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_passwordCtrl.text.isEmpty) {
      setState(() => _error = "Saisis ton mot de passe pour confirmer.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final uid = AuthService.instance.currentUser?.uid;
    final error = await AuthService.instance.deleteAccount(password: _passwordCtrl.text);
    if (error == null && uid != null) {
      await ProgressStore.clearLocalFor(uid);
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text("Supprimer ton compte ?", style: AppText.fraunces(fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cette action est définitive : ta progression, tes badges et ton compte seront supprimés. "
            "Confirme avec ton mot de passe.",
            style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            autofocus: true,
            onSubmitted: (_) => _confirm(),
            decoration: InputDecoration(
              hintText: "Mot de passe",
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: AppText.inter(fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text("Annuler", style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ),
        TextButton(
          onPressed: _loading ? null : _confirm,
          child: _loading
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.red))
              : Text("Supprimer", style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.red)),
        ),
      ],
    );
  }
}
