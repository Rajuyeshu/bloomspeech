import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/config/constants/app_constants.dart';
import 'package:bloomspeech/widgets/theme_token_board.dart';

/// Response Cost only works if the child perceives the cost. Gaining a token
/// was always obvious — something appeared — but losing one only dimmed a
/// glyph, which is easy to miss on a board of twenty. The board now animates
/// the departing token and shows how many went.
void main() {
  Future<void> pump(WidgetTester tester, int current, int goal) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 300,
          child: ThemeTokenBoardWidget(
            theme: PlayTheme.chocolateBox,
            currentTokens: current,
            tokenGoal: goal,
          ),
        ),
      ),
    ));
  }

  testWidgets('losing a token shows how many were lost', (tester) async {
    await pump(tester, 6, 10);
    expect(find.text('−1'), findsNothing);

    await pump(tester, 5, 10);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('−1'), findsOneWidget,
        reason: 'the child must see that something was taken away');
  });

  testWidgets('losing several tokens reports the real number', (tester) async {
    await pump(tester, 9, 12);
    await pump(tester, 6, 12);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('−3'), findsOneWidget);
  });

  testWidgets('a reward cycle is not shown as a loss', (tester) async {
    // Reaching the goal also drops the count — to zero — but that is a
    // celebration. Showing "−10" at the moment the child earns their reward
    // would teach exactly the wrong thing.
    await pump(tester, 10, 10);
    await pump(tester, 0, 10);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('−'), findsNothing,
        reason: 'a completed reward cycle must never read as a penalty');
  });

  testWidgets('earning a token shows no loss indicator', (tester) async {
    await pump(tester, 4, 10);
    await pump(tester, 5, 10);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('−'), findsNothing);
  });

  testWidgets('earning again clears a loss still on screen', (tester) async {
    await pump(tester, 5, 10);
    await pump(tester, 4, 10);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('−1'), findsOneWidget);

    // The child recovers before the animation has finished.
    await pump(tester, 5, 10);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('−1'), findsNothing,
        reason: 'the refilled slot must not still be animating away');
  });

  testWidgets('the loss indicator clears itself', (tester) async {
    await pump(tester, 5, 10);
    await pump(tester, 4, 10);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('−1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('−1'), findsNothing,
        reason: 'it must not sit over the board for the rest of the session');
  });

  testWidgets('no exception is thrown when the board is disposed mid-loss',
      (tester) async {
    await pump(tester, 5, 10);
    await pump(tester, 4, 10);
    await tester.pump(const Duration(milliseconds: 100));

    // Tear the board down while the clear-timer is still pending.
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
  });
}
