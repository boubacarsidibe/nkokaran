import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/social_service.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';

/// Feature 27 — a single shared, join-by-code club with a collective weekly
/// XP goal. Requires a configured Firebase backend.
class ClubScreen extends StatefulWidget {
  const ClubScreen({super.key});

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  static const _defaultClubId = "kalanden-manding";
  bool _checking = true;
  bool _available = false;

  @override
  void initState() {
    super.initState();
    SocialService.instance.ensureReady().then((ok) {
      if (mounted) {
        setState(() {
          _available = ok;
          _checking = false;
        });
      }
    });
  }

  Future<void> _join() {
    final name = FirebaseAuth.instance.currentUser?.displayName;
    return SocialService.instance.joinClub(_defaultClubId, (name == null || name.isEmpty) ? "Kalanden" : name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text("Club d'apprentissage", style: AppText.fraunces(fontSize: 18)),
      ),
      body: SafeArea(
        child: _checking
            ? const Center(child: CircularProgressIndicator(color: AppColors.indigo))
            : !_available
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text("Le club nécessite une connexion au serveur — indisponible pour l'instant.",
                          textAlign: TextAlign.center,
                          style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65))),
                    ),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: StreamBuilder<ClubData?>(
                        stream: SocialService.instance.clubStream(_defaultClubId),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text("Club indisponible pour l'instant — vérifie ta connexion.",
                                    textAlign: TextAlign.center,
                                    style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65))),
                              ),
                            );
                          }
                          final club = snap.data;
                          if (club == null) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Rejoins le club « Kalanden Manding » et atteins un objectif collectif d'XP chaque semaine.",
                                        textAlign: TextAlign.center, style: AppText.inter(fontSize: 14)),
                                    const SizedBox(height: 16),
                                    PrimaryButton(label: "Rejoindre le club", onPressed: _join),
                                  ],
                                ),
                              ),
                            );
                          }
                          final progress = (club.totalXp / club.weeklyGoalXp).clamp(0, 1);
                          return Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(club.name, style: AppText.fraunces(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text("${club.members.length} membres", style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6))),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress.toDouble(),
                                    minHeight: 14,
                                    backgroundColor: AppColors.lockedNode,
                                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text("${club.totalXp} / ${club.weeklyGoalXp} XP cette semaine",
                                    style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 20),
                                PrimaryButton(
                                  label: "Contribuer 10 XP",
                                  onPressed: () => SocialService.instance.contributeToClub(_defaultClubId, 10),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
      ),
    );
  }
}
