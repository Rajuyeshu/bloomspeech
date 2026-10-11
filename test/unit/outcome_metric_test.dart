import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/config/constants/app_constants.dart';
import 'package:bloomspeech/models/child_profile.dart';
import 'package:bloomspeech/models/session.dart';

/// The reported outcome is stuttering frequency, and progress is a REDUCTION
/// in it. Reporting its complement inverts the direction a clinician reads.
void main() {
  SessionStats stats({required int fluent, required int dysfluent}) =>
      SessionStats(
        totalUtterances: fluent + dysfluent,
        fluentCount: fluent,
        dysfluentCount: dysfluent,
        fluencyPercentage:
            (fluent + dysfluent) > 0 ? fluent / (fluent + dysfluent) * 100 : 0,
        rewardCyclesCompleted: 0,
        duration: Duration.zero,
      );

  group('stuttering frequency', () {
    test('is the stuttered share of recorded words', () {
      expect(stats(fluent: 15, dysfluent: 5).dysfluencyPercentage, 25.0);
      expect(stats(fluent: 1, dysfluent: 3).dysfluencyPercentage, 75.0);
    });

    test('complements fluency exactly', () {
      final s = stats(fluent: 7, dysfluent: 3);
      expect(s.dysfluencyPercentage + s.fluencyPercentage, closeTo(100, 1e-9));
    });

    test('a session with no words is 0%, not a division by zero', () {
      final s = stats(fluent: 0, dysfluent: 0);
      expect(s.dysfluencyPercentage, 0);
      expect(s.dysfluencyPercentage.isFinite, isTrue);
    });

    test('falls as the child improves', () {
      // The direction the dashboard depends on.
      final early = stats(fluent: 10, dysfluent: 10);
      final later = stats(fluent: 18, dysfluent: 2);
      expect(later.dysfluencyPercentage,
          lessThan(early.dysfluencyPercentage));
    });

    test('survives a stored session round trip', () {
      final original = stats(fluent: 12, dysfluent: 8);
      final restored = SessionStats.fromFirestore(original.toFirestore());
      expect(restored.dysfluencyPercentage,
          closeTo(original.dysfluencyPercentage, 1e-9));
    });
  });

  group('treatment levels', () {
    test('there are four selectable levels', () {
      expect(TherapyLevel.selectable, hasLength(4));
      for (var i = 0; i < 4; i++) {
        expect(TherapyLevel.selectable[i].levelNumber, i + 1);
      }
    });

    test('level 1 covers words, phrases and sentences together', () {
      final one = TherapyLevel.selectable.first;
      expect(one.levelNumber, 1);
      expect(one.description.toLowerCase(), contains('words'));
      expect(one.description.toLowerCase(), contains('phrases'));
      expect(one.description.toLowerCase(), contains('sentences'));
    });

    test('the retired sentence level still parses for old sessions', () {
      final t = TherapyLevel.values.firstWhere((l) => l.name == 'sentence');
      expect(t.legacy, isTrue);
      expect(TherapyLevel.selectable, isNot(contains(t)));
    });
  });

  group('baseline stuttering frequency', () {
    ChildProfile child(Map<String, dynamic> extra) => ChildProfile.fromMap({
          'id': 'c1',
          'name': 'Aarav',
          'date_of_birth': '2019-06-15',
          'clinician_id': 'clin1',
          ...extra,
        });

    test('is read from the child record', () {
      expect(child({'baseline_dysfluency_pct': 18.5}).baselineDysfluencyPct,
          18.5);
    });

    test('is null when never recorded, so no reference line is drawn', () {
      expect(child({}).baselineDysfluencyPct, isNull);
    });

    test('a database without the column simply yields null', () {
      // The column arrives with a later migration; the app must still work.
      expect(child({'name': 'Aarav'}).baselineDysfluencyPct, isNull);
    });

    test('an impossible percentage is discarded rather than charted', () {
      expect(child({'baseline_dysfluency_pct': 150}).baselineDysfluencyPct,
          isNull);
      expect(child({'baseline_dysfluency_pct': -4}).baselineDysfluencyPct,
          isNull);
      expect(child({'baseline_dysfluency_pct': 'abc'}).baselineDysfluencyPct,
          isNull);
    });

    test('survives a write and read back', () {
      final original = child({'baseline_dysfluency_pct': 22.0});
      expect(ChildProfile.fromMap(original.toMap()).baselineDysfluencyPct, 22.0);
    });
  });
}
