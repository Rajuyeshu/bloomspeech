import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/config/constants/app_constants.dart';
import 'package:bloomspeech/models/session.dart';

/// Fluency percentage is the number the whole progress report rests on, and
/// the charts feed it straight into fl_chart, which asserts on NaN or infinity.
void main() {
  Utterance u(UtteranceType type, {int after = 0}) => Utterance(
        id: 'u',
        timestamp: DateTime(2025, 1, 1),
        type: type,
        tokenCountAfter: after,
      );

  group('SessionStats.calculate', () {
    test('computes fluency across a mixed session', () {
      final stats = SessionStats.calculate(
        utterances: [
          u(UtteranceType.fluent),
          u(UtteranceType.fluent),
          u(UtteranceType.fluent),
          u(UtteranceType.dysfluent),
        ],
        rewardCycles: 1,
        duration: const Duration(minutes: 12),
      );

      expect(stats.totalUtterances, 4);
      expect(stats.fluentCount, 3);
      expect(stats.dysfluentCount, 1);
      expect(stats.fluencyPercentage, 75.0);
      expect(stats.rewardCyclesCompleted, 1);
      expect(stats.duration, const Duration(minutes: 12));
    });

    test('an empty session is 0%, not a division by zero', () {
      final stats = SessionStats.calculate(
        utterances: const [],
        rewardCycles: 0,
        duration: Duration.zero,
      );
      expect(stats.totalUtterances, 0);
      expect(stats.fluencyPercentage, 0);
      expect(stats.fluencyPercentage.isFinite, isTrue);
    });

    test('all fluent is 100% and all dysfluent is 0%', () {
      final allFluent = SessionStats.calculate(
        utterances: [u(UtteranceType.fluent), u(UtteranceType.fluent)],
        rewardCycles: 0,
        duration: Duration.zero,
      );
      final allDysfluent = SessionStats.calculate(
        utterances: [u(UtteranceType.dysfluent), u(UtteranceType.dysfluent)],
        rewardCycles: 0,
        duration: Duration.zero,
      );
      expect(allFluent.fluencyPercentage, 100.0);
      expect(allDysfluent.fluencyPercentage, 0.0);
    });
  });

  group('SessionStats.fromFirestore defends the charts', () {
    test('reads a well-formed row', () {
      final stats = SessionStats.fromFirestore({
        'totalUtterances': 10,
        'fluentCount': 8,
        'dysfluentCount': 2,
        'fluencyPercentage': 80.0,
        'rewardCyclesCompleted': 2,
        'durationSeconds': 600,
      });
      expect(stats.fluencyPercentage, 80.0);
      expect(stats.duration, const Duration(minutes: 10));
    });

    test('NaN and infinity collapse to zero instead of crashing fl_chart', () {
      final nan = SessionStats.fromFirestore({'fluencyPercentage': double.nan});
      final inf =
          SessionStats.fromFirestore({'fluencyPercentage': double.infinity});
      expect(nan.fluencyPercentage, 0);
      expect(inf.fluencyPercentage, 0);
      expect(nan.fluencyPercentage.isFinite, isTrue);
      expect(inf.fluencyPercentage.isFinite, isTrue);
    });

    test('percentages are clamped to the chart axes', () {
      expect(
        SessionStats.fromFirestore({'fluencyPercentage': 150}).fluencyPercentage,
        100,
      );
      expect(
        SessionStats.fromFirestore({'fluencyPercentage': -20}).fluencyPercentage,
        0,
      );
    });

    test('numeric strings from the database are accepted', () {
      final stats = SessionStats.fromFirestore({
        'fluencyPercentage': '62.5',
        'fluentCount': '5',
        'durationSeconds': '300',
      });
      expect(stats.fluencyPercentage, 62.5);
      expect(stats.fluentCount, 5);
      expect(stats.duration, const Duration(minutes: 5));
    });

    test('a clock that moved backwards cannot produce a negative bar', () {
      final stats = SessionStats.fromFirestore({'durationSeconds': -120});
      expect(stats.duration, const Duration(minutes: 2));
      expect(stats.duration.isNegative, isFalse);
    });

    test('a missing or junk row degrades to zeroes', () {
      final empty = SessionStats.fromFirestore({});
      final junk = SessionStats.fromFirestore({
        'fluencyPercentage': 'not a number',
        'fluentCount': null,
        'durationSeconds': {},
      });
      for (final s in [empty, junk]) {
        expect(s.fluencyPercentage, 0);
        expect(s.fluentCount, 0);
        expect(s.duration, Duration.zero);
      }
    });
  });

  test('calculate then serialise then read back is stable', () {
    final original = SessionStats.calculate(
      utterances: [
        u(UtteranceType.fluent),
        u(UtteranceType.dysfluent),
        u(UtteranceType.fluent),
      ],
      rewardCycles: 3,
      duration: const Duration(seconds: 754),
    );
    final restored = SessionStats.fromFirestore(original.toFirestore());

    expect(restored.totalUtterances, original.totalUtterances);
    expect(restored.fluentCount, original.fluentCount);
    expect(restored.dysfluentCount, original.dysfluentCount);
    expect(restored.rewardCyclesCompleted, original.rewardCyclesCompleted);
    expect(restored.duration, original.duration);
    expect(restored.fluencyPercentage,
        closeTo(original.fluencyPercentage, 0.0001));
  });
}
