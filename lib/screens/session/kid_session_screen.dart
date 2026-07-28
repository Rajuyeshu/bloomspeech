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
import '../../services/video_call_service.dart';
import '../../widgets/embedded_video_call.dart';
import '../../widgets/theme_token_board.dart';
import 'session_setup_screen.dart';
import 'active_session_screen.dart';
import 'dart:math';

/// Kid's session screen — receives real-time updates from clinician
class KidSessionScreen extends ConsumerStatefulWidget {
  final String sessionCode;
  const KidSessionScreen({super.key, required this.sessionCode});

  @override
  ConsumerState<KidSessionScreen> createState() => _KidSessionScreenState();
}

class _KidSessionScreenState extends ConsumerState<KidSessionScreen>
    with TickerProviderStateMixin {
  String? _lastFeedbackType;
  bool _showFeedback = false;
  bool _showEmbeddedVideoCall = true;
  String _feedbackEmoji = '';
  String _feedbackText = '';

  Future<void> _joinVideoCall(String roomId, String displayName) async {
    try {
      await VideoCallService.joinCall(
        roomName: roomId,
        displayName: displayName,
        subject: 'BloomSpeech Teletherapy Session',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not join video call: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ActiveSession?>(
      stream: ref
          .read(firestoreServiceProvider)
          .listenToActiveSession(widget.sessionCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        final activeState = ref.watch(activeSessionProvider);
        final configState = ref.watch(sessionConfigProvider);

        final session = snapshot.data ??
            (activeState != null
                ? ActiveSession(
                    sessionCode: widget.sessionCode,
                    clinicianId: 'clinician',
                    childId: activeState.config.childId,
                    childName: activeState.config.childName,
                    currentTokenCount: activeState.currentTokens,
                    tokenGoal: activeState.config.tokenGoal,
                    therapyLevel: activeState.config.therapyLevel,
                    playTheme: activeState.config.playTheme,
                    miniGame: activeState.config.miniGame,
                    lastFeedbackType: activeState.lastFeedbackType,
                  )
                : configState != null
                    ? ActiveSession(
                        sessionCode: widget.sessionCode,
                        clinicianId: 'clinician',
                        childId: configState.childId,
                        childName: configState.childName,
                        currentTokenCount: 0,
                        tokenGoal: configState.tokenGoal,
                        therapyLevel: configState.therapyLevel,
                        playTheme: configState.playTheme,
                        miniGame: configState.miniGame,
                      )
                    : ActiveSession(
                        sessionCode: widget.sessionCode,
                        clinicianId: 'clinician',
                        childId: 'child_1',
                        childName: 'Aarav',
                        currentTokenCount: 3,
                        tokenGoal: 10,
                        therapyLevel: 'continuousSpeech',
                        playTheme: 'diyaFestival',
                        miniGame: 'bubbleBurst',
                      ));

        // Detect feedback changes
        if (session.lastFeedbackType != null &&
            session.lastFeedbackType != _lastFeedbackType) {
          _lastFeedbackType = session.lastFeedbackType;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerFeedback(session.lastFeedbackType == 'fluent', session.language);
          });
        }

        final progress = session.tokenGoal > 0
            ? session.currentTokenCount / session.tokenGoal
            : 0.0;

        return Scaffold(
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
                  if (session.videoRoomId != null)
                    Positioned(
                      top: 10,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: () => _joinVideoCall(
                            session.videoRoomId!, session.childName),
                        backgroundColor: AppColors.primary,
                        mini: true,
                        child: const Icon(Icons.videocam_rounded,
                            color: Colors.white),
                      ),
                    ),
                  // Main content
                  Column(
                    children: [
                      const SizedBox(height: 20),

                      // Child name
                      Text(
                        'Hi ${session.childName}! 👋',
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ).animate().fadeIn(),

                      const SizedBox(height: 8),

                      Text(
                        'Keep talking! You\'re doing great!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const Spacer(),

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

                      const SizedBox(height: 24),

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

                      const SizedBox(height: 20),

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

                  // Floating Draggable Video Call Window (Picture-in-Picture)
                  if (_showEmbeddedVideoCall)
                    EmbeddedVideoCallWidget(
                      sessionCode: widget.sessionCode,
                      userName: session.childName,
                      isClinician: false,
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
