import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants/app_constants.dart';
import 'session_gate.dart';

/// AppUser wrapper for clean app-wide user handling
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String role; // 'clinician' or 'kid'

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    required this.role,
  });

  AppUser? get user => this;
}

/// Outcome of a sign-up attempt.
///
/// Registration has two distinct successful endings and they need different
/// handling: the user is signed in and can continue, or the account exists but
/// is waiting on an email confirmation and cannot sign in yet.
class RegistrationResult {
  final AppUser user;
  final bool needsEmailConfirmation;

  const RegistrationResult({
    required this.user,
    required this.needsEmailConfirmation,
  });
}

/// Authentication service powered 100% by Supabase
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Current user
  AppUser? get currentUser {
    final sUser = _supabase.auth.currentUser;
    if (sUser != null) {
      final email = sUser.email;
      final role = sUser.userMetadata?['role'] as String? ??
          (email != null && email.endsWith('@patient.bloomspeech.app')
              ? 'kid'
              : 'clinician');
      return AppUser(
        uid: sUser.id,
        email: sUser.email,
        displayName: sUser.userMetadata?['display_name'] as String? ?? sUser.email?.split('@').first,
        role: role,
      );
    }
    return null;
  }

  /// Auth state changes stream
  Stream<AppUser?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      final sUser = data.session?.user;
      if (sUser != null) {
        final email = sUser.email;
        final role = sUser.userMetadata?['role'] as String? ??
            (email != null && email.endsWith('@patient.bloomspeech.app')
                ? 'kid'
                : 'clinician');
        return AppUser(
          uid: sUser.id,
          email: sUser.email,
          displayName: sUser.userMetadata?['display_name'] as String? ?? sUser.email?.split('@').first,
          role: role,
        );
      }
      return null;
    });
  }

  /// Sign in with email and password (Supabase)
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final u = response.user;
    if (u == null) throw 'Login failed: user not found';
    final role = u.userMetadata?['role'] as String? ??
        (email.endsWith('@patient.bloomspeech.app') ? 'kid' : 'clinician');
    return AppUser(
      uid: u.id,
      email: u.email,
      displayName: u.userMetadata?['display_name'] as String? ?? u.email?.split('@').first,
      role: role,
    );
  }

  /// Register with email and password (Supabase)
  Future<RegistrationResult> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    String role = 'clinician',
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      // Where the confirmation link lands. Without this Supabase falls back to
      // the project's Site URL, which defaults to http://localhost:3000 — so
      // tapping "confirm" on a phone opened a browser that reported
      // "localhost is unreachable" and the user was stranded, with no way to
      // tell whether the account had been confirmed or not.
      //
      // Pointing it at the app's own deep link means confirming returns to
      // BloomSpeech and signs the user straight in. The URL must be on the
      // Redirect URLs allowlist in the Supabase dashboard.
      emailRedirectTo: kIsWeb ? null : AppConstants.oauthRedirectUrl,
      data: {
        'display_name': displayName,
        'role': role,
      },
    );
    final u = response.user;

    // When email confirmation is enabled, Supabase does NOT report an existing
    // address as an error — it returns a user with an empty `identities` list
    // instead, deliberately, so an attacker cannot probe which addresses are
    // registered. Taken at face value that looks like a successful sign-up,
    // and the app happily sent the user on to a home screen they had no
    // session for.
    if (u != null && (u.identities?.isEmpty ?? false)) {
      throw AuthException('User already registered');
    }

    if (u != null) {
      // Upsert to Supabase profiles table
      try {
        await _supabase.from('profiles').upsert({
          'id': u.id,
          'name': displayName,
          'email': email,
          'role': role,
        });
      } catch (dbErr) {
        debugPrint('Profiles table sync info: $dbErr');
      }
      return RegistrationResult(
        user: AppUser(
          uid: u.id,
          email: u.email,
          displayName: displayName,
          role: role,
        ),
        // No session means the project requires the address to be confirmed
        // before it can be used. The account exists but cannot sign in yet, so
        // sending the user to the home screen just bounces them back to login
        // with nothing explaining why.
        needsEmailConfirmation: response.session == null,
      );
    }
    throw 'Registration error';
  }

  /// Begin Google sign-in.
  ///
  /// Returns once the browser has been opened — NOT once the user is signed
  /// in. OAuth completes out of process: Google redirects to
  /// [AppConstants.oauthRedirectUrl], Android hands that deep link back to the
  /// app, and the session arrives on [authStateChanges] some seconds later.
  /// Callers must wait for that rather than assuming success here.
  ///
  /// Two things were wrong before. `redirectTo` was null on mobile, so
  /// Supabase fell back to the project's Site URL and the browser landed on a
  /// web page instead of returning to the app. And every failure was caught
  /// and turned into `null`, so a caller could not tell a launched browser
  /// from a total failure.
  ///
  /// Returns true if the browser opened. Throws if it could not be opened.
  Future<bool> signInWithGoogle() async {
    // Survive the round trip. The app is backgrounded for the whole browser
    // exchange and may be killed; this tells the next launch that the session
    // it finds is the result of this sign-in, not a leftover to be cleared.
    await SessionGate.markOAuthPending();

    return _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      // On the web the redirect is back to the page that started it. On mobile
      // it is the custom scheme registered in AndroidManifest.xml and
      // Info.plist, which must also be allowlisted in the Supabase dashboard
      // under Authentication › URL Configuration › Redirect URLs.
      redirectTo: kIsWeb ? Uri.base.origin : AppConstants.oauthRedirectUrl,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  /// Send password reset email.
  ///
  /// Same redirect problem as sign-up confirmation: without an explicit target
  /// the link goes to the project's Site URL (localhost by default) and dead
  /// ends in the browser.
  Future<void> sendPasswordReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : AppConstants.oauthRedirectUrl,
    );
  }

  /// Give an unauthenticated child device an identity.
  ///
  /// A child joins by typing a six-character code and is otherwise anonymous,
  /// so there was no `auth.uid()` to record on the session row and nothing for
  /// the clinician to link. Their progress screens could therefore never show
  /// anything, however many sessions were completed.
  ///
  /// Anonymous sign-in gives a stable id without asking a three-year-old's
  /// family to create an account. Requires "Anonymous sign-ins" to be enabled
  /// in the Supabase dashboard; throws if it is not, so the caller can say so
  /// rather than failing silently.
  Future<AppUser?> signInAnonymouslyForKid() async {
    final existing = currentUser;
    if (existing != null) return existing;

    final response = await _supabase.auth.signInAnonymously(
      data: {'role': 'kid', 'display_name': 'Patient device'},
    );
    final u = response.user;
    if (u == null) return null;
    return AppUser(
      uid: u.id,
      email: u.email,
      displayName: 'Patient device',
      role: 'kid',
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

/// Riverpod providers for auth
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).value ?? ref.watch(authServiceProvider).currentUser;
});
