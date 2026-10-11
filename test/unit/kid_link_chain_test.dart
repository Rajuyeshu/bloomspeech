import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/models/session.dart';

/// A child sees their own progress only if `children.linked_user_id` holds
/// their auth id. That link is written by the clinician at save time, reading
/// the child's id off `active_sessions.kid_user_id`.
///
/// Every step of that chain used to fail silently — including the step that
/// simply finds no id, which is what a database without the column produces.
/// The session saved, the clinician saw success, and the child's progress was
/// permanently empty with nothing recorded to say why.
void main() {
  Map<String, dynamic> row({Map<String, dynamic> extra = const {}}) => {
        'session_code': 'AB12CD',
        'clinician_id': 'clin-1',
        'child_id': 'child-1',
        'token_goal': 10,
        'therapy_level': 'word',
        'play_theme': 'diyaFestival',
        'mini_game': 'bubbleBurst',
        ...extra,
      };

  /// Mirrors the decision `_saveSession` makes before linking.
  bool canLink(ActiveSession s) =>
      s.kidUserId != null && s.kidUserId!.isNotEmpty;

  group('reading the child id off the session row', () {
    test('is available once the child announced itself', () {
      final s = ActiveSession.fromMap(
          row(extra: {'kid_user_id': 'a19e0bb5-5711-4733-a184-6491618cdeea'}));
      expect(s.kidUserId, 'a19e0bb5-5711-4733-a184-6491618cdeea');
      expect(canLink(s), isTrue);
    });

    test('is absent when the column does not exist', () {
      // This is the case that silently skipped linking altogether.
      final s = ActiveSession.fromMap(row());
      expect(s.kidUserId, isNull);
      expect(canLink(s), isFalse);
    });

    test('an empty string is treated as absent, not as a valid id', () {
      final s = ActiveSession.fromMap(row(extra: {'kid_user_id': ''}));
      expect(canLink(s), isFalse,
          reason: 'linking to an empty id would match no child at all');
    });

    test('the camelCase spelling is accepted', () {
      final s = ActiveSession.fromMap(row(extra: {'kidUserId': 'kid-1'}));
      expect(s.kidUserId, 'kid-1');
      expect(canLink(s), isTrue);
    });
  });

  group('creating the session must not undo what the child wrote', () {
    ActiveSession subject() => ActiveSession.fromConfig(
          SessionConfig(childId: 'child-1', childName: 'Aarav'),
          sessionCode: 'AB12CD',
          clinicianId: 'clin-1',
        );

    test('the creation payload omits every kid-owned column', () {
      final create = subject().toCreateMap();
      for (final column in ActiveSession.kidOwnedColumns) {
        expect(create.containsKey(column), isFalse,
            reason: '$column would be written as null over the child\'s value');
      }
    });

    test('it still carries everything the session needs', () {
      final create = subject().toCreateMap();
      for (final column in [
        'session_code',
        'clinician_id',
        'child_id',
        'token_goal',
        'play_theme',
        'reward_type',
        'language',
      ]) {
        expect(create.containsKey(column), isTrue, reason: column);
      }
    });

    test('a re-created session leaves an existing child id intact', () {
      // Session creation is an upsert. Simulate the row as it stands after the
      // child has joined, then apply a second creation over the top.
      const kidId = 'a19e0bb5-5711-4733-a184-6491618cdeea';
      final existing = {
        'session_code': 'AB12CD',
        'clinician_id': 'clin-1',
        'child_id': 'child-1',
        'token_goal': 10,
        'therapy_level': 'word',
        'play_theme': 'flowerBasket',
        'mini_game': 'bubbleBurst',
        'kid_user_id': kidId,
      };

      final merged = {...existing, ...subject().toCreateMap()};

      expect(merged['kid_user_id'], kidId,
          reason: 'this is the bug that emptied the child\'s progress screens');
      expect(ActiveSession.fromMap(merged).kidUserId, kidId);
    });

    test('the full map would have destroyed it — the difference is the fix', () {
      const kidId = 'kid-1';
      final existing = {'kid_user_id': kidId};
      final withFullMap = {...existing, ...subject().toMap()};
      expect(withFullMap['kid_user_id'], isNull,
          reason: 'demonstrates why toCreateMap exists');
    });
  });

  group('the chain as a whole', () {
    test('a fully migrated database links end to end', () {
      const kidId = 'a19e0bb5-5711-4733-a184-6491618cdeea';

      // 1. The child writes its id onto the shared row.
      final announced = ActiveSession.fromMap(row(extra: {
        'kid_user_id': kidId,
        'kid_video_started': false,
      }));

      // 2. The clinician reads it back at save time.
      expect(canLink(announced), isTrue);
      expect(announced.kidUserId, kidId);

      // 3. …and writes it to the child record, which is what the child's
      //    progress query then matches on.
      expect(announced.childId, 'child-1');
    });

    test('a database missing the column breaks the chain at step one', () {
      final announced = ActiveSession.fromMap(row());
      expect(canLink(announced), isFalse);
      // The clinician has nothing to link, so the child's progress query
      // returns nothing — exactly the "0 rows" the diagnostics report.
      expect(announced.kidUserId, isNull);
    });
  });
}
