import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme/app_theme.dart';
import 'config/theme/app_colors.dart';
import 'config/theme/app_text_styles.dart';
import 'config/constants/app_constants.dart';
import 'services/language_service.dart';

// Import all screens for preview navigation
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/session/theme_selection_screen.dart';
import 'screens/reward/reward_screen.dart';
import 'screens/reward/mini_games/bubble_burst_game.dart';
import 'screens/reward/mini_games/plant_water_game.dart';
import 'screens/reward/mini_games/rangoli_paint_game.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/preview/preview_screens.dart';

/// Temporary preview mode — lets you see all screens with or without Supabase
/// Run with: flutter run -d chrome -t lib/main_preview.dart
void main() {
  runApp(
    const ProviderScope(
      child: _PreviewApp(),
    ),
  );
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloomSpeech — UI Preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _ScreenGallery(),
    );
  }
}

/// Gallery of all screens for preview
class _ScreenGallery extends ConsumerWidget {
  const _ScreenGallery();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    final isKn = language == AppLanguage.kannada;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  '🌸 BloomSpeech',
                  style: AppTextStyles.displaySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  isKn
                      ? 'ಯುಐ ಮುನ್ನೋಟ — ಪರೀಕ್ಷಿಸಲು ಯಾವುದೇ ಸ್ಕ್ರೀನ್ ಟ್ಯಾಪ್ ಮಾಡಿ'
                      : 'UI Preview — Tap any screen to preview',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // ─── Auth Screens ───
                _buildSection(isKn ? '🔐 ದೃಢೀಕರಣ' : '🔐 Authentication'),
                _buildTile(context, isKn ? '🚀 ಸ್ಪ್ಲಾಶ್ ಸ್ಕ್ರೀನ್' : '🚀 Splash Screen', const SplashScreen()),
                _buildTile(context, isKn ? '🔐 ಲಾಗಿನ್ (ಚಿಕಿತ್ಸಕರು / ರೋಗಿ)' : '🔐 Login (Clinician / Patient)',
                    const LoginScreen()),

                const SizedBox(height: 20),

                // ─── Clinician: Child Management ───
                _buildSection(isKn ? '👶 ಮಕ್ಕಳ ನಿರ್ವಹಣೆ' : '👶 Child Management (Clinician)'),
                _buildTile(context, isKn ? '🧒 ಮಗುವಿನ ಆಯ್ಕೆ / ಹೊಸ ಮಗು ಸೇರ್ಪಡೆ' : '🧒 Select / Add Child for Therapy',
                    const PreviewChildSelectionScreen()),
                _buildTile(context, isKn ? '➕ ಹೊಸ ಮಗುವಿನ ವಿವರ ನಮೂನೆ' : '➕ Add New Child Form',
                    const PreviewAddChildScreen()),

                const SizedBox(height: 20),

                // ─── Session Setup & Therapy ───
                _buildSection(isKn ? '🩺 ಸೆಷನ್ ಸಂರಚನೆ ಮತ್ತು ಚಿಕಿತ್ಸೆ' : '🩺 Session Setup & Therapy'),
                _buildTile(context, isKn ? '📊 ಚಿಕಿತ್ಸಾ ಮಟ್ಟ ಮತ್ತು ಬಹುಮಾನ ಕಾನ್ಫಿಗರೇಶನ್' : '📊 Treatment Level + Token + Reward Config',
                    const PreviewSessionSetupScreen()),
                _buildTile(context, isKn ? '🎨 ಆಟದ ಥೀಮ್ ಆಯ್ಕೆ' : '🎨 Play Theme Selection',
                    const ThemeSelectionScreen()),
                _buildTile(context, isKn ? '⚡ ಸಕ್ರಿಯ ಚಿಕಿತ್ಸಾ ಸೆಷನ್ (ಟೋಕನ್ ಬೋರ್ಡ್)' : '⚡ Active Therapy Session (Token Board)',
                    const PreviewActiveSessionScreen()),

                const SizedBox(height: 20),

