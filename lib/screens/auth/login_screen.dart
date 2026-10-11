import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/routes/app_router.dart';
import '../../config/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/forgot_password_dialog.dart';
import '../../services/language_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_localizations.dart';
import '../../utils/auth_error.dart';

/// Landing screen — choose Clinician or Kid/Patient login
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  Widget _buildLangBtn(AppLanguage lang, String label) {
    final currentLang = ref.watch(appLanguageProvider);
    final isSelected = currentLang == lang;
    return GestureDetector(
      onTap: () => ref.read(appLanguageProvider.notifier).setLanguage(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, Color(0xFFF3E5F5), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ─── Language Switcher ───
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.textHint.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLangBtn(AppLanguage.english, 'ENG'),
                        const SizedBox(width: 4),
                        _buildLangBtn(AppLanguage.kannada, 'ಕನ್ನಡ'),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // ─── Logo & Branding ───
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                    .animate()
                    .scale(duration: 700.ms, curve: Curves.elasticOut)
                    .then()
                    .shimmer(
                      duration: 1800.ms,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),

                const SizedBox(height: 24),

                Text(
                  'BloomSpeech',
                  style: AppTextStyles.displaySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

                const SizedBox(height: 6),

                Text(
                  'tagline'.tr(language),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                const SizedBox(height: 48),

                // ─── I am a… label ───
                Text(
                  'i_am_a'.tr(language),
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 20),

                // ─── Clinician Card ───
                _buildRoleCard(
                  title: 'clinician_title'.tr(language),
                  subtitle: 'clinician_subtitle'.tr(language),
                  icon: Icons.medical_services_rounded,
                  emoji: '👩‍⚕️',
                  gradient: AppColors.primaryGradient,
                  shadowColor: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _ClinicianAuthScreen(),
                    ),
                  ),
                  delay: 700,
                ),

                const SizedBox(height: 16),

                // ─── Patient / Kid Card ───
                _buildRoleCard(
                  title: 'patient_title'.tr(language),
                  subtitle: 'patient_subtitle'.tr(language),
                  icon: Icons.child_care_rounded,
                  emoji: '🧒',
                  gradient: AppColors.warmGradient,
                  shadowColor: AppColors.accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _PatientAuthScreen(),
                    ),
                  ),
                  delay: 850,
                ),

                // The decorative festival icons that sat here were the
                // retired token imagery, and gave the landing screen a
                // different visual vocabulary from the rest of the app.
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String emoji,
    required LinearGradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji circle
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 600.ms)
        .slideY(begin: 0.15, end: 0);
  }

}

// ═══════════════════════════════════════════════════════════
// CLINICIAN AUTH SCREEN — Login / Register tabs
// ═══════════════════════════════════════════════════════════
class _ClinicianAuthScreen extends ConsumerStatefulWidget {
  const _ClinicianAuthScreen();

  @override
  ConsumerState<_ClinicianAuthScreen> createState() =>
      _ClinicianAuthScreenState();
}

