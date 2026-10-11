import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/config/constants/app_constants.dart';
import 'package:bloomspeech/models/session.dart';

/// `active_sessions` is the only channel between the clinician's device and
/// the child's. A field this row fails to carry is not an error anywhere — the
/// child's device simply uses a default, and the clinician's choice is gone.
void main() {
  SessionConfig config({
    String rewardType = 'physicalReward',
    String? physicalReward = 'sticker',
    String language = 'kn',
  }) =>
      SessionConfig(
        childId: 'child-1',
        childName: 'Aarav',
        therapyLevel: 'sentence',
        tokensPerFluent: 2,
        tokensPerDysfluent: 3,
        tokenGoal: 24,
        playTheme: 'peacockGarden',
        rewardType: rewardType,
        miniGame: 'rangoliPainter',
        physicalReward: physicalReward,
        language: language,
      );

  group('fromConfig carries the whole setup', () {
    test('every field the child needs survives the mapping', () {
      final c = config();
      final row = ActiveSession.fromConfig(c,
          sessionCode: 'AB12CD', clinicianId: 'clin-1');

      expect(row.sessionCode, 'AB12CD');
      expect(row.clinicianId, 'clin-1');
      expect(row.childId, c.childId);
      expect(row.childName, c.childName);
      expect(row.tokenGoal, c.tokenGoal);
      expect(row.therapyLevel, c.therapyLevel);
      expect(row.playTheme, c.playTheme);
      expect(row.miniGame, c.miniGame);
      expect(row.tokensPerFluent, c.tokensPerFluent);
      expect(row.tokensPerDysfluent, c.tokensPerDysfluent);

      // The three that one construction site used to omit.
      expect(row.rewardType, 'physicalReward');
      expect(row.physicalReward, 'sticker');
      expect(row.language, 'kn');
    });

    test('a physical reward is never downgraded to the mini-game default', () {
      final row = ActiveSession.fromConfig(
        config(rewardType: 'physicalReward'),
        sessionCode: 'X',
        clinicianId: 'c',
      );
      expect(row.rewardType, isNot('inAppMiniGame'));
    });

    test('a new session starts with the call and reward inactive', () {
      final row = ActiveSession.fromConfig(config(),
          sessionCode: 'X', clinicianId: 'c');
      expect(row.currentTokenCount, 0);
      expect(row.rewardCyclesCompleted, 0);
      expect(row.rewardActive, isFalse);
      expect(row.miniGameActive, isFalse);
      expect(row.status, SessionStatus.active);
      // The child must wait for the clinician to start the call.
      expect(row.kidVideoStarted, isFalse);
    });
  });

  group('toMap writes the complete row', () {
    ActiveSession subject() => ActiveSession.fromConfig(
          config(),
          sessionCode: 'AB12CD',
          clinicianId: 'clin-1',
        ).copyWith(
          currentTokenCount: 7,
          rewardCyclesCompleted: 2,
          lastFeedbackType: 'fluent',
          lastFeedbackTime: DateTime.utc(2025, 8, 20, 10),
          kidUserId: 'kid-1',
          kidVideoStarted: true,
          kidAudioMuted: true,
        );

    test('includes every column the child device reads back', () {
      final map = subject().toMap();
      for (final column in [
        'session_code',
        'clinician_id',
        'child_id',
        'child_name',
        'status',
        'current_token_count',
        'token_goal',
        'therapy_level',
        'play_theme',
        'mini_game',
        'language',
        'reward_cycles_completed',
        'tokens_per_fluent',
        'tokens_per_dysfluent',
        'reward_type',
        'physical_reward',
        'kid_user_id',
        'kid_video_started',
        'kid_audio_muted',
        'kid_video_muted',
      ]) {
        expect(map.containsKey(column), isTrue,
            reason: '$column is missing — the child device will use a default');
      }
    });

    test('uses snake_case keys only, matching the table', () {
      for (final key in subject().toMap().keys) {
        expect(key, isNot(matches(RegExp('[A-Z]'))),
            reason: '"$key" is camelCase; Postgres would reject it');
      }
    });

    test('timestamps are written as UTC with an explicit zone', () {
      final map = subject().toMap();
      expect(map['last_feedback_time'], '2025-08-20T10:00:00.000Z');
    });

    test('a null feedback time stays null rather than becoming a string', () {
      final map = ActiveSession.fromConfig(config(),
              sessionCode: 'X', clinicianId: 'c')
          .toMap();
      expect(map['last_feedback_time'], isNull);
    });

    test('round-trips through fromMap without losing a field', () {
      final original = subject();
      final restored = ActiveSession.fromMap(original.toMap());

      expect(restored.sessionCode, original.sessionCode);
      expect(restored.clinicianId, original.clinicianId);
      expect(restored.childId, original.childId);
      expect(restored.childName, original.childName);
      expect(restored.status, original.status);
      expect(restored.currentTokenCount, original.currentTokenCount);
      expect(restored.tokenGoal, original.tokenGoal);
      expect(restored.therapyLevel, original.therapyLevel);
      expect(restored.playTheme, original.playTheme);
      expect(restored.miniGame, original.miniGame);
      expect(restored.language, original.language);
      expect(restored.rewardCyclesCompleted, original.rewardCyclesCompleted);
      expect(restored.tokensPerFluent, original.tokensPerFluent);
      expect(restored.tokensPerDysfluent, original.tokensPerDysfluent);
      expect(restored.rewardType, original.rewardType);
      expect(restored.physicalReward, original.physicalReward);
      expect(restored.kidUserId, original.kidUserId);
      expect(restored.kidVideoStarted, original.kidVideoStarted);
      expect(restored.kidAudioMuted, original.kidAudioMuted);
      expect(restored.kidVideoMuted, original.kidVideoMuted);
      expect(restored.lastFeedbackType, original.lastFeedbackType);
      expect(restored.lastFeedbackTime, original.lastFeedbackTime);
    });
  });

  group('degrading onto a database without the later migrations', () {
    test('drops exactly the optional columns and keeps the rest', () {
      final row = ActiveSession.fromConfig(config(),
          sessionCode: 'X', clinicianId: 'c');
      final full = row.toMap();
      final reduced = row.toMapWithoutOptionalColumns();

      for (final column in ActiveSession.optionalColumns) {
        expect(reduced.containsKey(column), isFalse, reason: column);
      }
      expect(reduced.keys.toSet(),
          full.keys.toSet().difference(ActiveSession.optionalColumns.toSet()));
      // The session must still be usable: the essentials are all present.
      expect(reduced['session_code'], 'X');
      expect(reduced['token_goal'], 24);
      expect(reduced['play_theme'], 'peacockGarden');
    });

    test('every optional column really is one the base schema lacked', () {
      final full = ActiveSession.fromConfig(config(),
              sessionCode: 'X', clinicianId: 'c')
          .toMap();
      for (final column in ActiveSession.optionalColumns) {
        expect(full.containsKey(column), isTrue,
            reason: '$column is listed as optional but never written');
      }
    });
  });

  group('copyWith preserves what it was not asked to change', () {
    test('updating the token count keeps the reward configuration', () {
      final original = ActiveSession.fromConfig(config(),
          sessionCode: 'X', clinicianId: 'c');
      final updated = original.copyWith(currentTokenCount: 5);

      expect(updated.currentTokenCount, 5);
      // These used to reset to their defaults on any copyWith.
      expect(updated.rewardType, 'physicalReward');
      expect(updated.physicalReward, 'sticker');
    });

    test('updating the token count keeps the clinician control flags', () {
      final original = ActiveSession.fromConfig(config(),
              sessionCode: 'X', clinicianId: 'c')
          .copyWith(
        kidVideoStarted: true,
        kidAudioMuted: true,
        kidVideoMuted: true,
        kidUserId: 'kid-1',
      );

      final updated = original.copyWith(currentTokenCount: 3);
      expect(updated.kidVideoStarted, isTrue,
          reason: 'the child would be dropped from the call mid-session');
      expect(updated.kidAudioMuted, isTrue);
      expect(updated.kidVideoMuted, isTrue);
      expect(updated.kidUserId, 'kid-1');
    });

    test('an empty copyWith is an exact copy', () {
      final original = ActiveSession.fromConfig(config(),
              sessionCode: 'X', clinicianId: 'c')
          .copyWith(kidUserId: 'kid-1', kidVideoStarted: true);
      expect(original.copyWith().toMap(), original.toMap());
    });
  });
}
