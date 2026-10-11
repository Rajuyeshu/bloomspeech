import 'package:flutter_test/flutter_test.dart';
import 'package:bloomspeech/utils/auth_error.dart';

/// Auth failures used to reach the user as raw exception text — an
/// `AuthApiException(...)` dump reads as a fault in the app rather than as
/// "you already have an account, sign in instead", so people retried the same
/// form instead of taking the step that would have worked.
void main() {
  group('an email that is already registered', () {
    test('is explained, and points at signing in', () {
      final e = AuthError.from(
          'AuthApiException(message: User already registered, statusCode: 422, '
          'code: user_already_exists)');

      expect(e.message, contains('already exists'));
      expect(e.message, contains('Sign in'));
      expect(e.action, AuthErrorAction.signIn);

      // The raw exception must not reach the user.
      expect(e.message, isNot(contains('AuthApiException')));
      expect(e.message, isNot(contains('422')));
    });

    test('is recognised however the backend words it', () {
      for (final raw in [
        'User already registered',
        'AuthApiException(code: user_already_exists)',
        'A user with this email address has already been registered',
      ]) {
        expect(AuthError.from(raw).action, AuthErrorAction.signIn,
            reason: raw);
      }
    });
  });

  group('sign-in failures', () {
    test('bad credentials suggest a password reset', () {
      final e = AuthError.from(
          'AuthApiException(message: Invalid login credentials, statusCode: 400)');
      expect(e.message, contains('do not match'));
      expect(e.action, AuthErrorAction.resetPassword);
    });

    test('an unconfirmed email says so explicitly', () {
      final e = AuthError.from('AuthApiException(message: Email not confirmed)');
      expect(e.message.toLowerCase(), contains('confirm'));
    });

    test('an unknown email offers registration', () {
      final e = AuthError.from('AuthApiException(message: User not found)');
      expect(e.action, AuthErrorAction.register);
    });
  });

  group('failures that are not the user\'s fault', () {
    test('a dropped connection is named as such', () {
      final e = AuthError.from(
          "ClientException with SocketException: Failed host lookup: "
          "'wleogtlhqqwsqoweqhxh.supabase.co'");
      expect(e.message, contains('internet connection'));
      // Not a login problem — offering a password reset would mislead.
      expect(e.action, AuthErrorAction.none);
    });

    test('an email rate limit names the real cause, not "wait a minute"', () {
      // Waiting does not help: the built-in mailer allows a couple of messages
      // an hour, so the fix is configuration, not patience.
      final e = AuthError.from(
          'AuthApiException(message: email rate limit exceeded, '
          'code: over_email_send_rate_limit)');
      expect(e.message, contains('email service'));
      expect(e.message.toLowerCase(), contains('smtp'));
    });

    test('a generic rate limit still tells the user to wait', () {
      final e = AuthError.from(
          'AuthApiException(message: Too many requests, statusCode: 429)');
      expect(e.message.toLowerCase(), contains('wait'));
    });
  });

  group('anything unrecognised', () {
    test('keeps the underlying sentence rather than hiding it', () {
      final e = AuthError.from(
          'AuthApiException(message: Database error saving new user, '
          'statusCode: 500)');
      // The user can quote this; a generic apology would strip what matters.
      expect(e.message, contains('Database error saving new user'));
      expect(e.message, isNot(contains('statusCode')));
    });

    test('is never blank, whatever it was handed', () {
      for (final raw in ['', 'null', 'Exception:', '{}']) {
        expect(AuthError.from(raw).message.trim(), isNotEmpty, reason: raw);
      }
    });

    test('never throws', () {
      expect(() => AuthError.from(Object()), returnsNormally);
      expect(() => AuthError.from(StateError('x')), returnsNormally);
    });
  });

  group('registration that needs confirming', () {
    test('an obfuscated duplicate is still reported as a duplicate', () {
      // With email confirmation on, Supabase returns a user with no identities
      // rather than an error, so an existing address looks like success. The
      // service turns that back into a real error before it reaches here.
      final e = AuthError.from('AuthException(message: User already registered)');
      expect(e.action, AuthErrorAction.signIn);
    });
  });

  test('a weak password is reported as a length problem', () {
    final e = AuthError.from(
        'AuthApiException(message: Password should be at least 6 characters)');
    expect(e.message, contains('6 characters'));
  });
}
