import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bloomspeech/app.dart';

void main() {
  testWidgets('BloomSpeech app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: BloomSpeechApp(),
      ),
    );

    // Verify splash screen shows
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
