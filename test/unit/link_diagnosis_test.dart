import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/models/session.dart';

/// A null `kid_user_id` has two causes that need opposite responses: the
/// database lacks the column (run the migration), or no child device joined
/// (nothing is wrong — the clinician was testing alone). Treating both as a
/// failure is what made the real problem hard to find across several rounds.
void main() {
  Map<String, dynamic> row({Map<String, dynamic> extra = const {}}) => {
        'session_code': 'AB12CD',
        'clinician_id': 'clin-1',
        'child_id': 'child-1',
        'token_goal': 10,
        'therapy_level': 'word',
        'play_theme': 'flowerBasket',
        'mini_game': 'bubbleBurst',
        ...extra,
      };

  test('a database without the column is identifiable', () {
    final s = ActiveSession.fromMap(row());
    expect(s.kidUserIdColumnPresent, isFalse);
    expect(s.kidUserId, isNull);
  });

  test('a session no child joined is identifiable, and is not a fault', () {
    // The column exists and is simply empty.
    final s = ActiveSession.fromMap(row(extra: {'kid_user_id': null}));
    expect(s.kidUserIdColumnPresent, isTrue);
    expect(s.kidUserId, isNull);
  });

  test('a child that joined is linkable', () {
    final s = ActiveSession.fromMap(row(extra: {'kid_user_id': 'kid-1'}));
    expect(s.kidUserIdColumnPresent, isTrue);
    expect(s.kidUserId, 'kid-1');
  });

  test('the camelCase spelling counts as present', () {
    final s = ActiveSession.fromMap(row(extra: {'kidUserId': 'kid-1'}));
    expect(s.kidUserIdColumnPresent, isTrue);
  });

  test('a row written by this app always carries the column', () {
    // toMap includes it, so a round trip must never look like a missing column.
    final original = ActiveSession.fromConfig(
      SessionConfig(childId: 'c', childName: 'A'),
      sessionCode: 'X',
      clinicianId: 'clin',
    );
    expect(ActiveSession.fromMap(original.toMap()).kidUserIdColumnPresent,
        isTrue);
  });

  test('the creation payload omits it, so creation cannot erase it', () {
    final create = ActiveSession.fromConfig(
      SessionConfig(childId: 'c', childName: 'A'),
      sessionCode: 'X',
      clinicianId: 'clin',
    ).toCreateMap();
    expect(create.containsKey('kid_user_id'), isFalse);
  });
}
