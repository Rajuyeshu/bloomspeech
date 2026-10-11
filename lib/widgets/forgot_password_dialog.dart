import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_text_styles.dart';
import '../services/auth_service.dart';
import '../utils/app_localizations.dart';

/// Password-reset dialog for both the clinician and patient sign-in forms.
///
/// Sends a Supabase reset email. The confirmation is deliberately worded so it
/// does not reveal whether an account exists for the address — telling an
/// anonymous caller "no such user" would let someone enumerate the clinic's
/// registered emails.
class ForgotPasswordDialog extends ConsumerStatefulWidget {
  /// Pre-fills the field with whatever the user already typed on the form.
  final String initialEmail;
  final Color accent;

  const ForgotPasswordDialog({
    super.key,
    this.initialEmail = '',
    this.accent = AppColors.primary,
  });

  static Future<void> show(
    BuildContext context, {
    String initialEmail = '',
    Color accent = AppColors.primary,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ForgotPasswordDialog(
        initialEmail: initialEmail,
        accent: accent,
      ),
    );
  }

  @override
  ConsumerState<ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialEmail);
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .sendPasswordReset(_controller.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(_sent ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
              color: widget.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _sent ? 'Check your email'.tr() : 'Reset Password'.tr(),
              style: AppTextStyles.titleLarge,
            ),
          ),
        ],
      ),
      content: _sent ? _buildSent() : _buildForm(),
      actions: _sent
          ? [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.white,
                ),
                child: Text('Done'.tr()),
              ),
            ]
          : [
              TextButton(
                onPressed: _sending ? null : () => Navigator.pop(context),
                child: Text('Cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.white,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Send Reset Link'.tr()),
              ),
            ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your email and we will send you a link to set a new password.'
                .tr(),
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: 'your.email@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return 'Enter your email'.tr();
              if (!t.contains('@') || !t.contains('.')) {
                return 'Enter a valid email'.tr();
              }
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'If an account exists for that address, a reset link is on its way. '
                  'Check your inbox and spam folder.'
              .tr(),
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Text(
          _controller.text.trim(),
          style: AppTextStyles.titleSmall.copyWith(color: widget.accent),
        ),
      ],
    );
  }
}
