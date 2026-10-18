import 'package:flutter/material.dart';
import '../models/nko_data.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';

/// Pronunciation exercise: listen to the word (Djelia, Bambara voice) and
/// repeat it aloud. There's no speech recognizer for N'Ko or Bambara — the
/// device recognizers are tied to French/English locales — so the learner
/// self-assesses instead of being graded by a French-biased matcher.
class PronunciationCard extends StatefulWidget {
  final Exercise exercise;
  const PronunciationCard({super.key, required this.exercise});

  @override
  State<PronunciationCard> createState() => _PronunciationCardState();
}

class _PronunciationCardState extends State<PronunciationCard> {
  int _listens = 0;

  Future<void> _listen() async {
    setState(() => _listens += 1);
    await speakOrNotify(context, widget.exercise.spokenText ?? widget.exercise.targetPhonetic!);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Écoute le mot, puis répète-le à voix haute",
              textAlign: TextAlign.center, style: AppText.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 22),
          Text(widget.exercise.targetWord!, style: AppText.nko(fontSize: 64), textDirection: TextDirection.rtl),
          const SizedBox(height: 26),
          GestureDetector(
            onTap: _listen,
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(_listens > 0 ? Icons.volume_up : Icons.volume_up_outlined, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _listens == 0
                ? "Touche pour écouter."
                : "Répète autant de fois que tu veux, puis continue.",
            textAlign: TextAlign.center,
            style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
