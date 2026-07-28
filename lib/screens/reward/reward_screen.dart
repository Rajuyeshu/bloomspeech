import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../services/audio_service.dart';
import 'dart:math';

class RewardScreen extends ConsumerStatefulWidget {
  const RewardScreen({super.key});

  @override
  ConsumerState<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends ConsumerState<RewardScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  final List<_Sparkle> _sparkles = [];

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    _confettiController.play();
    ref.read(audioServiceProvider).playCelebration();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _addSparkle(TapDownDetails details) {
    setState(() {
      _sparkles.add(_Sparkle(
        position: details.localPosition,
        id: DateTime.now().millisecondsSinceEpoch,
      ));
    });

    // Remove after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _sparkles.removeWhere(
              (s) => s.id == _sparkles.firstOrNull?.id);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: _addSparkle,
        child: Stack(
          children: [
            // Background
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF16213E),
                    Color(0xFF0F3460),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Animated stars background
            ...List.generate(20, (i) {
              final random = Random(i);
              return Positioned(
                left: random.nextDouble() * MediaQuery.of(context).size.width,
                top: random.nextDouble() * MediaQuery.of(context).size.height,
                child: Icon(
                  Icons.star_rounded,
                  size: 8 + random.nextDouble() * 12,
                  color:
                      Colors.white.withValues(alpha: 0.2 + random.nextDouble() * 0.3),
                )
                    .animate(
                      onPlay: (c) => c.repeat(reverse: true),
                    )
                    .fadeIn(
                      delay: Duration(milliseconds: random.nextInt(2000)),
                    )
                    .then()
                    .fadeOut(
                      duration: Duration(
                        milliseconds: 1000 + random.nextInt(2000),
                      ),
                    ),
              );
            }),

            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Trophy/star
                    const Text('🏆', style: TextStyle(fontSize: 80))
                        .animate()
                        .scale(
                          begin: const Offset(0.2, 0.2),
                          end: const Offset(1, 1),
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        )
                        .then()
                        .shimmer(
                          duration: 1500.ms,
                          color: AppColors.tokenGold.withValues(alpha: 0.5),
                        ),

                    const SizedBox(height: 24),

                    Text(
                      'Amazing! 🌟',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.tokenGold,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 10),

                    Text(
                      'You reached your goal!',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 600.ms),

                    const SizedBox(height: 12),

                    Text(
                      'Tap anywhere for sparkles! ✨',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 1200.ms, duration: 600.ms),

                    const SizedBox(height: 40),

                    // Done button (clinician controls)
                    ElevatedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Done — Continue Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tokenGold,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.tokenGold.withValues(alpha: 0.4),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 1500.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),

            // Sparkles from taps
            ..._sparkles.map((sparkle) {
              return Positioned(
                left: sparkle.position.dx - 20,
                top: sparkle.position.dy - 20,
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.tokenGold,
                  size: 40,
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.5, 1.5),
                      duration: 500.ms,
                    )
                    .fadeOut(duration: 800.ms),
              );
            }),

            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.03,
                numberOfParticles: 20,
                gravity: 0.05,
                colors: const [
                  AppColors.tokenGold,
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.accent,
                  Colors.white,
                  AppColors.smoothGreen,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sparkle {
  final Offset position;
  final int id;
  _Sparkle({required this.position, required this.id});
}
