import 'package:flutter/material.dart';
import '../models/nko_data.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';
import 'lesson_cards.dart';

/// Dictation exercise (feature 20): play the word via TTS, reconstruct it
/// from letter tiles — same tile-tap interaction as [WordBankCard], with a
/// replay button up top instead of the N'Ko text being shown outright.
class DictationCard extends StatefulWidget {
  final Exercise exercise;
  final void Function(List<String>? assembled) onChanged;

  const DictationCard({super.key, required this.exercise, required this.onChanged});

  @override
  State<DictationCard> createState() => _DictationCardState();
}

class _DictationCardState extends State<DictationCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => TtsService.instance.speak(widget.exercise.spokenText!));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => TtsService.instance.speak(widget.exercise.spokenText!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.selectedBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_up, size: 18, color: AppColors.indigo),
                const SizedBox(width: 8),
                Text("Réécouter", style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        WordBankCard(
          question: widget.exercise.question!,
          tiles: widget.exercise.wordTiles!,
          answer: widget.exercise.wordAnswer!,
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
