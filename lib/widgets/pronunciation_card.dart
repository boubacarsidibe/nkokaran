import 'package:flutter/material.dart';
import '../models/nko_data.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';

/// Pronunciation exercise (feature 17): show the target word, record the
/// learner reading it aloud, and give best-effort feedback. Speech
/// recognition has no N'Ko model, so this fuzzy-matches the recognized
/// Latin-alphabet transcript against [Exercise.targetPhonetic] — framed as
/// formative feedback, never a hard pass/fail gate.
class PronunciationCard extends StatefulWidget {
  final Exercise exercise;
  const PronunciationCard({super.key, required this.exercise});

  @override
  State<PronunciationCard> createState() => _PronunciationCardState();
}

class _PronunciationCardState extends State<PronunciationCard> {
  bool _checking = false;
  bool _unavailable = false;
  String _heard = "";
  bool? _matched;

  Future<void> _record() async {
    final available = await SttService.instance.initialize();
    if (!available) {
      setState(() => _unavailable = true);
      return;
    }
    setState(() {
      _checking = true;
      _heard = "";
      _matched = null;
    });
    try {
      await SttService.instance.listen(
        onResult: (text, isFinal) {
          if (!mounted) return;
          setState(() => _heard = text);
          if (isFinal) {
            setState(() {
              _checking = false;
              _matched = roughlyMatches(text, widget.exercise.targetPhonetic!);
            });
          }
        },
      );
    } catch (_) {
      // Mic permission denied mid-session, engine error, etc. — don't leave
      // the button stuck in a permanently "listening" state.
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Prononce ce mot à voix haute",
              textAlign: TextAlign.center, style: AppText.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 22),
          Text(widget.exercise.targetWord!, style: AppText.nko(fontSize: 64), textDirection: TextDirection.rtl),
          const SizedBox(height: 26),
          if (_unavailable)
            Text(
              "Reconnaissance vocale indisponible sur cet appareil — réessaie depuis un téléphone ou une tablette.",
              textAlign: TextAlign.center,
              style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65)),
            )
          else ...[
            GestureDetector(
              onTap: _checking ? null : _record,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: _checking ? AppColors.red : AppColors.indigo,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(_checking ? Icons.mic : Icons.mic_none, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 14),
            if (_checking) Text("Je t'écoute…", style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6))),
            if (!_checking && _matched != null) ...[
              Text('Entendu : "$_heard"', style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6))),
              const SizedBox(height: 6),
              Text(
                _matched! ? "Bonne prononciation !" : "Pas tout à fait — réessaie en articulant chaque syllabe.",
                style: AppText.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _matched! ? AppColors.green : AppColors.clay),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
