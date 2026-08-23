import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/social_service.dart';
import '../theme/app_theme.dart';

/// Feature 26 — a discussion thread per lesson, so learners can ask
/// questions about that unit. Requires a configured Firebase backend.
class LessonThreadScreen extends StatefulWidget {
  final String unitId;
  final String unitTitle;
  const LessonThreadScreen({super.key, required this.unitId, required this.unitTitle});

  @override
  State<LessonThreadScreen> createState() => _LessonThreadScreenState();
}

class _LessonThreadScreenState extends State<LessonThreadScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text("Discussion — ${widget.unitTitle}", style: AppText.fraunces(fontSize: 17)),
      ),
      body: SafeArea(
        child: _checking
            ? const Center(child: CircularProgressIndicator(color: AppColors.indigo))
            : !_available
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "La discussion nécessite une connexion au serveur — indisponible pour l'instant.",
                        textAlign: TextAlign.center,
                        style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65)),
                      ),
                    ),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        children: [
                          Expanded(
                            child: StreamBuilder<List<ThreadPost>>(
                              stream: SocialService.instance.lessonThreadStream(widget.unitId),
                              builder: (context, snap) {
                                final posts = snap.data ?? [];
                                if (posts.isEmpty) {
                                  return Center(
                                    child: Text("Sois le premier à poser une question sur cette leçon !",
                                        style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6))),
                                  );
                                }
                                return ListView.separated(
                                  padding: const EdgeInsets.all(18),
                                  itemCount: posts.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, i) {
                                    final p = posts[i];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        border: Border.all(color: AppColors.line),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.author, style: AppText.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.clay)),
                                          const SizedBox(height: 4),
                                          Text(p.text, style: AppText.inter(fontSize: 14)),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    decoration: InputDecoration(
                                      hintText: "Poser une question…",
                                      filled: true,
                                      fillColor: AppColors.card,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: AppColors.line),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  style: IconButton.styleFrom(backgroundColor: AppColors.indigo),
                                  icon: const Icon(Icons.send, color: Colors.white),
                                  onPressed: () async {
                                    final name = FirebaseAuth.instance.currentUser?.displayName;
                                    await SocialService.instance.postToThread(
                                      widget.unitId,
                                      (name == null || name.isEmpty) ? "Kalanden" : name,
                                      _controller.text,
                                    );
                                    _controller.clear();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
