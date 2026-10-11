import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Decides whether a saved session should survive an app launch.
///
/// The requirement is that closing the app signs you out. That was first
/// implemented by refusing to persist the session at all
/// (`EmptyLocalStorage`), which worked for email sign-in and quietly broke
/// Google sign-in:
///
///   Google authenticates in an EXTERNAL browser, so the app is backgrounded
///   for the whole exchange — and Android kills backgrounded processes freely.
///   When the browser redirects to `bloomspeech://login-callback` the app is
///   started fresh. With nothing persisted there is no session to come back
///   to, and the session created by the code exchange is not written anywhere
///   either, so the user lands on the login screen having just signed in.
///
/// Sessions are therefore persisted normally, and this gate clears them on the
/// next launch instead — except when that launch is the OAuth redirect coming
/// back, which is a continuation of the same sign-in rather than a new run.
class SessionGate {
  SessionGate._();

  /// Shares the settings box that is already open at startup.
  static const String boxName = 'app_settings';
  static const String _pendingKey = 'oauth_pending_since';

  /// How long an in-flight sign-in stays valid. Long enough to find a password
  /// and pass a 2FA prompt; short enough that an abandoned attempt does not
  /// leave the next launch signed in.
  static const Duration pendingWindow = Duration(minutes: 10);

  /// Call immediately before handing off to the browser.
  static Future<void> markOAuthPending() async {
    try {
      await Hive.box(boxName)
          .put(_pendingKey, DateTime.now().toUtc().toIso8601String());
    } catch (e) {
      debugPrint('SessionGate.markOAuthPending failed: $e');
    }
  }

  /// True if this launch is an OAuth redirect returning within the window.
  /// Consumes the flag, so it applies to exactly one launch.
  static Future<bool> consumeOAuthPending({DateTime? now}) async {
    try {
      final box = Hive.box(boxName);
      final raw = box.get(_pendingKey) as String?;
      await box.delete(_pendingKey);
      if (raw == null) return false;

      final started = DateTime.tryParse(raw);
      if (started == null) return false;

      final elapsed = (now ?? DateTime.now().toUtc()).difference(started);
      // A negative elapsed time means the clock moved backwards; treat it as
      // in-flight rather than discarding a sign-in that is probably valid.
      return elapsed <= pendingWindow;
    } catch (e) {
      debugPrint('SessionGate.consumeOAuthPending failed: $e');
      return false;
    }
  }

  /// Whether a restored session should be kept for this launch.
  ///
  /// Pure so the rule can be tested without Hive or a clock.
  ///
  /// [isKidDevice] keeps a child's identity across launches. The sign-out rule
  /// exists for a clinician's tablet that moves between children; a child's own
  /// device is the opposite case, and clearing it would hand them a new
  /// anonymous id every launch — which would detach them from their own
  /// therapy record each time the app was closed.
  static bool shouldKeepSession({
    required bool oauthPending,
    bool isKidDevice = false,
  }) =>
      oauthPending || isKidDevice;
}
