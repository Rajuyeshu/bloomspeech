import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/routes/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.goNamed(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // App Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 600.ms),

              const SizedBox(height: 32),

              // App Name
              Text(
                'BloomSpeech',
                style: AppTextStyles.displayLarge.copyWith(
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 800.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 12),

              // Tagline
              Text(
                'Nurturing Fluent Speech'.tr(),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 800.ms)
                  .slideY(begin: 0.2, end: 0),

              const Spacer(flex: 2),

              // Decorative elements
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDecorativeDot(0),
                  const SizedBox(width: 8),
                  _buildDecorativeDot(200),
                  const SizedBox(width: 8),
                  _buildDecorativeDot(400),
                ],
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeDot(int delayMs) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .fadeIn(delay: Duration(milliseconds: 1000 + delayMs))
        .then()
        .scaleXY(end: 1.5, duration: 600.ms)
        .then()
        .scaleXY(end: 1.0, duration: 600.ms);
  }
}