                // ─── Rewards & Mini-Games ───
                _buildSection(isKn ? '🏆 ಬಹುಮಾನಗಳು ಮತ್ತು ಆಟಗಳು' : '🏆 Rewards & Mini-Games'),
                _buildTile(context, isKn ? '🎉 ಸಂಭ್ರಮಾಚರಣೆ ಸ್ಕ್ರೀನ್' : '🎉 Reward Celebration', const RewardScreen()),
                _buildTile(context, isKn ? '🫧 ಗುಳ್ಳೆ ಒಡೆಯುವ ಆಟ' : '🫧 Bubble Burst Game', const BubbleBurstGame()),
                _buildTile(context, isKn ? '🌱 ಗಿಡಕ್ಕೆ ನೀರುಣಿಸುವ ಆಟ' : '🌱 Plant Water Game', const PlantWaterGame()),
                _buildTile(context, isKn ? '🎨 ರಂಗೋಲಿ ಬಣ್ಣಿಸುವ ಆಟ' : '🎨 Rangoli Paint Game', const RangoliPaintGame()),

                const SizedBox(height: 20),

                // ─── Settings ───
                _buildSection(isKn ? '⚙️ ಸೆಟ್ಟಿಂಗ್ಸ್' : '⚙️ Settings'),
                _buildTile(context, isKn ? '⚙️ ಭಾಷೆ, ಪ್ರೊಫೈಲ್ ಮತ್ತು ವಿವರಗಳು' : '⚙️ Settings (Language, Profile, About)',
                    const SettingsScreen()),

                const SizedBox(height: 20),

                // ─── Walkthrough Note ───
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Text(isKn ? 'ಪೂರ್ಣ ಚಿಕಿತ್ಸಾ ಹಂತ' : 'Full Therapy Flow',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: AppColors.success)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isKn
                            ? '1. ಚಿಕಿತ್ಸಕರು ಅಥವಾ ರೋಗಿಯಾಗಿ ಲಾಗಿನ್ ಮಾಡಿ\n'
                              '2. ಇರುವ ಮಗುವನ್ನು ಆರಿಸಿ ಅಥವಾ ಹೊಸ ಮಗುವನ್ನು ನೋಂದಾಯಿಸಿ\n'
                              '3. ಚಿಕಿತ್ಸಾ ಮಟ್ಟ, ನಕ್ಷತ್ರಗಳು, ಥೀಮ್ ಮತ್ತು ಬಹುಮಾನ ಕಾನ್ಫಿಗರ್ ಮಾಡಿ\n'
                              '4. ಸೆಶನ್ ರನ್ ಮಾಡಿ: ಸರಾಗ/ತೊಡರು ಕ್ಲಿಕ್ ಮಾಡಿ ಮಾತು ರೆಕಾರ್ಡ್ ಮಾಡಿ\n'
                              '5. ನಕ್ಷತ್ರಗಳನ್ನು ಗಳಿಸಿ → ಬಹುಮಾನದ ಸಂಭ್ರಮಾಚರಣೆ ಪಡೆಯಿರಿ!\n'
                              '6. ಸೆಷನ್ ಇತಿಹಾಸ ಮತ್ತು ಪ್ರಗತಿಯನ್ನು ಪರಿಶೀಲಿಸಿ'
                            : '1. Login as Clinician or Patient\n'
                              '2. Select an existing child or add new one\n'
                              '3. Configure session: treatment level, tokens, theme, reward\n'
                              '4. Run therapy: tap Smooth/Bumpy to record utterances\n'
                              '5. Earn tokens → get reward celebration!\n'
                              '6. Review session summary & progress',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.info),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isKn
                              ? 'ಪ್ರಗತಿ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್, ಸೆಷನ್ ಇತಿಹಾಸ, ಸೆಷನ್ ಹೋಲಿಕೆ ಮತ್ತು ಮಕ್ಕಳ ಸಾಧನ ಹೊಂದಾಣಿಕೆಯನ್ನು ರಿಯಲ್ ಡೇಟಾಬೇಸ್ ಕಾನ್ಫಿಗರ್ ಮಾಡಿದ ನಂತರ ನೋಡಬಹುದು.\n\n'
                                'ರನ್ ಮಾಡಿ: flutterfire configure'
                              : 'Progress Dashboard, Session History, Session Compare, '
                                'and Kid Session (dual-device sync) will display real '
                                'data once Supabase is configured.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: AppTextStyles.headlineSmall),
    );
  }

  Widget _buildTile(BuildContext context, String title, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: AppTextStyles.titleMedium),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
