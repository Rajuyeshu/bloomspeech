import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/config/constants/app_constants.dart';
import 'package:bloomspeech/widgets/theme_token_board.dart';

/// The token board must keep every token inside its container at any goal.
/// A 30-token goal used to push glyphs outside the board and over the stats
/// row below it, so this pins the behaviour for every theme and screen size.
void main() {
  Future<void> pumpBoard(
    WidgetTester tester, {
    required PlayTheme theme,
    required int goal,
    required int current,
    required Size screen,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            SizedBox(
              height: screen.height < 750 ? 180 : 240,
              child: ThemeTokenBoardWidget(
                theme: theme,
                currentTokens: current,
                tokenGoal: goal,
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final screen in [const Size(360, 640), const Size(412, 915)]) {
    for (final theme in PlayTheme.values) {
      for (final goal in [5, 10, 18, 24, 30]) {
        testWidgets('${theme.name} fits $goal tokens at ${screen.width.toInt()}x${screen.height.toInt()}',
            (tester) async {
          await pumpBoard(tester,
              theme: theme,
              goal: goal,
              current: (goal * 0.8).round(),
              screen: screen);

          // Any RenderFlex/RenderBox overflow is reported as a FlutterError.
          expect(tester.takeException(), isNull,
              reason: '${theme.name} overflowed with $goal tokens');
        });
      }
    }
  }

  // ── Ring themes: every token must be visible and distinct ────────────────
  //
  // Diya, Rangoli and Peacock lay their tokens out on rings rather than a
  // grid, and all three were broken in the same two ways: the innermost ring
  // was drawn underneath the centre badge, and the peacock crammed a full
  // ring's worth of feathers into a half-circle. In both cases the board
  // claimed more tokens than the child could actually see. These tests assert
  // the layout directly instead of only checking for overflow.
  // Ring themes plus every container theme. The container themes pack tokens
  // into a painted vessel, so a token drawn outside its interior is the same
  // class of defect as one drawn outside a ring: the child cannot count it.
  final ringThemes = <PlayTheme>[
    PlayTheme.diyaFestival,
    PlayTheme.rangoliBuilder,
    PlayTheme.peacockGarden,
    ...PlayTheme.values.where((t) => t.container != TokenContainer.none),
  ];

  for (final screen in [const Size(360, 640), const Size(412, 915)]) {
    for (final theme in ringThemes) {
      for (final goal in [5, 10, 18, 24, 30]) {
        final label =
            '${theme.name} shows $goal distinct tokens at ${screen.width.toInt()}x${screen.height.toInt()}';

        testWidgets(label, (tester) async {
          await pumpBoard(tester,
              theme: theme, goal: goal, current: goal, screen: screen);
          expect(tester.takeException(), isNull);

          // The board itself, so we can prove the tokens land inside it.
          final board = tester.getRect(find.byType(ThemeTokenBoardWidget));

          final rects = <Rect>[];
          for (var i = 0; i < goal; i++) {
            final finder = find.byKey(ValueKey('token-$i'));
            expect(finder, findsOneWidget,
                reason: '${theme.name}: token $i was never laid out');
            final r = tester.getRect(finder);

            // Being laid out is not the same as being visible. These themes
            // positioned their tokens against the full canvas width while the
            // Stack had shrink-wrapped to its centrepiece, so the tokens were
            // painted off the side of the board and clipped away entirely.
            expect(board.contains(r.topLeft) && board.contains(r.bottomRight),
                isTrue,
                reason: '${theme.name} at goal $goal: token $i at $r '
                    'falls outside the board $board');
            rects.add(r);
          }

          // No token may be mostly buried under another one. A little overlap
          // between neighbouring glyphs is fine and looks intentional; more
          // than a third of a token's area means it cannot be counted.
          for (var i = 0; i < rects.length; i++) {
            for (var j = i + 1; j < rects.length; j++) {
              final overlap = rects[i].intersect(rects[j]);
              if (overlap.isEmpty || overlap.width <= 0 || overlap.height <= 0) {
                continue;
              }
              final area = overlap.width * overlap.height;
              final own = rects[i].width * rects[i].height;
              expect(area / own, lessThan(0.34),
                  reason: '${theme.name} at goal $goal: tokens $i and $j '
                      'overlap by ${(area / own * 100).round()}%');
            }
          }
        });
      }
    }
  }
}
