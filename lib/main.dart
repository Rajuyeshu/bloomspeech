import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_options.dart';
import 'app.dart';
import 'services/crash_log.dart';
import 'services/language_service.dart';
import 'services/session_gate.dart';

/// Entry point for BloomSpeech
/// 
/// Initializes Supabase backend and sets up the app with Riverpod state management.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Replace the default grey "red screen of death" with something readable, so
  // a widget-level failure degrades to a message instead of an unexplained
  // blank screen that looks like a crash.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('Widget error: ${details.exception}');
    return Material(
      color: const Color(0xFFFFF8E1),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFD32F2F)),
              const SizedBox(height: 12),
              const Text('Something went wrong on this screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('${details.exception}',
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  };

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
    CrashLog.record(details.exception, details.stack);
  };

  // Uncaught *asynchronous* errors never reached FlutterError.onError — a
  // failed future with no catch propagated to the platform, and on Android in
  // release that terminates the app. Handling it here keeps the app alive and
  // leaves a record that can actually be read afterwards.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught async error: $error\n$stack');
    CrashLog.record(error, stack);
    return true;
  };

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Local storage — holds the chosen interface language across restarts.
  try {
    await Hive.initFlutter();
    await Hive.openBox(LanguageService.boxName);
    await Hive.openBox(CrashLog.boxName);
  } catch (e) {
    debugPrint('Hive initialization warning: $e');
  }

  // Initialize Supabase backend.
  //
  // Sessions ARE persisted. Refusing to persist them (EmptyLocalStorage) also
  // met the "closing the app signs you out" requirement, but it broke Google
  // sign-in: OAuth runs in an external browser, Android is free to kill the
  // backgrounded app, and the redirect then starts it fresh with no session to
  // return to. See SessionGate.
  try {
    await Supabase.initialize(
      url: SupabaseOptions.url,
      anonKey: SupabaseOptions.anonKey,
    );

    // Closing the app signs you out — enforced here, on the next launch,
    // rather than by discarding the session as it is created. The exception is
    // a launch that is an OAuth redirect coming back, which is the tail end of
    // a sign-in already in progress, not a new run.
    final returningFromOAuth = await SessionGate.consumeOAuthPending();
    final restored = Supabase.instance.client.auth.currentUser;
    final isKidDevice = restored?.userMetadata?['role'] == 'kid' ||
        restored?.isAnonymous == true;

    if (!SessionGate.shouldKeepSession(
          oauthPending: returningFromOAuth,
          isKidDevice: isKidDevice,
        ) &&
        Supabase.instance.client.auth.currentSession != null) {
      debugPrint('Clearing restored session — fresh launch requires sign-in.');
      await Supabase.instance.client.auth.signOut();
    }
  } catch (e) {
    debugPrint('Supabase initialization warning: $e');
  }

  // runZonedGuarded catches what escapes everything else — an error thrown
  // from a callback with no zone of its own.
  runZonedGuarded(
    () => runApp(
      const ProviderScope(
        child: BloomSpeechApp(),
      ),
    ),
    (error, stack) {
      debugPrint('Uncaught zone error: $error\n$stack');
      CrashLog.record(error, stack);
    },
  );
}
