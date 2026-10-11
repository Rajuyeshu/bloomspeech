import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bloomspeech/app.dart';
import 'package:bloomspeech/services/language_service.dart';

/// Smoke test: the app boots to a router and a MaterialApp without throwing.
///
/// This used to pump [BloomSpeechApp] with neither Hive nor Supabase set up,
/// so it always failed on `Supabase.instance` — it was reporting a broken test
/// harness, not a broken app. Both dependencies are now stood up the way
/// main() does, minus the platform plugins a unit test cannot provide.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Hive without path_provider — a temp directory is enough for the one
    // settings box the app reads at startup.
    Hive.init(Directory.systemTemp.createTempSync('bloomspeech_test').path);
    await Hive.openBox(LanguageService.boxName);

    // No persistence and no deep-link observer: both need platform channels,
    // and neither is what this test is checking.
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
      debug: false,
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        // Supabase reaches for SharedPreferences to hold the PKCE verifier
        // whatever the session storage is, and that plugin has no
        // implementation in a unit test.
        pkceAsyncStorage: _MemoryStorage(),
        detectSessionInUri: false,
        // gotrue keeps a refresh ticker running; a unit test has no event loop
        // left to drain it once the tree is torn down.
        autoRefreshToken: false,
      ),
    );
  });

  testWidgets('BloomSpeech app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BloomSpeechApp()),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The splash holds for three seconds before routing on. Let that elapse,
    // otherwise the pending timer outlives the widget tree and the test
    // framework fails the test for it.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(tester.takeException(), isNull);
  });
}

/// In-memory stand-in for the PKCE store, so the test needs no platform channels.
class _MemoryStorage extends GotrueAsyncStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }
}
