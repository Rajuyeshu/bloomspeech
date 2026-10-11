import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/models/session.dart';
import 'package:bloomspeech/services/firestore_service.dart';

/// Creating the shared session row must survive a database whose schema is
/// older than the app. If the insert fails there is no row, and the child's
/// device answers a perfectly valid code with "Session not found" — with
/// nothing in the UI to say why.
void main() {
  group('reading the missing column out of a database error', () {
    test('parses the Postgres 42703 wording', () {
      const message = 'column "tokens_per_fluent" of relation '
          '"active_sessions" does not exist';
      expect(FirestoreService.missingColumnName(message), 'tokens_per_fluent');
    });

    test('parses the PostgREST schema-cache wording', () {
      const message = "Could not find the 'reward_type' column of "
          "'active_sessions' in the schema cache";
      expect(FirestoreService.missingColumnName(message), 'reward_type');
    });

    test('parses a single-quoted column reference', () {
      expect(
        FirestoreService.missingColumnName("column 'kid_user_id' not found"),
        'kid_user_id',
      );
    });

    test('returns null when the error names no column', () {
      expect(FirestoreService.missingColumnName('connection refused'), isNull);
      expect(FirestoreService.missingColumnName(''), isNull);
    });

    test('does not mistake a table name for a column name', () {
      // The column is quoted first in both wordings, so the first match wins.
      const message = 'column "physical_reward" of relation '
          '"active_sessions" does not exist';
      expect(FirestoreService.missingColumnName(message),
          isNot('active_sessions'));
    });
  });

  group('the row can shed unknown columns and stay usable', () {
    ActiveSession subject() => ActiveSession.fromConfig(
          SessionConfig(
            childId: 'child-1',
            childName: 'Aarav',
            tokenGoal: 18,
            playTheme: 'peacockGarden',
            rewardType: 'physicalReward',
            physicalReward: 'sticker',
          ),
          sessionCode: 'AJHJ32',
          clinicianId: 'clin-1',
        );

    test('the columns a session cannot work without are always present', () {
      final row = subject().toMap();
      // These are the ones createActiveSession refuses to drop: without them
      // the row cannot be found or joined at all.
      for (final essential in [
        'session_code',
        'clinician_id',
        'child_id',
        'token_goal',
      ]) {
        expect(row[essential], isNotNull, reason: essential);
      }
    });

    test('dropping every optional column still leaves a joinable session', () {
      final reduced = subject().toMapWithoutOptionalColumns();
      expect(reduced['session_code'], 'AJHJ32');
      expect(reduced['child_name'], 'Aarav');
      expect(reduced['token_goal'], 18);
      expect(reduced['play_theme'], 'peacockGarden');

      // And the child's device can still read it back.
      final restored = ActiveSession.fromMap(reduced);
      expect(restored.sessionCode, 'AJHJ32');
      expect(restored.tokenGoal, 18);
      expect(restored.playTheme, 'peacockGarden');
    });

    test('a row stripped to the essentials still parses with defaults', () {
      // Simulates the worst case: an old schema that has almost nothing.
      final restored = ActiveSession.fromMap({
        'session_code': 'AJHJ32',
        'clinician_id': 'clin-1',
        'child_id': 'child-1',
        'token_goal': 18,
      });
      expect(restored.sessionCode, 'AJHJ32');
      expect(restored.rewardType, 'inAppMiniGame');
      expect(restored.kidVideoStarted, isFalse);
      expect(restored.playTheme, 'diyaFestival');
    });

    test('every droppable column is one the app can genuinely do without', () {
      // A column listed as optional but actually required would let the
      // retry loop produce a session the child cannot use.
      const essential = {
        'session_code',
        'clinician_id',
        'child_id',
        'token_goal',
      };
      for (final column in ActiveSession.optionalColumns) {
        expect(essential.contains(column), isFalse,
            reason: '$column must never be dropped');
      }
    });
  });
}
