import 'package:flutter/material.dart';
import '../models/culture_data.dart';
import '../theme/app_theme.dart';

/// The story of the N'Ko script and its inventor, Solomana Kanté —
/// linked from the profile screen alongside the audio glossary.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text("Histoire du N'Ko", style: AppText.fraunces(fontSize: 20)),
        foregroundColor: AppColors.ink,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              itemCount: historyChapters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ChapterCard(chapter: historyChapters[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final HistoryChapter chapter;
  const _ChapterCard({required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chapter.title, style: AppText.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            chapter.body,
            style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.8)).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
