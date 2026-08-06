import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/constants/app_constants.dart';
import '../../services/firestore_service.dart';
import '../../services/audio_service.dart';
import '../../models/session.dart';
import '../../utils/bilingual_phrases.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes/app_router.dart';
import '../../widgets/embedded_video_call.dart';
import '../../widgets/theme_token_board.dart';

/// Kid's session screen — receives real-time updates from clinician via polling
class KidSessionScreen extends ConsumerStatefulWidget {
  final String sessionCode;
  const KidSessionScreen({super.key, required this.sessionCode});

  @override
  ConsumerState<KidSessionScreen> createState() => _KidSessionScreenState();
}

class _KidSessionScreenState extends ConsumerState<KidSessionScreen>
    with TickerProviderStateMixin {
  ActiveSession? _session;
  bool _isLoading = true;
  bool _hasError = false;
  String? _lastFeedbackType;
  bool _showFeedback = false;
  final bool _showEmbeddedVideoCall = true;
  String _feedbackEmoji = '';
  String _feedbackText = '';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchSession();
    // Poll every 2 seconds for real-time token sync
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchSession(isPolling: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSession({bool isPolling = false}) async {
    try {
      final session = await ref
          .read(firestoreServiceProvider)
          .fetchActiveSession(widget.sessionCode);

      if (!mounted) return;

      if (session != null) {
        // Detect feedback changes from clinician taps
        if (session.lastFeedbackType != null &&
            session.lastFeedbackType != _lastFeedbackType) {
          _lastFeedbackType = session.lastFeedbackType;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _triggerFeedback(
                  session.lastFeedbackType == 'fluent', session.language);
            }
          });
        }

        setState(() {
          _session = session;
          _isLoading = false;
          _hasError = false;
        });
      } else if (!isPolling) {
        // Only show error on initial fetch, not during polling
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      if (!isPolling && mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _onBack() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Session?'),
        content: const Text(
          'Are you sure you want to leave this therapy session?',
        ),
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
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.goNamed(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF8E1), Color(0xFFFFE0B2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.accent),
                SizedBox(height: 20),
                Text('Connecting to session...'),
              ],
            ),
          ),
        ),
      );
    }

    // Error state — invalid code or session not found
    if (_hasError || _session == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF8E1), Color(0xFFFFE0B2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 64, color: AppColors.error),
                  const SizedBox(height: 20),
                  Text(
                    'Session not found 😕',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The code "${widget.sessionCode}" does not match any active session. Please check with your clinician.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _hasError = false;
                      });
                      _fetchSession();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('← Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final session = _session!;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _onBack();
      },
      child: Scaffold(
        body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFF8E1),
              session.lastFeedbackType == 'fluent'
                  ? AppColors.smoothGreen.withValues(alpha: 0.05)
                  : const Color(0xFFFFE0B2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content — token board always visible
              Column(
                children: [
                  const SizedBox(height: 16),

                  // Child name
                  Text(
                    'Hi ${session.childName}! 👋',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 6),

                  Text(
                    'Keep talking! You\'re doing great!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Kid-attractive Theme Token Board Widget
                  ThemeTokenBoardWidget(
                    theme: PlayTheme.values.firstWhere(
                      (t) => t.name == session.playTheme,
                      orElse: () => PlayTheme.diyaFestival,
                    ),
                    currentTokens: session.currentTokenCount,
                    tokenGoal: session.tokenGoal,
                  ),

                  const SizedBox(height: 16),

                  // Token dots (big, kid-friendly)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        session.tokenGoal,
                        (index) {
                          final isFilled =
                              index < session.currentTokenCount;
                          return AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 400),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled
                                  ? AppColors.tokenGold
                                  : AppColors.tokenEmpty
                                      .withValues(alpha: 0.4),
                              boxShadow: isFilled
                                  ? [
                                      BoxShadow(
                                        color: AppColors.tokenGold
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isFilled
                                ? const Icon(Icons.star_rounded,
                                    color: Colors.white, size: 14)
                                : null,
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Rewards count
                  if (session.rewardCyclesCompleted > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🎉 ${session.rewardCyclesCompleted} reward${session.rewardCyclesCompleted > 1 ? 's' : ''} earned!',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.accentDark,
                        ),
                      ),
                    ),

                  // Embedded Jitsi Video Call (below the token board)
                  if (_showEmbeddedVideoCall) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: MediaQuery.of(context).size.height < 750 ? 160 : 260,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: EmbeddedVideoCallWidget(
                          sessionCode: widget.sessionCode,
                          userName: session.childName,
                          isClinician: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    const Spacer(),
                    // Fun decorations
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: PlayTheme.values.map((t) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(t.emoji,
                                style: const TextStyle(fontSize: 24)),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),

              // Feedback overlay
              if (_showFeedback)
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _showFeedback ? 1 : 0,
                    child: Container(
                      color: _lastFeedbackType == 'fluent'
                          ? AppColors.smoothGreen.withValues(alpha: 0.2)
                          : AppColors.bumpyOrange.withValues(alpha: 0.15),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _feedbackEmoji,
                              style: const TextStyle(fontSize: 80),
                            )
                                .animate()
                                .scale(
                                  begin: const Offset(0.3, 0.3),
                                  end: const Offset(1, 1),
                                  duration: 500.ms,
                                  curve: Curves.elasticOut,
                                ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40),
                              child: Text(
                                _feedbackText,
                                style:
                                    AppTextStyles.headlineMedium.copyWith(
                                  color: _lastFeedbackType == 'fluent'
                                      ? AppColors.smoothGreenDark
                                      : AppColors.bumpyOrangeDark,
                                ),
                                textAlign: TextAlign.center,
                              )
                                  .animate()
                                  .fadeIn(delay: 200.ms),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _triggerFeedback(bool isSmooth, String language) {
    final phrases = BilingualPhrases.feedback;
    String key;
    if (isSmooth) {
      key = 'fluent_${Random().nextInt(5) + 1}';
      _feedbackEmoji = '🌟';
    } else {
      key = 'dysfluent_${Random().nextInt(3) + 1}';
      _feedbackEmoji = '💪';
    }
    _feedbackText = BilingualPhrases.getPhrase(phrases, key, language);
    if (_feedbackText.isEmpty) {
      _feedbackText = isSmooth
          ? 'Great job! So smooth!'
          : "That's okay! Try again!";
    }

    setState(() => _showFeedback = true);

    // Play audio on kid's device too
    if (isSmooth) {
      ref.read(audioServiceProvider).playSmoothFeedback(
            phrase: _feedbackText,
            languageCode: language,
          );
    } else {
      ref.read(audioServiceProvider).playBumpyFeedback(
            phrase: _feedbackText,
            languageCode: language,
          );
    }

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _showFeedback = false);
    });
  }
}
