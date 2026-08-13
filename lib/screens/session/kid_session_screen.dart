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
import '../../services/auth_service.dart';
import '../../services/video_call_service.dart';
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
  DateTime? _lastFeedbackTime;
  bool _showFeedback = false;
  final bool _showEmbeddedVideoCall = true;
  String _feedbackEmoji = '';
  String _feedbackText = '';
  Timer? _pollTimer;
  bool _isOnRewardScreen = false;
  bool _sessionEnded = false;
  bool _hasLoadedSessionOnce = false;
  // Last clinician control state pushed to the SDK, so polling doesn't
  // re-issue the same mute call every 2 seconds.
  bool _appliedAudioMuted = false;
  bool _appliedVideoMuted = false;
  bool _appliedVideoStarted = false;

  @override
  void initState() {
    super.initState();
    // Initialize TTS audio so it's ready for feedback
    ref.read(audioServiceProvider).initialize();
    _fetchSession();
    // Poll every 2 seconds for real-time token sync
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchSession(isPolling: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    // Never leave the kid in a live meeting after this screen is gone.
    VideoCallService.leaveCall();
    super.dispose();
  }

  Future<void> _fetchSession({bool isPolling = false}) async {
    try {
      final session = await ref
          .read(firestoreServiceProvider)
          .fetchActiveSession(widget.sessionCode);

      if (!mounted) return;

      if (session != null) {
        // Detect session ended by clinician
        if (session.status == SessionStatus.completed && !_sessionEnded) {
          _sessionEnded = true;
          _pollTimer?.cancel();
          // Drop out of the meeting immediately — don't wait for the widget
          // teardown, or the kid sits in the call behind the dialog.
          VideoCallService.leaveCall();
          _showSessionEndedDialog();
          return;
        }

        if (!_hasLoadedSessionOnce) {
          _hasLoadedSessionOnce = true;
          // Attach this kid's login to the clinician's child record the first
          // time they join, so their home and progress screens can find the
          // sessions that get saved against it.
          final user = ref.read(currentUserProvider);
          if (user != null && session.childId.isNotEmpty) {
            // Announce who is on this device. The clinician picks this up when
            // saving and writes the link with their own credentials — the kid
            // may not be permitted to touch `children` at all.
            ref.read(firestoreServiceProvider).updateActiveSession(
              sessionCode: widget.sessionCode,
              data: {'kidUserId': user.uid},
            );

            // Best-effort direct link as well, for setups where the kid does
            // have write access. Failure here is expected and non-fatal now
            // that the clinician-side path exists.
            ref
                .read(firestoreServiceProvider)
                .linkKidToChild(
                  childId: session.childId,
                  kidUserId: user.uid,
                )
                .catchError((e) => debugPrint('direct linkKidToChild: $e'));
          }
        }

        _applyClinicianCallControls(session);

        // Detect reward triggered by clinician (reward_active becomes true)
        if (session.rewardActive && !_isOnRewardScreen) {
          _isOnRewardScreen = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              await context.pushNamed(
                AppRouter.reward,
                queryParameters: {
                  'miniGame': session.miniGame,
                  'sessionCode': widget.sessionCode,
                },
              );
              // Kid returned from reward screen
              if (mounted) {
                setState(() => _isOnRewardScreen = false);
              }
            }
          });
        }

        // Detect feedback changes from clinician taps (compare timestamp for consecutive same-type taps)
        if (session.lastFeedbackType != null &&
            session.lastFeedbackTime != null &&
            session.lastFeedbackTime != _lastFeedbackTime) {
          _lastFeedbackTime = session.lastFeedbackTime;
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
      } else if (_hasLoadedSessionOnce && !_sessionEnded) {
        // The row vanished mid-session — the clinician ended it and the
        // cleanup ran before we could read status == completed. Treat a
        // disappearing session we were previously connected to as "ended"
        // rather than silently leaving the kid on a frozen screen.
        _sessionEnded = true;
        _pollTimer?.cancel();
        VideoCallService.leaveCall();
        _showSessionEndedDialog();
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

  /// Leaves the session for good and returns the kid to their home screen,
  /// where completed sessions, progress reports and practice history live.
  void _leaveSessionToHome(BuildContext dialogContext) {
    Navigator.pop(dialogContext);
    // The session that just finished is new data — force home to re-query so
    // the completed count and progress reflect it immediately.
    ref.read(dataRefreshProvider.notifier).state++;
    // Always `go` — the kid arrived here via `go` from the join screen, so
    // there is usually nothing to pop, and popping would land them back on
    // the code-entry screen instead of home.
    context.goNamed(AppRouter.home);
  }

  /// Mirrors the clinician's call controls onto this device.
  ///
  /// Jitsi's public server won't make the clinician a real moderator, so
  /// remote mute is done cooperatively: the clinician writes the flag, the
  /// kid's device reads it and mutes itself.
  void _applyClinicianCallControls(ActiveSession session) {
    // Clinician turned the call off — leave the conference. Driven by the flag
    // rather than widget teardown, which fired for unrelated rebuilds.
    if (_appliedVideoStarted && !session.kidVideoStarted) {
      VideoCallService.leaveCall();
    }
    _appliedVideoStarted = session.kidVideoStarted;

    if (session.kidAudioMuted != _appliedAudioMuted) {
      _appliedAudioMuted = session.kidAudioMuted;
      VideoCallService.setAudioMuted(session.kidAudioMuted);
    }
    if (session.kidVideoMuted != _appliedVideoMuted) {
      _appliedVideoMuted = session.kidVideoMuted;
      VideoCallService.setVideoMuted(session.kidVideoMuted);
    }
  }

  void _showSessionEndedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text('Session Complete!',
                style: AppTextStyles.titleLarge
                    .copyWith(color: AppColors.primary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Great job! Your clinician has ended the session.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            if (_session != null && _session!.rewardCyclesCompleted > 0) ...[
              const SizedBox(height: 12),
              Text(
                '🏆 You earned ${_session!.rewardCyclesCompleted} reward${_session!.rewardCyclesCompleted > 1 ? 's' : ''}!',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.accentDark),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          if (_session != null)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ref.read(dataRefreshProvider.notifier).state++;
                context.goNamed(AppRouter.home);
                context.pushNamed(
                  AppRouter.progressDashboard,
                  pathParameters: {'childId': _session!.childId},
                );
              },
              icon: const Icon(Icons.insights_rounded, size: 18),
              label: const Text('My Progress'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ElevatedButton(
            onPressed: () => _leaveSessionToHome(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Done! 🌟'),
          ),
        ],
      ),
    );
  }

  /// The session is clinician-controlled: the kid cannot leave on their own.
  /// Back just explains that, and the screen exits only when the clinician
  /// ends the session.
  Future<void> _onBack() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🧑‍⚕️', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Session in progress',
                  style: AppTextStyles.titleLarge
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ),
        content: Text(
          'Your therapist is running this session. It will finish when they '
          'end it — keep practising!',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('OK 👍'),
          ),
        ],
      ),
    );
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

    final isSmallScreen = MediaQuery.of(context).size.height < 750;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
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
              // Main content — token board always visible (scrollable)
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
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
                  SizedBox(
                    height: isSmallScreen ? 180 : 240,
                    child: ThemeTokenBoardWidget(
                      theme: PlayTheme.values.firstWhere(
                        (t) => t.name == session.playTheme,
                        orElse: () => PlayTheme.diyaFestival,
                      ),
                      currentTokens: session.currentTokenCount,
                      tokenGoal: session.tokenGoal,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Token dots (big, kid-friendly)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Wrap(
                      spacing: isSmallScreen ? 8 : 10,
                      runSpacing: isSmallScreen ? 8 : 10,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        session.tokenGoal,
                        (index) {
                          final isFilled =
                              index < session.currentTokenCount;
                          return AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 400),
                            width: isSmallScreen ? 18 : 22,
                            height: isSmallScreen ? 18 : 22,
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
                                ? Icon(Icons.star_rounded,
                                    color: Colors.white, size: isSmallScreen ? 11 : 14)
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

                  // Embedded Jitsi Video Call (below the token board).
                  // Only once the clinician has started it — the kid never
                  // opens the call on their own.
                  if (_showEmbeddedVideoCall && session.kidVideoStarted) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: isSmallScreen ? 130 : 180,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: EmbeddedVideoCallWidget(
                          // Stable identity. Without it, a sibling appearing
                          // above (the reward counter) shifts this widget's
                          // position and Flutter rebuilds its State from
                          // scratch, restarting the call.
                          key: ValueKey('call-${widget.sessionCode}'),
                          sessionCode: widget.sessionCode,
                          userName: session.childName,
                          isClinician: false,
                          startAudioMuted: session.kidAudioMuted,
                          startVideoMuted: session.kidVideoMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else if (_showEmbeddedVideoCall) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: isSmallScreen ? 130 : 180,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hourglass_top_rounded,
                                color: Colors.white70, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'Waiting for your therapist…',
                              style: AppTextStyles.titleSmall
                                  .copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'They will start the video call',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    const SizedBox(height: 40),
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
              ),

              // Feedback overlay
              if (_showFeedback)
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _showFeedback ? 1 : 0,
                    child: IgnorePointer(
                      child: Container(
                        color: _feedbackEmoji == '🌟'
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
                                    color: _feedbackEmoji == '🌟'
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
