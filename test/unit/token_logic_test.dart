import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/config/constants/app_constants.dart';
import 'package:bloomspeech/models/session.dart';
import 'package:bloomspeech/screens/session/active_session_screen.dart';

/// Response-cost therapy: a fluent utterance earns tokens, a dysfluent one
/// costs them, and reaching the goal completes a reward cycle. This is the
/// clinical heart of the app and every number in the progress report descends
/// from it.
void main() {
  ActiveSessionState session({
    int tokens = 0,
    int goal = 10,
    int perFluent = 1,
    int perDysfluent = 1,
    int cycles = 0,
  }) =>
      ActiveSessionState(
        config: SessionConfig(
          childId: 'c1',
          childName: 'Aarav',
          tokenGoal: goal,
          tokensPerFluent: perFluent,
          tokensPerDysfluent: perDysfluent,
        ),
        currentTokens: tokens,
        rewardCycles: cycles,
        startTime: DateTime(2025, 1, 1),
      );

  group('fluent utterances earn tokens', () {
    test('adds the configured number of tokens', () {
      final out = session(tokens: 3, perFluent: 2).recordFluent();
      expect(out.state.currentTokens, 5);
      expect(out.goalReached, isFalse);
    });

    test('records the utterance with the count it produced', () {
      final out = session(tokens: 3).recordFluent();
      expect(out.state.utterances, hasLength(1));
      expect(out.state.utterances.single.type, UtteranceType.fluent);
      expect(out.state.utterances.single.tokenCountAfter, 4);
    });

    test('appends rather than replacing the utterance history', () {
      var s = session();
      for (var i = 0; i < 4; i++) {
        s = s.recordFluent().state;
      }
      expect(s.utterances, hasLength(4));
      expect(s.currentTokens, 4);
    });
  });

  group('reaching the goal completes a cycle', () {
    test('the board resets and the cycle count rises', () {
      final out = session(tokens: 9, goal: 10).recordFluent();
      expect(out.goalReached, isTrue);
      expect(out.state.currentTokens, 0, reason: 'board clears for next cycle');
      expect(out.state.rewardCycles, 1);
      expect(out.state.showingReward, isTrue);
    });

    test('the utterance still records what the child earned', () {
      final out = session(tokens: 9, goal: 10).recordFluent();
      // The record is of the achievement, not of the board being cleared.
      expect(out.state.utterances.single.tokenCountAfter, 10);
    });

    test('overshooting the goal still completes exactly one cycle', () {
      // Three tokens per utterance from eight, with a goal of ten.
      final out = session(tokens: 8, goal: 10, perFluent: 3).recordFluent();
      expect(out.goalReached, isTrue);
      expect(out.state.rewardCycles, 1);
      expect(out.state.currentTokens, 0);
    });

    test('cycles accumulate across a long session', () {
      var s = session(goal: 3);
      for (var i = 0; i < 9; i++) {
        s = s.recordFluent().state;
      }
      expect(s.rewardCycles, 3);
      expect(s.utterances, hasLength(9));
    });

    test('a goal of one rewards on every fluent utterance', () {
      final out = session(goal: 1).recordFluent();
      expect(out.goalReached, isTrue);
      expect(out.state.rewardCycles, 1);
    });
  });

  group('dysfluent utterances cost tokens', () {
    test('subtracts the configured cost', () {
      final out = session(tokens: 5, perDysfluent: 2).recordDysfluent();
      expect(out.state.currentTokens, 3);
    });

    test('never goes below zero', () {
      // The response cost must not produce a negative board — it would be
      // meaningless to the child and impossible to draw.
      final out = session(tokens: 1, perDysfluent: 3).recordDysfluent();
      expect(out.state.currentTokens, 0);
      expect(out.state.currentTokens, isNonNegative);
    });

    test('an empty board stays at zero', () {
      final out = session(tokens: 0).recordDysfluent();
      expect(out.state.currentTokens, 0);
      expect(out.state.utterances.single.type, UtteranceType.dysfluent);
    });

    test('never completes a reward cycle', () {
      final out = session(tokens: 9, goal: 10).recordDysfluent();
      expect(out.goalReached, isFalse);
      expect(out.state.rewardCycles, 0);
      expect(out.state.showingReward, isFalse);
    });

    test('a cost cannot undo a reward already awarded', () {
      var s = session(tokens: 9, goal: 10).recordFluent().state;
      expect(s.rewardCycles, 1);
      s = s.recordDysfluent().state;
      expect(s.rewardCycles, 1, reason: 'earned cycles are permanent');
      expect(s.currentTokens, 0);
    });
  });

  group('a session end to end', () {
    test('stats derived from the recorded utterances match the tally', () {
      var s = session(goal: 5);
      // Five fluent (one cycle at the fifth), then two dysfluent.
      for (var i = 0; i < 5; i++) {
        s = s.recordFluent().state;
      }
      s = s.recordDysfluent().state;
      s = s.recordDysfluent().state;

      final stats = SessionStats.calculate(
        utterances: s.utterances,
        rewardCycles: s.rewardCycles,
        duration: const Duration(minutes: 10),
      );

      expect(stats.totalUtterances, 7);
      expect(stats.fluentCount, 5);
      expect(stats.dysfluentCount, 2);
      expect(stats.fluencyPercentage, closeTo(71.43, 0.01));
      expect(stats.rewardCyclesCompleted, 1);
      expect(s.rewardCycles, 1);
    });

    test('the previous state is not mutated', () {
      final before = session(tokens: 4);
      final after = before.recordFluent().state;

      expect(before.currentTokens, 4, reason: 'states must be immutable');
      expect(before.utterances, isEmpty);
      expect(after.currentTokens, 5);
      expect(after.utterances, hasLength(1));
    });

    test('feedback type is recorded for the child device to mirror', () {
      expect(session().recordFluent().state.lastFeedbackType, 'fluent');
      expect(session().recordDysfluent().state.lastFeedbackType, 'dysfluent');
    });
  });
}
