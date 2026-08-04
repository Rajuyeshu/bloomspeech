import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    String role = 'clinician',
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
        'role': role,
      },
    );
    final u = response.user;
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
      return AppUser(
        uid: u.id,
        email: u.email,
        displayName: displayName,
        role: role,
      );
    }
    throw 'Registration error';
  }

  /// Sign in with Google (Supabase OAuth)
  Future<dynamic> signInWithGoogle() async {
    try {
      final redirectTo = kIsWeb ? Uri.base.origin : null;
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );
      return true;
    } catch (e) {
      return null;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
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