class _ClinicianAuthScreenState extends ConsumerState<_ClinicianAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login fields
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscure = true;
  bool _loginLoading = false;
  String? _loginError;

  // Register fields
  final _registerFormKey = GlobalKey<FormState>();
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmController = TextEditingController();
  bool _regObscure = true;
  bool _regConfirmObscure = true;
  bool _regLoading = false;
  String? _regError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _regConfirmController.dispose();
    super.dispose();
  }

  Future<void> _handleClinicianLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _loginLoading = true;
      _loginError = null;
    });

    try {
      await ref.read(authServiceProvider).signInWithEmail(
            email: _loginEmailController.text.trim(),
            password: _loginPasswordController.text,
          );
      if (mounted) context.goNamed(AppRouter.home);
    } catch (e) {
      if (mounted) {
        setState(() => _loginError = _friendlyError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _loginLoading = true;
      _loginError = null;
    });

    try {
      // Opens the browser and returns immediately. The session does not exist
      // yet — it arrives over the deep link once Google redirects back, and
      // the router sends the user to home when it does.
      //
      // This used to navigate to home on the very next line, before any
      // session existed. The router found no user and bounced straight back
      // here, which is exactly what "Google sign-in doesn't work" looked like:
      // a flicker, and no error to explain it.
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() => _loginError = _friendlyError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _handleClinicianRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() {
      _regLoading = true;
      _regError = null;
    });

    try {
      final result = await ref.read(authServiceProvider).registerWithEmail(
            email: _regEmailController.text.trim(),
            password: _regPasswordController.text,
            displayName: _regNameController.text.trim(),
          );
      if (!mounted) return;
      if (result.needsEmailConfirmation) {
        // Account created but not usable yet — going to home would just bounce
        // back here with no explanation.
        setState(() => _regError =
            'Account created. Open the confirmation link in your email — it '
            'will bring you back here and sign you in.');
        return;
      }
      context.goNamed(AppRouter.home);
    } catch (e) {
      if (mounted) {
        setState(() => _regError = _friendlyError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _regLoading = false);
    }
  }

  /// Delegates to the shared mapping in [AuthError].
  ///
  /// This existed twice in this file, in two classes, with wording that had
  /// already drifted apart — and neither copy covered an unconfirmed email, a
  /// rate limit, or a dropped connection, so those all fell through to raw
  /// exception text.
  String _friendlyError(String error) => AuthError.from(error).message;

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👩‍⚕️ '),
            Text('clinician_title'.tr(language).split(' /').first),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: 'login'.tr(language)),
            Tab(text: 'register'.tr(language)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoginTab(),
          _buildRegisterTab(),
        ],
      ),
    );
  }

  // ─── Login Tab ───
  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.login_rounded,
                    size: 32, color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text('Welcome Back'.tr(),
                  style: AppTextStyles.headlineMedium),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Sign in to your clinician account'.tr(),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 32),

            // Email (Username)
            Text('Email Address (Username)'.tr(), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _loginEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _inputDecor('your.email@example.com', Icons.email_outlined),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter your email address' : null,
            ),

            const SizedBox(height: 18),

            // Password
            Text('Password'.tr(), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _loginPasswordController,
              obscureText: _loginObscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleClinicianLogin(),
              decoration: _inputDecor('Enter password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_loginObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _loginObscure = !_loginObscure),
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter your password' : null,
            ),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => ForgotPasswordDialog.show(
                  context,
                  initialEmail: _loginEmailController.text.trim(),
                  accent: AppColors.primary,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot Password?'.tr(),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Error
            if (_loginError != null) ...[
              const SizedBox(height: 14),
              _buildErrorBanner(_loginError!),
            ],

            const SizedBox(height: 28),

            // Login button
            _buildPrimaryButton(
              label: 'Login'.tr(),
              isLoading: _loginLoading,
              onPressed: _handleClinicianLogin,
            ),

            const SizedBox(height: 20),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider(thickness: 1, color: Color(0xFFE2E8F0))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'OR'.tr(),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(child: Divider(thickness: 1, color: Color(0xFFE2E8F0))),
              ],
            ),

            const SizedBox(height: 20),

            // Google Login Button
            _buildGoogleButton(
              label: 'Continue with Google'.tr(),
              onPressed: _handleGoogleLogin,
            ),

            const SizedBox(height: 24),

            // Switch to register
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: Text('Register'.tr(),
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Register Tab ───
  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: AppColors.warmGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_add_rounded,
                    size: 32, color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text('Create Account'.tr(),
                  style: AppTextStyles.headlineMedium),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Register as a new clinician'.tr(),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 28),

            // Full Name
            Text('Full Name'.tr(), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _inputDecor('Dr. / SLP Name', Icons.person_outline),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter your name' : null,
            ),

            const SizedBox(height: 16),

            // Email (Username)
            Text('Email Address (Username)'.tr(), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _inputDecor('your.email@example.com', Icons.email_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email address';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Password
            Text('Password'.tr(), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regPasswordController,
              obscureText: _regObscure,
              textInputAction: TextInputAction.next,
              decoration: _inputDecor('Min 6 characters', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_regObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _regObscure = !_regObscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a password';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Confirm Password
            Text('Confirm Password'.tr(), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regConfirmController,
              obscureText: _regConfirmObscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleClinicianRegister(),
              decoration: _inputDecor('Re-enter password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_regConfirmObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _regConfirmObscure = !_regConfirmObscure),
                ),
              ),
              validator: (v) {
                if (v != _regPasswordController.text) return 'Passwords don\'t match';
                return null;
              },
            ),

            // Error
            if (_regError != null) ...[
              const SizedBox(height: 14),
              _buildErrorBanner(_regError!),
            ],

            const SizedBox(height: 28),

            // Register button
            _buildPrimaryButton(
              label: 'Create Account'.tr(),
              isLoading: _regLoading,
              onPressed: _handleClinicianRegister,
            ),

            const SizedBox(height: 16),

            // Switch to login
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? '.tr(),
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: Text('Login'.tr(),
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Shared UI helpers ───
  InputDecoration _inputDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label, style: AppTextStyles.buttonText),
      ),
    );
  }

  Widget _buildGoogleButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: const Icon(
                Icons.g_mobiledata_rounded,
                color: Color(0xFF4285F4),
                size: 32,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PATIENT / KID AUTH SCREEN — Login / Register / Join Session tabs
// ═══════════════════════════════════════════════════════════
class _PatientAuthScreen extends ConsumerStatefulWidget {
  const _PatientAuthScreen();

  @override
  ConsumerState<_PatientAuthScreen> createState() =>
      _PatientAuthScreenState();
}

class _PatientAuthScreenState extends ConsumerState<_PatientAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login fields
  final _loginFormKey = GlobalKey<FormState>();
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscure = true;
  bool _loginLoading = false;
  String? _loginError;

  // Register fields
  final _registerFormKey = GlobalKey<FormState>();
  final _regChildNameController = TextEditingController();
  final _regParentNameController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmController = TextEditingController();
  bool _regObscure = true;
  bool _regConfirmObscure = true;
  bool _regLoading = false;
  String? _regError;

  // Session code fields
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());
  bool _joinLoading = false;
  String? _joinError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regChildNameController.dispose();
    _regParentNameController.dispose();
    _regUsernameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmController.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _sessionCode =>
      _codeControllers.map((c) => c.text).join().toUpperCase();

  Future<void> _handlePatientLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() {
      _loginLoading = true;
      _loginError = null;
    });

    try {
      final input = _loginUsernameController.text.trim();
      final email = input.contains('@') ? input : '$input@patient.bloomspeech.app';
      await ref.read(authServiceProvider).signInWithEmail(
            email: email,
            password: _loginPasswordController.text,
          );
      if (mounted) context.goNamed(AppRouter.home);
    } catch (e) {
      if (mounted) {
        setState(() => _loginError = _friendlyError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _loginLoading = true;
      _loginError = null;
    });

    try {
      // Opens the browser and returns immediately. The session does not exist
      // yet — it arrives over the deep link once Google redirects back, and
      // the router sends the user to home when it does.
      //
      // This used to navigate to home on the very next line, before any
      // session existed. The router found no user and bounced straight back
      // here, which is exactly what "Google sign-in doesn't work" looked like:
      // a flicker, and no error to explain it.
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() => _loginError = _friendlyError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _handlePatientRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() {
      _regLoading = true;
      _regError = null;
    });

    try {
      final email = _regEmailController.text.trim();

      final result = await ref.read(authServiceProvider).registerWithEmail(
            email: email,
            password: _regPasswordController.text,
            displayName: _regChildNameController.text.trim(),
            role: 'kid',
          );

      // Create a child profile for this patient linked directly to their user ID
      await ref.read(firestoreServiceProvider).createPatientChildProfile(
            childId: result.user.uid,
            name: _regChildNameController.text.trim(),
            parentName: _regParentNameController.text.trim(),
            email: email,
          );

      if (!mounted) return;
      if (result.needsEmailConfirmation) {
        setState(() => _regError =
            'Account created. Open the confirmation link in your email — it '
            'will bring you back here and sign you in.');
        return;
      }
      context.goNamed(AppRouter.home);
    } catch (e) {
      if (mounted) {
        setState(() => _regError = _friendlyError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _regLoading = false);
    }
  }

  /// Delegates to the shared mapping in [AuthError].
  ///
  /// This existed twice in this file, in two classes, with wording that had
  /// already drifted apart — and neither copy covered an unconfirmed email, a
  /// rate limit, or a dropped connection, so those all fell through to raw
  /// exception text.
  String _friendlyError(String error) => AuthError.from(error).message;

  Future<void> _joinSession() async {
    final code = _sessionCode;
    if (code.length != 6) {
      setState(() => _joinError = 'Please enter all 6 characters');
      return;
    }

    setState(() {
      _joinLoading = true;
      _joinError = null;
    });

    try {
      if (mounted) {
        context.goNamed(
          AppRouter.kidSession,
          pathParameters: {'sessionCode': code},
        );
      }
    } catch (e) {
      setState(() {
        _joinError = 'Could not connect. Try again.';
        _joinLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧒 '),
            Text('patient_title'.tr(language).split(' /').first),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: 'login'.tr(language)),
            Tab(text: 'register'.tr(language)),
            Tab(text: 'join_session'.tr(language)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPatientLoginTab(),
          _buildPatientRegisterTab(),
          _buildJoinSessionTab(),
        ],
      ),
    );
  }

  // ─── Patient Login Tab ───
  Widget _buildPatientLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: AppColors.warmGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.child_care_rounded,
                    size: 34, color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: Text('Welcome Back!'.tr(), style: AppTextStyles.headlineMedium),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Login with your patient account'.tr(),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 32),

            // Email (Username)
            Text('Email Address (Username)'.tr(), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _loginUsernameController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'your.email@example.com'.tr(),
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.textHint.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.textHint.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter your email address' : null,
            ),

            const SizedBox(height: 18),

            // Password
            Text('Password'.tr(), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _loginPasswordController,
              obscureText: _loginObscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handlePatientLogin(),
              decoration: InputDecoration(
                hintText: 'Enter password'.tr(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_loginObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _loginObscure = !_loginObscure),
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.textHint.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.textHint.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter your password' : null,
            ),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => ForgotPasswordDialog.show(
                  context,
                  initialEmail: _loginUsernameController.text.trim(),
                  accent: AppColors.accent,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot Password?'.tr(),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.accentDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            if (_loginError != null) ...[
              const SizedBox(height: 14),
              _buildErrorBanner(_loginError!),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loginLoading ? null : _handlePatientLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _loginLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text('Login'.tr(), style: AppTextStyles.buttonText),
              ),
            ),

            const SizedBox(height: 20),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider(thickness: 1, color: Color(0xFFE2E8F0))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'OR'.tr(),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(child: Divider(thickness: 1, color: Color(0xFFE2E8F0))),
              ],
            ),

            const SizedBox(height: 20),

            // Google Login Button
            _buildGoogleButton(
              label: 'Continue with Google'.tr(),
              onPressed: _handleGoogleLogin,
            ),

            const SizedBox(height: 24),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("New here? ",
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: Text('Register'.tr(),
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.accent)),
                  ),
                  Text(' or '.tr(),
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(2),
                    child: Text('Join Session'.tr(),
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.accent)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Patient Register Tab ───
  Widget _buildPatientRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            Center(
              child: Text('Create Patient Account'.tr(),
                  style: AppTextStyles.headlineMedium),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Register with your details'.tr(),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 24),

            // Child name
            Text('Child\'s Name'.tr(), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regChildNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _patientInputDecor('Child\'s full name', Icons.child_care_rounded),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter child\'s name' : null,
            ),

            const SizedBox(height: 14),

            // Parent name
            Text('Parent\'s Name'.tr(), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regParentNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _patientInputDecor('Parent/Guardian name', Icons.family_restroom_rounded),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter parent name' : null,
            ),

            const SizedBox(height: 14),

            // Email (Username)
            Text('Email Address (Username)'.tr(), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _patientInputDecor('parent.or.child@example.com', Icons.email_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter an email address';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Password
            Text('Password'.tr(), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regPasswordController,
              obscureText: _regObscure,
              textInputAction: TextInputAction.next,
              decoration: _patientInputDecor('Min 6 characters', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_regObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _regObscure = !_regObscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a password';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Confirm
            Text('Confirm Password'.tr(), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regConfirmController,
              obscureText: _regConfirmObscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handlePatientRegister(),
              decoration: _patientInputDecor('Re-enter password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_regConfirmObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _regConfirmObscure = !_regConfirmObscure),
                ),
              ),
              validator: (v) {
                if (v != _regPasswordController.text) return 'Passwords don\'t match';
                return null;
              },
            ),

            if (_regError != null) ...[
              const SizedBox(height: 14),
              _buildErrorBanner(_regError!),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _regLoading ? null : _handlePatientRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _regLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text('Create Account'.tr(), style: AppTextStyles.buttonText),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already registered? '.tr(),
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: Text('Login'.tr(),
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.accent)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Join Session Tab (code entry) ───
  Widget _buildJoinSessionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 24),

          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.warmGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.qr_code_scanner_rounded,
                size: 38, color: Colors.white),
          ),

          const SizedBox(height: 20),
          Text('Join Session'.tr(), style: AppTextStyles.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Enter the 6-digit code from your clinician'.tr(),
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 36),

          // Code input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 44,
                height: 56,
                child: TextFormField(
                  controller: _codeControllers[index],
                  focusNode: _codeFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.accent, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _codeFocusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _codeFocusNodes[index - 1].requestFocus();
                    }
                    if (_sessionCode.length == 6) _joinSession();
                  },
                ),
              );
            }),
          ),

          if (_joinError != null) ...[
            const SizedBox(height: 14),
            _buildErrorBanner(_joinError!),
          ],

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _joinLoading ? null : _joinSession,
              icon: _joinLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(
                _joinLoading ? 'Connecting...' : 'Join Session',
                style: AppTextStyles.buttonText,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your clinician will give you a session code. You don\'t need an account to join a session!'
                        .tr(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: const Icon(
                Icons.g_mobiledata_rounded,
                color: Color(0xFF4285F4),
                size: 32,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _patientInputDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
