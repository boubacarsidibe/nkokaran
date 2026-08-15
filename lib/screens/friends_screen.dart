import 'package:flutter/material.dart';
import '../services/social_service.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';

/// Friends list — mirrors Duolingo's "add a friend, see them in your feed"
/// loop. Since there's no username directory here, friends are added by
/// pasting the other player's id (shown on their own screen to share).
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _controller = TextEditingController();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addFriend() async {
    final id = _controller.text.trim();
    if (id.isEmpty) return;
    await SocialService.instance.addFriend(id);
    _controller.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ami ajouté (si l'identifiant est valide).")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = SocialService.instance.uid ?? "—";
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text("Amis", style: AppText.fraunces(fontSize: 20)),
      ),
      body: SafeArea(
        child: _checking
            ? const Center(child: CircularProgressIndicator(color: AppColors.indigo))
            : !_available
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text("Les amis nécessitent une connexion au serveur — indisponible pour l'instant.",
                          textAlign: TextAlign.center,
                          style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65))),
                    ),
                  )
                : Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Ton identifiant", style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.clay)),
                      const SizedBox(height: 8),
                      SelectableText(myUid, style: AppText.inter(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text("Partage-le pour que d'autres t'ajoutent.",
                          style: AppText.inter(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Ajouter un ami", style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.clay)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Coller un identifiant",
                          filled: true,
                          fillColor: AppColors.bg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),
                      PrimaryButtonWide(label: "Ajouter", icon: Icons.person_add, onPressed: _addFriend),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text("Tes amis", style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.clay)),
                const SizedBox(height: 10),
                StreamBuilder<List<LeagueMember>>(
                  stream: SocialService.instance.friendsStream(),
                  builder: (context, snap) {
                    final friends = snap.data ?? [];
                    if (friends.isEmpty) {
                      return Text("Pas encore d'amis ajoutés.",
                          style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6)));
                    }
                    return Column(
                      children: [
                        for (final f in friends)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              border: Border.all(color: AppColors.line),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person, size: 18, color: AppColors.indigo),
                                const SizedBox(width: 10),
                                Expanded(child: Text(f.name, style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w600))),
                                Text("${f.weeklyXp} XP", style: AppText.inter(fontSize: 13, color: AppColors.clay, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
