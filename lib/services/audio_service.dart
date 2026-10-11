import 'dart:io' show File, Platform;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/bilingual_phrases.dart';

/// Audio service for feedback chimes and TTS
class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Separate player wired to the *voice call* audio route (see
  /// [_speakThroughCallRoute]).
  final AudioPlayer _speechPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _callRouteConfigured = false;

  /// Synthesised phrase files, keyed by locale + text. The feedback phrases
  /// come from a small fixed set, so this is a handful of entries and avoids
  /// re-synthesising on every token.
  final Map<String, String> _synthCache = {};

  /// Initialize TTS settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.45); // Slower for children
    await _flutterTts.setPitch(1.1); // Slightly higher pitch, friendly

    // On the kid's device a Jitsi call is usually running, and it takes
    // exclusive audio focus in voice-communication mode. Default TTS playback
    // is then dropped entirely — the feedback phrase looked like it played but
    // nothing was ever audible. These attributes mark the speech as guidance
    // that should duck the call instead of being discarded.
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _flutterTts.setAudioAttributesForNavigation();
      } catch (e) {
        debugPrint('setAudioAttributesForNavigation unavailable: $e');
      }
    }

    // iOS needs to share the audio session for the same reason.
    if (!kIsWeb && Platform.isIOS) {
      try {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.duckOthers,
          ],
        );
      } catch (e) {
        debugPrint('iOS audio session setup failed: $e');
      }
    }

    _isInitialized = true;
  }

  /// Play a feedback chime sound.
  ///
  /// Returns false if the asset can't play, so callers skip the pause that
  /// only exists to let the chime finish. The chimes are short generated
  /// tones: a bright rising arpeggio for fluent speech, and a soft, low
  /// two-note fall for dysfluent — deliberately gentle rather than a buzzer,
  /// since the child should not hear it as punishment.
  Future<bool> playChime({required bool isSmooth}) async {
    try {
      final asset = isSmooth
          ? 'audio/smooth_chime.wav'
          : 'audio/bumpy_chime.wav';
      await _audioPlayer.play(AssetSource(asset));
      return true;
    } catch (e) {
      debugPrint('Chime asset missing, speaking without it: $e');
      return false;
    }
  }

  /// Play celebration sound for rewards
  Future<void> playCelebration() async {
    try {
      await _audioPlayer.play(AssetSource('audio/celebration.wav'));
    } catch (_) {}
  }

  /// Whether this device can actually speak the therapy language.
  ///
  /// Null until probed. Exposed so a screen can warn the clinician that the
  /// child will hear English — a silent substitution would otherwise look like
  /// the language setting being ignored.
  bool? get kannadaVoiceAvailable => _voiceAvailable['kn-IN'];

  final Map<String, bool> _voiceAvailable = {};

  /// Probe once per locale. `isLanguageAvailable` is a platform channel call,
  /// and running it before every phrase added latency to feedback that has to
  /// follow the child's utterance closely.
  Future<bool> _hasVoice(String locale) async {
    final cached = _voiceAvailable[locale];
    if (cached != null) return cached;
    try {
      final ok = await _flutterTts.isLanguageAvailable(locale) == true;
      _voiceAvailable[locale] = ok;
      return ok;
    } catch (e) {
      debugPrint('TTS availability check failed for $locale: $e');
      _voiceAvailable[locale] = false;
      return false;
    }
  }

  /// Synthesise the feedback phrases ahead of the first utterance.
  ///
  /// The first time a phrase is spoken it must be rendered to a file, which on
  /// a mid-range device takes long enough to be audible as a lag between the
  /// clinician's tap and the child's feedback. Warming the cache at session
  /// start moves that cost off the response-contingent path, where immediacy
  /// is the entire point of the treatment.
  Future<void> warmUp(String languageCode) async {
    if (kIsWeb || !Platform.isAndroid) return;
    await initialize();
    final locale = await _resolveLocale(languageCode);
    for (final entry in BilingualPhrases.feedback.values) {
      final text = entry[languageCode] ?? entry['en'] ?? '';
      if (text.trim().isEmpty) continue;
      try {
        await _synthesiseToCache(text, locale);
      } catch (e) {
        debugPrint('Phrase warm-up failed: $e');
      }
    }
  }

  /// The locale to speak in, falling back when the device has no such voice.
  Future<String> _resolveLocale(String languageCode) async {
    if (languageCode == 'kn' && await _hasVoice('kn-IN')) return 'kn-IN';
    if (await _hasVoice('en-IN')) return 'en-IN';
    return 'en-US';
  }

  /// Speak a feedback phrase.
  ///
  /// [fallbackText] is spoken instead when the device has no voice for the
  /// requested language. Passing Kannada text to an English voice does not
  /// degrade gracefully — it produces sounds that are not words — so the
  /// English phrase is the better failure.
  Future<void> speak({
    required String text,
    required String languageCode,
    String? fallbackText,
  }) async {
    if (text.trim().isEmpty) return;
    await initialize();

    final wantsKannada = languageCode == 'kn';
    final locale = await _resolveLocale(languageCode);
    final usingRequested = !wantsKannada || locale == 'kn-IN';

    if (!usingRequested) {
      debugPrint('No kn-IN voice on this device; speaking the English phrase.');
    }
    final spoken = usingRequested ? text : (fallbackText ?? text);

    try {
      await _flutterTts.setLanguage(locale);
    } catch (e) {
      debugPrint('TTS setLanguage($locale) failed: $e');
    }
    text = spoken;

    // On Android, plain TTS is inaudible while Jitsi holds the audio session
    // in communication mode — the engine plays to the media route, which the
    // call suppresses. Synthesising to a file and playing it back through the
    // voice-call route is the only way the kid actually hears it mid-session.
    if (!kIsWeb && Platform.isAndroid) {
      if (await _speakThroughCallRoute(text, locale)) return;
    }

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  /// Renders [text] to a file and plays it on the voice-call audio route.
  /// Returns false if anything goes wrong, so the caller can fall back to
  /// ordinary TTS (correct on a device with no active call).
  Future<bool> _speakThroughCallRoute(String text, String locale) async {
    try {
      final path = await _synthesiseToCache(text, locale);
      if (path == null) return false;

      if (!_callRouteConfigured) {
        await _speechPlayer.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              contentType: AndroidContentType.speech,
              // Route into the call's audio path rather than the media path.
              usageType: AndroidUsageType.voiceCommunication,
              // Match the mode Jitsi already set; changing it would disrupt
              // the call itself.
              audioMode: AndroidAudioMode.inCommunication,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
          ),
        );
        _callRouteConfigured = true;
      }

      await _speechPlayer.stop();
      await _speechPlayer.play(DeviceFileSource(path));
      return true;
    } catch (e) {
      debugPrint('Call-route speech failed, falling back to TTS: $e');
      return false;
    }
  }

  Future<String?> _synthesiseToCache(String text, String locale) async {
    final key = '$locale::$text';
    final cached = _synthCache[key];
    if (cached != null && File(cached).existsSync()) return cached;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/tts_${key.hashCode.toUnsigned(32).toRadixString(16)}.wav';

    // Without this the call returns before the file is written.
    await _flutterTts.awaitSynthCompletion(true);
    await _flutterTts.synthesizeToFile(text, path, true);

    if (!File(path).existsSync()) {
      debugPrint('synthesizeToFile produced no file at $path');
      return null;
    }
    _synthCache[key] = path;
    return path;
  }

  /// Stop any playing audio
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _speechPlayer.stop();
    await _flutterTts.stop();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _speechPlayer.dispose();
    await _flutterTts.stop();
  }

  /// Play smooth feedback (chime + speech)
  Future<void> playSmoothFeedback({
    required String phrase,
    required String languageCode,
    String? fallbackPhrase,
  }) async {
    final played = await playChime(isSmooth: true);
    // Let the chime land before the phrase, but no longer than it needs — this
    // sits directly between the child's utterance and its consequence.
    if (played) await Future.delayed(const Duration(milliseconds: 180));
    await speak(
        text: phrase, languageCode: languageCode, fallbackText: fallbackPhrase);
  }

  /// Play bumpy feedback (soft sound + speech)
  Future<void> playBumpyFeedback({
    required String phrase,
    required String languageCode,
    String? fallbackPhrase,
  }) async {
    final played = await playChime(isSmooth: false);
    if (played) await Future.delayed(const Duration(milliseconds: 180));
    await speak(
        text: phrase, languageCode: languageCode, fallbackText: fallbackPhrase);
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
