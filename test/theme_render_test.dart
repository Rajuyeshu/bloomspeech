import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/config/constants/app_constants.dart';
import 'package:bloomspeech/widgets/theme_token_board.dart';

/// Renders the ring themes to PNG so the layout can be eyeballed, not just
/// asserted. Emoji glyphs do not rasterise in a unit test, but position,
/// size and spacing — which is what was broken — do.
void main() {
  // Diagnostic only: set RENDER_OUT to a directory to dump the PNGs. Skipped
  // in a normal `flutter test` run so it cannot fail the suite.
  final outDir = Platform.environment['RENDER_OUT'];
  if (outDir == null) return;

  for (final theme in PlayTheme.selectable) {
    for (final goal in [10, 20]) {
      testWidgets('render ${theme.name} $goal', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final key = GlobalKey();
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF101018),
            body: Column(children: [
              RepaintBoundary(
                key: key,
                child: SizedBox(
                  height: 230,
                  child: ThemeTokenBoardWidget(
                    theme: theme, currentTokens: (goal * 0.6).round(), tokenGoal: goal),
                ),
              ),
              const Expanded(child: SizedBox()),
            ]),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 400));

        final boundary = key.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        // toImage needs the real event loop, not the fake-async test one.
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 3.0);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$outDir/${theme.name}_$goal.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
