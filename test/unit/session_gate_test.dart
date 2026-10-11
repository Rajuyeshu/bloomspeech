import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:bloomspeech/services/session_gate.dart';

/// "Closing the app signs you out" and "Google sign-in works" pull in opposite
/// directions: OAuth runs in an external browser, so the app is backgrounded
/// for the whole exchange and Android may kill it. The redirect then starts
/// the app fresh — and a rule that clears the session on every fresh launch
/// would throw away the sign-in that had just succeeded.
void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('session_gate_test').path);
  });

  setUp(() async {
    if (!Hive.isBoxOpen(SessionGate.boxName)) {
      await Hive.openBox(SessionGate.boxName);
    }
    await Hive.box(SessionGate.boxName).clear();
  });

  group('the rule', () {
    test('a normal launch does not keep the session', () {
      expect(SessionGate.shouldKeepSession(oauthPending: false), isFalse);
    });

    test('an OAuth redirect keeps it', () {
      expect(SessionGate.shouldKeepSession(oauthPending: true), isTrue);
    });

    test('a child device keeps its identity across launches', () {
      // Clearing it would give the child a new anonymous id every launch and
      // detach them from their own therapy record each time.
      expect(
          SessionGate.shouldKeepSession(
              oauthPending: false, isKidDevice: true),
          isTrue);
    });

    test('a clinician device still signs out on a fresh launch', () {
      expect(
          SessionGate.shouldKeepSession(
              oauthPending: false, isKidDevice: false),
          isFalse);
    });
  });

  group('the pending flag', () {
    test('is absent until a sign-in starts', () async {
      expect(await SessionGate.consumeOAuthPending(), isFalse);
    });

    test('is set when the browser is about to open', () async {
      await SessionGate.markOAuthPending();
      expect(await SessionGate.consumeOAuthPending(), isTrue);
    });

    test('applies to exactly one launch', () async {
      await SessionGate.markOAuthPending();
      expect(await SessionGate.consumeOAuthPending(), isTrue);
      // A later launch is a normal one and must sign out again, or "closing
      // the app signs you out" would be permanently disabled by one sign-in.
      expect(await SessionGate.consumeOAuthPending(), isFalse);
    });

    test('expires, so an abandoned sign-in does not keep you logged in',
        () async {
      await SessionGate.markOAuthPending();
      final muchLater = DateTime.now()
          .toUtc()
          .add(SessionGate.pendingWindow + const Duration(minutes: 1));
      expect(await SessionGate.consumeOAuthPending(now: muchLater), isFalse);
    });

    test('is still valid just inside the window', () async {
      await SessionGate.markOAuthPending();
      final justInside = DateTime.now()
          .toUtc()
          .add(SessionGate.pendingWindow - const Duration(seconds: 30));
      expect(await SessionGate.consumeOAuthPending(now: justInside), isTrue);
    });

    test('survives a clock that moved backwards', () async {
      await SessionGate.markOAuthPending();
      final earlier =
          DateTime.now().toUtc().subtract(const Duration(hours: 2));
      // Discarding a probably-valid sign-in because the device clock changed
      // would be the worse failure.
      expect(await SessionGate.consumeOAuthPending(now: earlier), isTrue);
    });

    test('a corrupt value is treated as no sign-in in flight', () async {
      await Hive.box(SessionGate.boxName)
          .put('oauth_pending_since', 'not a timestamp');
      expect(await SessionGate.consumeOAuthPending(), isFalse);
    });
  });

  group('the whole journey', () {
    test('browser round trip keeps the session, next launch clears it',
        () async {
      // 1. User taps Continue with Google.
      await SessionGate.markOAuthPending();

      // 2. Android kills the backgrounded app; the redirect restarts it.
      final returning = await SessionGate.consumeOAuthPending();
      expect(SessionGate.shouldKeepSession(oauthPending: returning), isTrue,
          reason: 'the sign-in that just succeeded must not be discarded');

      // 3. User closes the app and opens it again later.
      final normalLaunch = await SessionGate.consumeOAuthPending();
      expect(SessionGate.shouldKeepSession(oauthPending: normalLaunch), isFalse,
          reason: 'closing the app must still require signing in again');
    });
  });
}
