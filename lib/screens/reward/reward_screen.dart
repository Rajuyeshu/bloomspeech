import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/routes/app_router.dart';
import '../../config/constants/app_constants.dart';
import '../../utils/bilingual_phrases.dart';
import '../../services/audio_service.dart';
import '../../services/firestore_service.dart';
import 'dart:math';

class RewardScreen extends ConsumerStatefulWidget {
  final String? miniGame;
  final String? sessionCode;

  /// `RewardType` name chosen at session setup. The mini-game is offered only
  /// for `inAppMiniGame`; previously the button appeared whenever a mini-game
  /// name was present, which it always is (it has a default), so a physical
  /// reward or a plain animation still showed "Play Mini Game".
  final String? rewardType;

  /// Key into `BilingualPhrases.physicalRewards`, for `physicalReward`.
  final String? physicalReward;

  const RewardScreen({
    super.key,
    this.miniGame,
    this.sessionCode,
    this.rewardType,
    this.physicalReward,
  });

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

  static const List<String> _celebrationGlyphs = [
    '⭐', '🎈', '🎉', '✨', '🌟', '🎊', '💫', '🏅'
  ];

  void _addSparkle(TapDownDetails details) {
    final rand = Random();
    setState(() {
      _sparkles.add(_Sparkle(
        position: details.localPosition,
        id: DateTime.now().microsecondsSinceEpoch,
        glyphs: List.generate(
            6, (_) => _celebrationGlyphs[rand.nextInt(_celebrationGlyphs.length)]),
      ));
      // Bound the list: a child tapping continuously for a minute would
      // otherwise accumulate hundreds of widgets.
      if (_sparkles.length > 12) _sparkles.removeAt(0);
    });

    final id = _sparkles.last.id;
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) {
        // Remove THIS burst by id. The old code removed whichever burst
        // happened to be first, so rapid taps cleared each other's.
        setState(() => _sparkles.removeWhere((s) => s.id == id));
      }
    });
  }

  /// Which kind of reward this session grants. Defaults to the mini-game so
  /// existing sessions created before this was stored keep working.
  RewardType get _reward => RewardType.values.firstWhere(
        (r) => r.name == widget.rewardType,
        orElse: () => RewardType.inAppMiniGame,
      );

  bool get _showMiniGame =>
      _reward == RewardType.inAppMiniGame &&
      widget.miniGame != null &&
      widget.miniGame!.isNotEmpty;

  void _navigateToMiniGame() {
    // Switch over the enum, not over string literals.
    //
    // The previous version matched 'plantWater' and 'rangoliPaint', but
    // `MiniGameType` names them `plantWatering` and `rangoliPainter` — so
    // neither ever matched and both silently fell through to `default`,
    // launching Bubble Burst no matter what the clinician had chosen.
    // An exhaustive switch on the enum makes that drift a compile error
    // rather than a wrong game.
    final game = MiniGameType.values.firstWhere(
      (g) => g.name == widget.miniGame,
      orElse: () => MiniGameType.bubbleBurst,
    );
    switch (game) {
      case MiniGameType.bubbleBurst:
        context.pushNamed(AppRouter.bubbleBurst);
      case MiniGameType.balloonPop:
        context.pushNamed(AppRouter.balloonPop);
      case MiniGameType.plantWatering:
        // Withdrawn; a session saved against it plays the game that replaced it.
        context.pushNamed(AppRouter.balloonPop);
      case MiniGameType.rangoliPainter:
        context.pushNamed(AppRouter.rangoliPaint);
    }
  }

  void _goBack() {
    // Clear the reward flags on the way out. The clinician no longer opens the
    // reward screen, so this device is the only one that knows the child has
    // finished playing; leaving them set would keep the session marked as
    // rewarding indefinitely.
    final code = widget.sessionCode;
    if (code != null && code.isNotEmpty) {
      ref.read(firestoreServiceProvider).updateActiveSession(
        sessionCode: code,
        data: {'rewardActive': false, 'miniGameActive': false},
      );
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRouter.home);
    }
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
                  color: Colors.white
                      .withValues(alpha: 0.2 + random.nextDouble() * 0.3),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(
                        delay: Duration(milliseconds: random.nextInt(2000)))
                    .then()
                    .fadeOut(
                      duration: Duration(
                          milliseconds: 1000 + random.nextInt(2000)),
                    ),
              );
            }),

            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Trophy
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
                            color:
                                AppColors.tokenGold.withValues(alpha: 0.5),
                          ),

                      const SizedBox(height: 24),

                      Text(
                        'Amazing! 🌟'.tr(),
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
                        'You reached your goal!'.tr(),
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 700.ms, duration: 600.ms),

                      const SizedBox(height: 12),

                      Text(
                        'Tap anywhere for a surprise! 🎉'.tr(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 1200.ms, duration: 600.ms),

                      const SizedBox(height: 32),

                      // Physical reward — the clinician hands it over in
                      // person, so tell the child what to expect instead of
                      // offering a game.
                      if (_reward == RewardType.physicalReward)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.tokenGold.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎁',
                                    style: TextStyle(fontSize: 44)),
                                const SizedBox(height: 10),
                                Text(
                                  'Ask your therapist for your reward!'.tr(),
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (widget.physicalReward != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    BilingualPhrases.getPhrase(
                                      BilingualPhrases.physicalRewards,
                                      widget.physicalReward!,
                                      'en',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.tokenGold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                      // Play Mini Game button — only when that is the reward.
                      if (_showMiniGame)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ElevatedButton.icon(
                            onPressed: _navigateToMiniGame,
                            icon: const Icon(Icons.sports_esports_rounded,
                                size: 24),
                            label: Text('Play Mini Game! 🎮'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 8,
                              shadowColor:
                                  AppColors.accent.withValues(alpha: 0.4),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 1300.ms, duration: 600.ms)
                              .slideY(begin: 0.2, end: 0),
                        ),

                      // Done button
                      ElevatedButton.icon(
                        onPressed: _goBack,
                        icon: const Icon(Icons.check_rounded),
                        label: Text('Done — Continue Session'.tr()),
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
                          shadowColor:
                              AppColors.tokenGold.withValues(alpha: 0.4),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 1500.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ),
              ),
            ),

            // Each tap throws a burst outward from where the child touched.
            ..._sparkles.expand((sparkle) {
              return List.generate(sparkle.glyphs.length, (i) {
                final angle = (2 * pi / sparkle.glyphs.length) * i;
                final distance = 58.0 + (i.isEven ? 22 : 0);
                return Positioned(
                  left: sparkle.position.dx - 18,
                  top: sparkle.position.dy - 18,
                  child: IgnorePointer(
                    child: Text(sparkle.glyphs[i],
                            style: const TextStyle(fontSize: 30))
                        .animate()
                        .move(
                          begin: Offset.zero,
                          end: Offset(cos(angle) * distance,
                              sin(angle) * distance - 20),
                          duration: 900.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .scale(
                          begin: const Offset(0.4, 0.4),
                          end: const Offset(1.25, 1.25),
                          duration: 320.ms,
                        )
                        .fadeOut(delay: 480.ms, duration: 420.ms),
                  ),
                );
              });
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

/// One tap's worth of celebration.
///
/// A single grey sparkle icon was not much of a reward. Each tap now throws a
/// small burst of characters outward on its own trajectory, which is far more
/// legible to a preschooler than one fading star.
class _Sparkle {
  final Offset position;
  final int id;
  final List<String> glyphs;
  _Sparkle({required this.position, required this.id, required this.glyphs});
}
