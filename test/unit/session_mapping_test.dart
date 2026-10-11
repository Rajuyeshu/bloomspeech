import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/config/constants/app_constants.dart';
import 'package:bloomspeech/models/session.dart';

/// The shared `active_sessions` row is the only channel between the
/// clinician's device and the child's. Anything it fails to carry across is
/// invisible at runtime — the child's device just quietly uses a default.
void main() {
  group('ActiveSession.fromMap', () {
    test('reads a Supabase row in snake_case', () {
      final s = ActiveSession.fromMap({
        'session_code': 'AB12CD',
        'clinician_id': 'clin1',
        'child_id': 'child1',
        'child_name': 'Aarav',
        'status': 'active',
        'current_token_count': 6,
        'token_goal': 18,
        'therapy_level': 'sentence',
        'play_theme': 'rangoliBuilder',
        'mini_game': 'rangoliPainter',
        'language': 'kn',
        'tokens_per_fluent': 2,
        'tokens_per_dysfluent': 1,
      });

      expect(s.sessionCode, 'AB12CD');
      expect(s.childName, 'Aarav');
      expect(s.currentTokenCount, 6);
      expect(s.tokenGoal, 18);
      expect(s.playTheme, 'rangoliBuilder');
      expect(s.miniGame, 'rangoliPainter');
      expect(s.language, 'kn');
      expect(s.tokensPerFluent, 2);
    });

    test('carries the reward configuration to the child', () {
      final physical = ActiveSession.fromMap({
        'token_goal': 10,
        'therapy_level': 'word',
        'play_theme': 'diyaFestival',
        'mini_game': 'bubbleBurst',
        'reward_type': 'physicalReward',
        'physical_reward': 'sticker',
      });

      // The child's device used to have no way to know this, so it always
      // offered the mini-game even when the clinician had chosen a sticker.
      expect(physical.rewardType, 'physicalReward');
      expect(physical.physicalReward, 'sticker');
    });

    test('defaults to the mini-game when no reward type was stored', () {
      final s = ActiveSession.fromMap({
        'token_goal': 10,
        'therapy_level': 'word',
        'play_theme': 'diyaFestival',
        'mini_game': 'bubbleBurst',
      });
      expect(s.rewardType, 'inAppMiniGame');
      expect(s.physicalReward, isNull);
    });

    test('carries the clinician control flags', () {
      final s = ActiveSession.fromMap({
        'token_goal': 10,
        'therapy_level': 'word',
        'play_theme': 'diyaFestival',
        'mini_game': 'bubbleBurst',
        'kid_video_started': true,
        'kid_audio_muted': true,
        'kid_video_muted': false,
        'kid_user_id': 'kid-uuid',
      });
      expect(s.kidVideoStarted, isTrue);
      expect(s.kidAudioMuted, isTrue);
      expect(s.kidVideoMuted, isFalse);
      expect(s.kidUserId, 'kid-uuid');
    });

    test('the kid waits until the clinician starts the call', () {
      final s = ActiveSession.fromMap({
        'token_goal': 10,
        'therapy_level': 'word',
        'play_theme': 'diyaFestival',
        'mini_game': 'bubbleBurst',
      });
      // Missing column (migration not yet run) must not auto-join the child.
      expect(s.kidVideoStarted, isFalse);
    });

    test('an unknown status falls back to active rather than throwing', () {
      final s = ActiveSession.fromMap({
        'status': 'something-new',
        'token_goal': 10,
        'therapy_level': 'word',
        'play_theme': 'diyaFestival',
        'mini_game': 'bubbleBurst',
      });
      expect(s.status, SessionStatus.active);
    });

    test('accepts both a DateTime and an ISO string for the feedback time', () {
      final iso = ActiveSession.fromMap({
        'token_goal': 10,
        'therapy_level': 'word',
        'play_theme': 'diyaFestival',
        'mini_game': 'bubbleBurst',
        'last_feedback_time': '2025-08-20T10:00:00.000Z',
      });
      final native = ActiveSession.fromMap({
        'token_goal': 10,
        'therapy_level': 'word',
        'play_theme': 'diyaFestival',
        'mini_game': 'bubbleBurst',
        'last_feedback_time': DateTime.utc(2025, 8, 20, 10),
      });
      expect(iso.lastFeedbackTime, isNotNull);
      expect(native.lastFeedbackTime, DateTime.utc(2025, 8, 20, 10));
    });

    test('an empty row produces safe defaults', () {
      final s = ActiveSession.fromMap({});
      expect(s.sessionCode, '');
      expect(s.tokenGoal, AppConstants.defaultTokenGoal);
      expect(s.currentTokenCount, 0);
      expect(s.status, SessionStatus.active);
    });
  });

  group('SessionConfig', () {
    test('round-trips through the wire format', () {
      final config = SessionConfig(
        childId: 'c1',
        childName: 'Meera',
        sessionNumber: 4,
        therapyLevel: 'narrative',
        tokensPerFluent: 2,
        tokensPerDysfluent: 3,
        tokenGoal: 24,
        playTheme: 'peacockGarden',
        rewardType: 'physicalReward',
        miniGame: 'plantWatering',
        sessionTimerMinutes: 15,
        physicalReward: 'sticker',
        language: 'kn',
      );

      final restored = SessionConfig.fromFirestore(config.toFirestore());

      expect(restored.childId, config.childId);
      expect(restored.sessionNumber, config.sessionNumber);
      expect(restored.therapyLevel, config.therapyLevel);
      expect(restored.tokensPerFluent, config.tokensPerFluent);
      expect(restored.tokensPerDysfluent, config.tokensPerDysfluent);
      expect(restored.tokenGoal, config.tokenGoal);
      expect(restored.playTheme, config.playTheme);
      expect(restored.rewardType, config.rewardType);
      expect(restored.miniGame, config.miniGame);
      expect(restored.sessionTimerMinutes, config.sessionTimerMinutes);
      expect(restored.physicalReward, config.physicalReward);
      expect(restored.language, config.language);
    });

    test('copyWith changes one field and leaves the rest alone', () {
      final base = SessionConfig(childId: 'c1', childName: 'Meera');
      final updated = base.copyWith(tokenGoal: 30);
      expect(updated.tokenGoal, 30);
      expect(updated.childId, 'c1');
      expect(updated.playTheme, base.playTheme);
      expect(updated.rewardType, base.rewardType);
    });

    test('an empty map yields the documented defaults', () {
      final c = SessionConfig.fromFirestore({});
      expect(c.tokenGoal, AppConstants.defaultTokenGoal);
      expect(c.tokensPerFluent, AppConstants.defaultTokensPerFluent);
      expect(c.tokensPerDysfluent, AppConstants.defaultTokensPerDysfluent);
      expect(c.rewardType, 'inAppMiniGame');
      expect(c.language, 'en');
    });
  });

  group('Session.fromFirestore', () {
    test('accepts snake_case columns', () {
      final s = Session.fromFirestore({
        'id': 's1',
        'child_id': 'c1',
        'clinician_id': 'clin1',
        'session_number': 3,
        'date': '2025-08-20T10:00:00.000Z',
        'therapy_level': 'sentence',
        'play_theme': 'lotusPond',
        'mini_game': 'bubbleBurst',
        'status': 'completed',
      });
      expect(s.childId, 'c1');
      expect(s.clinicianId, 'clin1');
      expect(s.sessionNumber, 3);
      expect(s.therapyLevel, 'sentence');
      expect(s.playTheme, 'lotusPond');
      expect(s.status, SessionStatus.completed);
    });

    test('a malformed nested config or stats does not throw', () {
      final s = Session.fromFirestore({
        'id': 's1',
        'config': 'not a map',
        'stats': 42,
      });
      expect(s.config.tokenGoal, AppConstants.defaultTokenGoal);
      expect(s.stats.fluencyPercentage, 0);
    });
  });

  group('Utterance', () {
    test('round-trips and tolerates both token-count spellings', () {
      final original = Utterance(
        id: 'u1',
        timestamp: DateTime.utc(2025, 8, 20, 10),
        type: UtteranceType.dysfluent,
        tokenCountAfter: 4,
      );
      final restored = Utterance.fromFirestore({
        'id': 'u1',
        ...original.toFirestore(),
      });
      expect(restored.type, UtteranceType.dysfluent);
      expect(restored.tokenCountAfter, 4);
      expect(restored.timestamp, original.timestamp);

      final snake = Utterance.fromFirestore({
        'type': 'fluent',
        'token_count_after': 9,
      });
      expect(snake.tokenCountAfter, 9);
    });

    test('an unknown type falls back to fluent rather than throwing', () {
      final u = Utterance.fromFirestore({'type': 'mumbled'});
      expect(u.type, UtteranceType.fluent);
    });
  });
}
