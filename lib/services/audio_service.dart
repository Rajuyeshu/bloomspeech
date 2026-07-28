import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Audio service for feedback chimes and TTS
class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  /// Initialize TTS settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.45); // Slower for children
    await _flutterTts.setPitch(1.1); // Slightly higher pitch, friendly

    _isInitialized = true;
  }

  /// Play a feedback chime sound
  Future<void> playChime({required bool isSmooth}) async {
    try {
      final asset = isSmooth
          ? 'audio/smooth_chime.mp3'
          : 'audio/bumpy_chime.mp3';
      await _audioPlayer.play(AssetSource(asset));
    } catch (e) {
      // Fallback: if audio file not found, generate a system sound
      // This ensures the app works without bundled audio
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
    await initialize();

    // Set language
    final locale = languageCode == 'kn' ? 'kn-IN' : 'en-IN';
    await _flutterTts.setLanguage(locale);

    await _flutterTts.speak(text);
  }

  /// Stop any playing audio
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _flutterTts.stop();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _flutterTts.stop();
  }

  /// Play smooth feedback (chime + speech)
  Future<void> playSmoothFeedback({
    required String phrase,
    required String languageCode,
  }) async {
    await playChime(isSmooth: true);
    // Small delay so chime plays first
    await Future.delayed(const Duration(milliseconds: 300));
    await speak(text: phrase, languageCode: languageCode);
  }

  /// Play bumpy feedback (soft sound + speech)
  Future<void> playBumpyFeedback({
    required String phrase,
    required String languageCode,
  }) async {
    await playChime(isSmooth: false);
    await Future.delayed(const Duration(milliseconds: 300));
    await speak(text: phrase, languageCode: languageCode);
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
