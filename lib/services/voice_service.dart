import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Audio de l'app — **uniquement** via Djelia (https://djelia.cloud), la
/// seule API hébergée avec une vraie synthèse vocale bambara. Il n'y a
/// volontairement aucune voix de secours (plus de voix française) : si
/// Djelia est injoignable ou non configuré, [speak] retourne `false` et
/// l'appelant affiche un message au lieu de lire du faux avec un accent
/// français.
///
/// Clé à fournir au build/run : `--dart-define=DJELIA_API_KEY=...`.
/// Attention : une clé passée par dart-define est lisible dans le binaire
/// (surtout sur le web) — pour une diffusion publique, faire passer l'appel
/// par un petit proxy serveur qui garde la clé.
/// Une URL de proxy peut être donnée via `--dart-define=DJELIA_TTS_URL=...`.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  static const _djeliaApiKey = String.fromEnvironment('DJELIA_API_KEY');
  static const _djeliaTtsUrl = String.fromEnvironment(
    'DJELIA_TTS_URL',
    defaultValue: 'https://djelia.cloud/api/v1/models/tts',
  );

  final AudioPlayer _player = AudioPlayer();
  final Map<String, Uint8List> _cache = {};

  /// Vrai si une clé (ou un proxy) est configuré — permet à l'UI de
  /// prévenir l'utilisateur avant même d'essayer.
  static bool get isConfigured => _djeliaApiKey.isNotEmpty || _djeliaTtsUrl != 'https://djelia.cloud/api/v1/models/tts';

  /// Retire les annotations entre parenthèses (« é (fermé) » → « é »)
  /// pour que la synthèse ne lise pas les indications pédagogiques.
  static String cleanForSpeech(String text) => text.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();

  /// Lit [text] en bambara via Djelia. Ne lève jamais d'exception ;
  /// retourne `false` en cas d'échec (réseau, clé, quota).
  Future<bool> speak(String text) async {
    final clean = cleanForSpeech(text);
    if (clean.isEmpty || !isConfigured) return false;
    try {
      var bytes = _cache[clean];
      if (bytes == null) {
        final response = await http
            .post(
              Uri.parse(_djeliaTtsUrl),
              headers: {
                if (_djeliaApiKey.isNotEmpty) 'x-api-key': _djeliaApiKey,
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'text': clean,
                'description': 'Sekou speaks with a clear, warm and natural voice',
                'format': 'mp3',
              }),
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) return false;
        bytes = response.bodyBytes;
        _cache[clean] = bytes;
      }
      await _player.stop();
      await _player.play(BytesSource(bytes));
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Lit [text] via Djelia et, si l'audio n'est pas disponible, le dit
/// clairement à l'utilisateur plutôt que de basculer sur une autre voix.
Future<void> speakOrNotify(BuildContext context, String text) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await TtsService.instance.speak(text);
  if (!ok) {
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(
      content: Text(TtsService.isConfigured
          ? "Audio Djelia indisponible pour l'instant — vérifie ta connexion."
          : "Audio non configuré (clé Djelia manquante)."),
    ));
  }
}
