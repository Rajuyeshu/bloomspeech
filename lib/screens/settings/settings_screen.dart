import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/theme/app_theme.dart';
import '../../config/routes/app_router.dart';
import '../../config/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final language = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          onPressed: () => context.goNamed(AppRouter.home),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Profile Card ───
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.buttonShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName![0].toUpperCase()
                            : '?',
                        style: AppTextStyles.headlineMedium
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Clinician',
                          style: AppTextStyles.titleMedium
                              .copyWith(color: Colors.white),
                        ),
                        Text(
                          user?.email ?? '',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 28),

            // ─── Language Settings ───
            Text('Language', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            _buildSettingCard(
              children: [
                ...AppLanguage.values.map((lang) {
                  final isSelected = language == lang;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          lang.code == 'en' ? '🇬🇧' : '🇮🇳',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    title: Text(lang.displayName,
                        style: AppTextStyles.titleSmall),
                    subtitle: Text(
                      lang == AppLanguage.english
                          ? 'English (India)'
                          : 'Kannada (ಕನ್ನಡ)',
                      style: AppTextStyles.bodySmall,
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      ref.read(appLanguageProvider.notifier).state = lang;
                    },
                  );
                }),
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

            const SizedBox(height: 24),

            // ─── App Info ───
            Text('App', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            _buildSettingCard(
              children: [
                _buildInfoTile(
                  Icons.info_outline_rounded,
                  'App Version',
                  AppConstants.appVersion,
                ),
                const Divider(height: 1, indent: 56),
                _buildInfoTile(
                  Icons.cloud_outlined,
                  'Backend',
                  'Supabase',
                ),
                const Divider(height: 1, indent: 56),
                _buildInfoTile(
                  Icons.video_call_outlined,
                  'Video Calling',
                  'Jitsi Meet',
                ),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

            const SizedBox(height: 24),

            // ─── About ───
            Text('About', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            _buildSettingCard(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_outlined,
                        color: AppColors.info, size: 20),
                  ),
                  title: Text('Privacy Policy',
                      style: AppTextStyles.titleSmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: AppColors.textHint),
                  onTap: () {
                    // Open privacy policy
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.help_outline_rounded,
                        color: AppColors.accent, size: 20),
                  ),
                  title: Text('Help & Support',
                      style: AppTextStyles.titleSmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: AppColors.textHint),
                  onTap: () {
                    // Open help
                  },
                ),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

            const SizedBox(height: 32),

            // ─── Sign Out ───
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) {
                      context.goNamed(AppRouter.login);
                    }
                  }
                },
                icon: const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 20),
                label: Text(
                  'Sign Out',
                  style: AppTextStyles.buttonText
                      .copyWith(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

            const SizedBox(height: 20),

            // App credit
            Center(
              child: Text(
                'BloomSpeech v${AppConstants.appVersion}\nMade with ❤️ for fluent speech',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
      title: Text(title, style: AppTextStyles.titleSmall),
      trailing: Text(
        value,
        style: AppTextStyles.bodySmall
            .copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
