import 'package:flutter/material.dart';
import '../models/nko_data.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';
import 'option_grid.dart';

/// Listening exercise (feature 16): play a sound, pick the letter that
/// matches it. Audio is a system-TTS approximation of the sound, played on
/// tap and replayable — there's no bundled N'Ko audio yet.
class ListeningCard extends StatefulWidget {
  final Exercise exercise;
  final NkoLetter? selected;
  final bool checked;
  final void Function(NkoLetter) onSelect;

  const ListeningCard({super.key, required this.exercise, required this.selected, required this.checked, required this.onSelect});

  @override
  State<ListeningCard> createState() => _ListeningCardState();
}

class _ListeningCardState extends State<ListeningCard> {
  bool _played = false;

  Future<void> _play() async {
    setState(() => _played = true);
    await TtsService.instance.speak(widget.exercise.spokenText!);
  }

  @override
  void initState() {
    super.initState();
    // Auto-play once when the exercise appears, like Duolingo's listening
    // exercises do.
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.exercise.options!.cast<NkoLetter>();
    final correctChar = widget.exercise.letter!.char;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Écoute et choisis la bonne lettre",
              textAlign: TextAlign.center, style: AppText.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: _play,
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(_played ? Icons.volume_up : Icons.volume_up_outlined, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 26),
          OptionGrid<NkoLetter>(
            options: options,
            renderLabel: (o) => o.char,
            nko: true,
            getKey: (o) => o.char,
            selected: widget.selected,
            checked: widget.checked,
            correctKey: correctChar,
            onSelect: widget.onSelect,
          ),
        ],
      ),
    );
  }
}
