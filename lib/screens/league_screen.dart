import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/social_service.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';
import 'friends_screen.dart';

const _botNames = [
  "Mariam", "Sekou", "Aïcha", "Lamine", "Fatou",
  "Boubacar", "Kadiatou", "Ismaël", "Djénéba", "Moussa",
  "Nabintou", "Yaya",
];

/// Visuals for each [leagueTierNames] entry, lowest tier first.
const _tierColors = [AppColors.clay, Color(0xFF8C97A8), AppColors.gold, AppColors.indigo, Color(0xFF6FC3D6)];

int weeklyXpOf(Progress progress) {
  final now = DateTime.now();
  var total = 0;
  for (var i = 0; i < 7; i++) {
    final d = now.subtract(Duration(days: i));
    total += progress.xpHistory["${d.year}-${d.month}-${d.day}"] ?? 0;
  }
  return total;
}

/// Weekly league — real players when a Firebase backend is configured (see
/// [SocialService]), otherwise a local, offline stand-in ranked against
/// seeded bot scores so the loop (weekly XP → rank → promotion zone) is
/// still demonstrable without a backend.
class LeagueScreen extends StatefulWidget {
  final Progress progress;
  const LeagueScreen({super.key, required this.progress});

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  bool _checkingBackend = true;
  bool _backendAvailable = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final available = await SocialService.instance.ensureReady();
    if (available) {
      final name = FirebaseAuth.instance.currentUser?.displayName;
      await SocialService.instance.upsertProfile(
        displayName: (name == null || name.isEmpty) ? "Kalanden" : name,
        xp: widget.progress.xp,
        weeklyXp: weeklyXpOf(widget.progress),
        leagueTier: widget.progress.leagueTier,
      );
    }
    if (mounted) {
      setState(() {
        _backendAvailable = available;
        _checkingBackend = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingBackend) {
      return const Center(child: CircularProgressIndicator(color: AppColors.indigo));
    }
    final tier = widget.progress.leagueTier;
    final tierColor = _tierColors[tier];
    final isTopTier = tier == leagueTierNames.length - 1;
    final promotionProgress = (widget.progress.leagueWeekXp / leaguePromotionXp).clamp(0, 1).toDouble();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.emoji_events, color: tierColor, size: 22),
                              const SizedBox(width: 8),
                              Text("Ligue ${leagueTierNames[tier]}", style: AppText.fraunces(fontSize: 24)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _backendAvailable
                                ? "Classement de la semaine — top 3 promus."
                                : "Classement simulé (hors ligne) — top 3 promus.",
                            style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65)),
                          ),
                          const SizedBox(height: 10),
                          if (isTopTier)
                            Text("Ligue la plus haute — continue pour t'y maintenir !",
                                style: AppText.inter(fontSize: 12, fontWeight: FontWeight.w600, color: tierColor))
                          else ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: promotionProgress,
                                minHeight: 8,
                                backgroundColor: AppColors.lockedNode,
                                valueColor: AlwaysStoppedAnimation(tierColor),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${widget.progress.leagueWeekXp}/$leaguePromotionXp XP pour monter en ${leagueTierNames[tier + 1]}",
                              style: AppText.inter(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.6)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_backendAvailable)
                      IconButton(
                        icon: const Icon(Icons.people, color: AppColors.indigo),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FriendsScreen())),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _backendAvailable
                    ? _RealLeagueList(progress: widget.progress, tier: tier)
                    : _SimulatedLeagueList(progress: widget.progress, tier: tier),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RealLeagueList extends StatelessWidget {
  final Progress progress;
  final int tier;
  const _RealLeagueList({required this.progress, required this.tier});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LeagueMember>>(
      stream: SocialService.instance.weeklyLeagueStream(tier),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text("Classement indisponible pour l'instant — vérifie ta connexion.",
                textAlign: TextAlign.center, style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6))),
          );
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.indigo));
        final rows = snap.data!;
        if (rows.isEmpty) {
          return Center(
            child: Text("Personne d'autre pour l'instant — invite des amis.",
                style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6))),
          );
        }
        return _LeagueRows(
          rows: [for (final r in rows) (label: r.name, xp: r.weeklyXp, uid: r.uid)],
          myUid: SocialService.instance.uid,
        );
      },
    );
  }
}

class _SimulatedLeagueList extends StatelessWidget {
  final Progress progress;
  final int tier;
  const _SimulatedLeagueList({required this.progress, required this.tier});

  @override
  Widget build(BuildContext context) {
    final myXp = weeklyXpOf(progress);
    // Seeded so the board doesn't reshuffle on every rebuild this session.
    final rng = Random(myXp + progress.streak);
    // Higher tiers face stiffer simulated competition, so climbing the
    // ladder actually feels harder — not just a cosmetic label change.
    final tierFloor = tier * 30;
    final rows = <({String label, int xp, String uid})>[
      for (final name in _botNames) (label: name, xp: tierFloor + 8 + rng.nextInt(85), uid: name),
      (label: "Toi", xp: myXp, uid: "Toi"),
    ];
    return _LeagueRows(rows: rows, myUid: "Toi");
  }
}

class _LeagueRows extends StatelessWidget {
  final List<({String label, int xp, String uid})> rows;
  final String? myUid;
  const _LeagueRows({required this.rows, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(rows)..sort((a, b) => b.xp.compareTo(a.xp));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final entry = sorted[i];
        final isMe = entry.uid == myUid;
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
                child: Text(entry.label, style: AppText.inter(fontSize: 14, fontWeight: isMe ? FontWeight.w700 : FontWeight.w500)),
              ),
              Text("${entry.xp} XP", style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clay)),
            ],
          ),
        );
      },
    );
  }
}
