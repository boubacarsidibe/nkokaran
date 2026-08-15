import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Thin, lazily-initialized wrapper around `flutter_tts` — used to "speak"
/// listening/dictation prompts since we don't ship real N'Ko audio files yet.
/// The system TTS voice won't pronounce N'Ko script correctly (no engine
/// supports it), so callers pass a plain Latin-alphabet approximation.
///
/// For users whose [preferredDialect] is "bambara", real Bambara speech is
/// used instead via Djelia (https://djelia.cloud) — the only hosted TTS API
/// we found with actual Bambara support (maninka/dioula have no comparable
/// hosted service; Meta's MMS models cover them but require self-hosting a
/// PyTorch model, so they're out of scope here). Requires a free-tier API
/// key supplied at build/run time via `--dart-define=DJELIA_API_KEY=...`;
/// without one (or on any request failure), this falls back to the same
/// French-voice approximation used for all dialects.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  static const _djeliaApiKey = String.fromEnvironment('DJELIA_API_KEY');
  static const _djeliaTtsUrl = 'https://djelia.cloud/api/v2/models/tts';

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  bool _configured = false;
  String _preferredDialect = "maninka";

  void setDialect(String dialect) => _preferredDialect = dialect;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _tts.setLanguage("fr-FR");
    await _tts.setSpeechRate(0.4);
    _configured = true;
  }

  Future<void> speak(String text) async {
    if (_preferredDialect == "bambara" && _djeliaApiKey.isNotEmpty) {
      if (await _speakBambara(text)) return;
    }
    await _ensureConfigured();
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Real Bambara speech via Djelia's TTS API. Returns false (never throws)
  /// on any failure — network error, bad key, rate limit — so [speak] can
  /// fall back to the French-voice approximation.
  Future<bool> _speakBambara(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse(_djeliaTtsUrl),
            headers: {
              'x-api-key': _djeliaApiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'text': text,
              'description': 'Sekou speaks with a clear, warm and natural voice',
              'format': 'mp3',
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;
      await _player.stop();
      await _player.play(BytesSource(response.bodyBytes));
      return true;
    } catch (_) {
      return false;
    }
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
