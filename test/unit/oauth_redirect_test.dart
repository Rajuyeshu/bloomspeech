import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/config/constants/app_constants.dart';

/// Google sign-in happens in an external browser, and the result comes back
/// over a deep link. That link only reaches the app if the same scheme is
/// registered in the Android manifest, the iOS plist, and the Supabase
/// redirect allowlist. Miss one and sign-in fails silently — the user
/// authenticates successfully and the app simply never hears about it, which
/// is indistinguishable from the button doing nothing.
void main() {
  group('the redirect URL', () {
    test('is a well-formed custom-scheme URL', () {
      final uri = Uri.parse(AppConstants.oauthRedirectUrl);
      expect(uri.scheme, AppConstants.oauthRedirectScheme);
      expect(uri.host, isNotEmpty);
      expect(uri.scheme, isNot('http'));
      expect(uri.scheme, isNot('https'));
    });

    test('uses a scheme Android will accept', () {
      final scheme = AppConstants.oauthRedirectScheme;
      // Lowercase letters only: Android lowercases schemes when matching, so a
      // capital in the manifest silently never matches.
      expect(scheme, matches(RegExp(r'^[a-z][a-z0-9.+-]*$')),
          reason: 'scheme must be lowercase and start with a letter');
    });
  });

  group('registration is consistent across platforms', () {
    final uri = Uri.parse(AppConstants.oauthRedirectUrl);

    test('the Android manifest declares the same scheme and host', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

      expect(manifest, contains('android.intent.action.VIEW'),
          reason: 'no VIEW intent-filter — the callback cannot be delivered');
      expect(manifest, contains('android.intent.category.BROWSABLE'),
          reason: 'without BROWSABLE the browser will not hand off the link');
      expect(manifest, contains('android:scheme="${uri.scheme}"'));
      expect(manifest, contains('android:host="${uri.host}"'));
    });

    test('the iOS plist declares the same scheme', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, contains('CFBundleURLSchemes'));
      expect(plist, contains('<string>${uri.scheme}</string>'));
    });

    test('the launcher intent-filter is still intact', () {
      // Adding the callback filter must not disturb the one that puts the app
      // in the launcher.
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android.intent.action.MAIN'));
      expect(manifest, contains('android.intent.category.LAUNCHER'));
    });
  });

  group('email links come back to the app', () {
    test('sign-up confirmation and password reset both set a redirect', () {
      final source = File('lib/services/auth_service.dart').readAsStringSync();

      // Without these, Supabase falls back to the project's Site URL — which
      // defaults to http://localhost:3000, so tapping "confirm" on a phone
      // opens a browser that cannot reach anything and the user is stranded.
      expect(source, contains('emailRedirectTo:'),
          reason: 'sign-up confirmation would dead-end at localhost');
      expect(source, contains('resetPasswordForEmail('));
      expect(source, contains('redirectTo:'),
          reason: 'password reset would dead-end at localhost');
    });

    test('they use the same deep link the manifest registers', () {
      final source = File('lib/services/auth_service.dart').readAsStringSync();
      expect(source, contains('AppConstants.oauthRedirectUrl'));
    });
  });

  test('the app id and code namespace are both correct', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    // `in` is a reserved word, so the Play id and the code package differ on
    // purpose. Both must stay as they are: applicationId is permanent once
    // published, and namespace is what the Kotlin package must match.
    expect(gradle, contains('applicationId = "in.bloomspeech.app"'));
    expect(gradle, contains('namespace = "app.bloomspeech"'));

    final activity = File(
      'android/app/src/main/kotlin/app/bloomspeech/MainActivity.kt',
    ).readAsStringSync();
    expect(activity, contains('package app.bloomspeech'));
  });
}
