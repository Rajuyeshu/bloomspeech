import 'dart:io' show File, Platform;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

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
  /// Returns false when the asset is missing so callers can skip the pause
  /// that exists only to let the chime finish. `assets/audio/` currently ships
  /// empty, so this is the normal path rather than an exceptional one.
  Future<bool> playChime({required bool isSmooth}) async {
    try {
      final asset = isSmooth
          ? 'audio/smooth_chime.mp3'
          : 'audio/bumpy_chime.mp3';
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
      await _audioPlayer.play(AssetSource('audio/celebration.mp3'));
    } catch (_) {}
  }

  /// Speak text using TTS
  Future<void> speak({
    required String text,
    required String languageCode,
  }) async {
    if (text.trim().isEmpty) return;
    await initialize();

    // Set language. Many devices ship no kn-IN (or even en-IN) voice; setting
    // an unavailable locale can leave the engine unable to speak at all, so
    // fall back rather than losing the phrase entirely.
    final locale = languageCode == 'kn' ? 'kn-IN' : 'en-IN';
    try {
      final available = await _flutterTts.isLanguageAvailable(locale);
      await _flutterTts.setLanguage(available == true ? locale : 'en-US');
    } catch (e) {
      debugPrint('TTS language $locale unavailable, using default: $e');
    }

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
  }) async {
    final played = await playChime(isSmooth: true);
    // Small delay so chime plays first — pointless if there was no chime.
    if (played) await Future.delayed(const Duration(milliseconds: 300));
    await speak(text: phrase, languageCode: languageCode);
  }

  /// Play bumpy feedback (soft sound + speech)
  Future<void> playBumpyFeedback({
    required String phrase,
    required String languageCode,
  }) async {
    final played = await playChime(isSmooth: false);
    if (played) await Future.delayed(const Duration(milliseconds: 300));
    await speak(text: phrase, languageCode: languageCode);
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
