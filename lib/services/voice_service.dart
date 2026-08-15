import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Thin, lazily-initialized wrapper around `flutter_tts` — used to "speak"
/// listening/dictation prompts since we don't ship real N'Ko audio files yet.
/// The system TTS voice won't pronounce N'Ko script correctly (no engine
/// supports it), so callers pass a plain Latin-alphabet approximation.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _tts.setLanguage("fr-FR");
    await _tts.setSpeechRate(0.4);
    _configured = true;
  }

  Future<void> speak(String text) async {
    await _ensureConfigured();
    await _tts.stop();
    await _tts.speak(text);
  }
}

enum SttAvailability { unknown, available, unavailable }

/// Thin wrapper around `speech_to_text`. Recognition quality for N'Ko is
/// inherently poor — no STT engine has a N'Ko model — so this is used only
/// for a loose, best-effort match against a Latin-alphabet phonetic
/// reference, with the UI always framing results as formative feedback.
class SttService {
  SttService._();
  static final SttService instance = SttService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  SttAvailability _availability = SttAvailability.unknown;

  Future<bool> initialize() async {
    if (_availability == SttAvailability.available) return true;
    try {
      final ok = await _speech.initialize();
      _availability = ok ? SttAvailability.available : SttAvailability.unavailable;
      return ok;
    } catch (_) {
      _availability = SttAvailability.unavailable;
      return false;
    }
  }

  bool get isListening => _speech.isListening;

  Future<void> listen({required void Function(String text, bool isFinal) onResult}) async {
    await _speech.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
      ),
    );
  }

  Future<void> stop() => _speech.stop();
}

/// Very loose similarity: lowercase, strip non-letters, then compare by
/// shared-prefix + substring containment. Good enough to distinguish "way
/// off" from "roughly right" without pretending to be a real phonetic
/// matcher — there isn't one for N'Ko.
bool roughlyMatches(String heard, String target) {
  String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  final h = norm(heard);
  final t = norm(target);
  if (h.isEmpty || t.isEmpty) return false;
  return h.contains(t) || t.contains(h) || h.startsWith(t.substring(0, (t.length / 2).ceil()));
}
