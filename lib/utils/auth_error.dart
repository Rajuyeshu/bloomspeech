/// Turns a Supabase auth failure into something a clinician can act on.
///
/// The screens used to render `e.toString()` directly, which produced text
/// like `AuthApiException(message: User already registered, statusCode: 422,
/// code: user_already_exists)`. That reads as a fault in the app rather than
/// as "you already have an account — sign in instead", so people retried the
/// same form instead of taking the one step that would have worked.
class AuthError {
  /// The sentence to show.
  final String message;

  /// What the user should do next, when there is a clear next step.
  final AuthErrorAction action;

  const AuthError(this.message, [this.action = AuthErrorAction.none]);

  /// Map any thrown auth object to a message. Never throws, and never returns
  /// an empty string — a blank error box is worse than a vague one.
  factory AuthError.from(Object error) {
    final raw = error.toString();
    final text = raw.toLowerCase();

    // ── Registration ────────────────────────────────────────────────────
    if (text.contains('already registered') ||
        text.contains('user_already_exists') ||
        text.contains('already been registered') ||
        text.contains('duplicate key') && text.contains('email')) {
      return const AuthError(
        'An account already exists for this email. Sign in instead, or reset '
        'your password if you have forgotten it.',
        AuthErrorAction.signIn,
      );
    }

    if (text.contains('password should be at least') ||
        text.contains('weak_password')) {
      return const AuthError(
        'That password is too short. Use at least 6 characters.',
      );
    }

    // ── Sign-in ─────────────────────────────────────────────────────────
    if (text.contains('invalid login credentials') ||
        text.contains('invalid_credentials')) {
      return const AuthError(
        'That email and password do not match an account. Check the spelling, '
        'or reset your password.',
        AuthErrorAction.resetPassword,
      );
    }

    if (text.contains('email not confirmed') ||
        text.contains('email_not_confirmed')) {
      return const AuthError(
        'This account has not been confirmed yet. Open the confirmation link '
        'in your email, then sign in.',
      );
    }

    if (text.contains('user not found') || text.contains('user_not_found')) {
      return const AuthError(
        'No account exists for this email. Create one to get started.',
        AuthErrorAction.register,
      );
    }

    // ── Rate limiting and network ───────────────────────────────────────
    // Supabase's built-in mailer allows only a couple of messages per hour, so
    // with "Confirm email" enabled and no custom SMTP this fires after two or
    // three sign-ups and looks like the app rejecting the user. Naming the
    // cause matters: the previous wording sent people off to wait, when
    // waiting does not help.
    if (text.contains('over_email_send_rate_limit') ||
        text.contains('email rate limit')) {
      return const AuthError(
        'The email service has hit its limit. This project sends confirmation '
        'emails through Supabase\'s built-in mailer, which allows only a few '
        'per hour. Turn off email confirmation, or set up custom SMTP.',
      );
    }

    if (text.contains('rate limit') || text.contains('too many requests')) {
      return const AuthError(
        'Too many attempts. Wait a minute and try again.',
      );
    }

    if (text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('connection closed') ||
        text.contains('clientexception')) {
      return const AuthError(
        'Could not reach the server. Check your internet connection and try '
        'again.',
      );
    }

    // ── Anything else ───────────────────────────────────────────────────
    // Keep the underlying text: an unrecognised failure the user can quote is
    // more useful to them than a generic apology that hides it.
    final detail = _tidy(raw);
    return AuthError(
      detail.isEmpty ? 'Something went wrong. Please try again.' : detail,
    );
  }

  /// Strip the exception wrapper so the sentence inside is readable.
  static String _tidy(String raw) {
    final match =
        RegExp(r'message:\s*([^,)]+)', caseSensitive: false).firstMatch(raw);
    var out = (match?.group(1) ?? raw).trim();
    for (final prefix in ['Exception:', 'AuthException:', 'AuthApiException:']) {
      if (out.startsWith(prefix)) out = out.substring(prefix.length).trim();
    }
    return out;
  }
}

/// The next step a failure points to, so the screen can offer it as a button
/// rather than leaving the user to work it out.
enum AuthErrorAction { none, signIn, register, resetPassword }
