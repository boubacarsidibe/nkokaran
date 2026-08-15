import 'package:flutter/material.dart';
import '../models/story_data.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';

/// The narrative "Saison" track — a list of episodes running in parallel to
/// the letters/units path, unlocked in order but not gated by unit progress.
class StoryListScreen extends StatelessWidget {
  final Progress progress;
  final void Function(StoryEpisode episode) onPlay;

  const StoryListScreen({super.key, required this.progress, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Saison 1", style: AppText.fraunces(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text("Suis Sekou et Aïcha à travers le pays manding.",
                        style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                  itemCount: storyEpisodes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final ep = storyEpisodes[i];
                    final unlocked = i == 0 || progress.completedEpisodes.contains(storyEpisodes[i - 1].id);
                    final done = progress.completedEpisodes.contains(ep.id);
                    final matchesDialect =
                        ep.characters.any((c) => c.dialect.label == progress.preferredDialect);
                    return _EpisodeRow(
                      index: i,
                      episode: ep,
                      unlocked: unlocked,
                      done: done,
                      matchesDialect: matchesDialect,
                      onTap: unlocked ? () => onPlay(ep) : null,
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

class _EpisodeRow extends StatelessWidget {
  final int index;
  final StoryEpisode episode;
  final bool unlocked;
  final bool done;
  final bool matchesDialect;
  final VoidCallback? onTap;

  const _EpisodeRow({
    required this.index,
    required this.episode,
    required this.unlocked,
    required this.done,
    required this.matchesDialect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: done ? AppColors.green : AppColors.indigo,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      done ? Icons.check : (unlocked ? Icons.play_arrow : Icons.lock),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text("Épisode ${index + 1} — ${episode.title}",
                                  style: AppText.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                            ),
                            if (matchesDialect) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text("ton dialecte",
                                    style: AppText.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ],
                          ],
                        ),
                        Text(episode.subtitle, style: AppText.inter(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  if (unlocked) const Icon(Icons.chevron_right, color: AppColors.ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
