import 'dart:async';
import '../../utils/app_localizations.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/constants/app_constants.dart';
import '../../services/crash_log.dart';
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
  bool _warmedAudio = false;
  bool _isSmoothFeedback = true;

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
          // A child who joined by code is not signed in, so there is no id to
          // announce and nothing the clinician can link. Give the device an
          // anonymous identity first — otherwise this whole branch is skipped
          // and the child's progress can never work.
          var user = ref.read(currentUserProvider);
          if (user == null) {
            try {
              user = await ref
                  .read(authServiceProvider)
                  .signInAnonymouslyForKid();
            } catch (e) {
              debugPrint('Anonymous sign-in failed: $e');
              CrashLog.record(
                'Child device could not be identified',
                StackTrace.fromString(
                  'This device joined by code and is not signed in, and '
                  'anonymous sign-in failed: $e\n\n'
                  'Enable "Anonymous sign-ins" in the Supabase dashboard '
                  '(Authentication -> Sign In / Providers), or have the family '
                  'register a patient account. Until then the clinician cannot '
                  'link this device and progress here stays empty.',
                ),
              );
            }
          }

          if (user != null && session.childId.isNotEmpty) {
            // Announce who is on this device. The clinician picks this up when
            // saving and writes the link with their own credentials — the kid
            // may not be permitted to touch `children` at all.
            //
            // This is the first link in the chain that ends with the child
            // being able to see their own progress, and it was fire-and-forget
            // over a call that swallowed its errors: if it failed there was no
            // kid id on the row, the clinician silently skipped the linking
            // step, and the child's progress stayed empty permanently. Record
            // a failure so Data Diagnostics can report it.
            ref
                .read(firestoreServiceProvider)
                .updateActiveSession(
                  sessionCode: widget.sessionCode,
                  data: {'kidUserId': user.uid},
                )
                .then((ok) {
              if (!ok) {
                CrashLog.record(
                  'Kid could not announce its id on the session row',
                  StackTrace.fromString(
                    'updateActiveSession(kidUserId) returned false for session '
                    '${widget.sessionCode}. Either active_sessions.kid_user_id '
                    'is missing (run supabase_setup_all.sql) or row-level '
                    'security refused the update. Without it the clinician '
                    'cannot link this device to a child, and progress here '
                    'will stay empty.',
                  ),
                );
              }
            });

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

        if (!_warmedAudio) {
          _warmedAudio = true;
          // Same reason as the clinician side: pay the synthesis cost before
          // the first utterance, not during it.
          ref.read(audioServiceProvider).warmUp(session.language);
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
                  'rewardType': session.rewardType,
                  if (session.physicalReward != null)
                    'physicalReward': session.physicalReward!,
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

  /// Whether this device should be in the video call.
  ///
  /// Normally the clinician decides, via `kid_video_started`. If the database
  /// predates that column there is no channel to say so — and gating on a flag
  /// that can never become true meant the child never joined at all while the
  /// clinician sat in the room alone. In that case fall back to joining
  /// whenever the session is live, which is how the app behaved before the
  /// control existed.
  bool _videoAllowed(ActiveSession session) =>
      session.kidCallColumnsPresent ? session.kidVideoStarted : true;

  /// Mirrors the clinician's call controls onto this device.
  ///
  /// Jitsi's public server won't make the clinician a real moderator, so
  /// remote mute is done cooperatively: the clinician writes the flag, the
  /// kid's device reads it and mutes itself.
  void _applyClinicianCallControls(ActiveSession session) {
    // Clinician turned the call off — leave the conference. Driven by the flag
    // rather than widget teardown, which fired for unrelated rebuilds.
    final videoOn = _videoAllowed(session);

    // Only hang up when the clinician actually turned the call off. A row that
    // simply does not carry these columns parses as `false`, which is
    // indistinguishable from "stop the call" — and this runs on every two
    // second poll, so one such read would drop the child out mid-session.
    if (_appliedVideoStarted && !videoOn && session.kidCallColumnsPresent) {
      VideoCallService.leaveCall();
    }
    _appliedVideoStarted = videoOn;

    if (session.kidAudioMuted != _appliedAudioMuted) {
      _appliedAudioMuted = session.kidAudioMuted;
      VideoCallService.setAudioMuted(session.kidAudioMuted);
    }
    if (session.kidVideoMuted != _appliedVideoMuted) {
      _appliedVideoMuted = session.kidVideoMuted;
      VideoCallService.setVideoMuted(session.kidVideoMuted);
    }
  }



  /// The glyph the feedback overlay animates, chosen to match the active play
  /// theme so a fluent utterance lights a diya, ripens a mango, and so on —
  /// rather than showing the same generic star for every theme.
  ({String glyph, String label}) _themeFeedbackGlyph(
      PlayTheme theme, bool isSmooth) {
    if (!isSmooth) {
      // Gentle and non-punitive: the same object, dimmed or unlit.
      switch (theme) {
        case PlayTheme.diyaFestival:
          return (glyph: '🪔', label: 'flicker');
        case PlayTheme.rangoliBuilder:
          return (glyph: '🌸', label: 'fade');
        case PlayTheme.mangoHarvest:
          return (glyph: '🥭', label: 'fade');
        case PlayTheme.peacockGarden:
          return (glyph: '🪶', label: 'fade');
        case PlayTheme.lotusPond:
          return (glyph: '🪷', label: 'fade');
        case PlayTheme.kiteFestival:
          return (glyph: '🪁', label: 'dip');
        default:
          // Container themes: the same reward object, dimmed rather than
          // replaced, so a lost token never introduces a new image.
          return (glyph: theme.emoji, label: 'fades');
      }
    }
    switch (theme) {
      case PlayTheme.diyaFestival:
        return (glyph: '🪔', label: 'lights up');
      case PlayTheme.rangoliBuilder:
        return (glyph: '🌸', label: 'blooms');
      case PlayTheme.mangoHarvest:
        return (glyph: '🥭', label: 'ripens');
      case PlayTheme.peacockGarden:
        return (glyph: '🦚', label: 'fans out');
      case PlayTheme.lotusPond:
        return (glyph: '🌸', label: 'blooms');
      case PlayTheme.kiteFestival:
        return (glyph: '🪁', label: 'soars');
      default:
        return (glyph: theme.emoji, label: 'collected');
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
            Text('Session Complete!'.tr(),
                style: AppTextStyles.titleLarge
                    .copyWith(color: AppColors.primary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Great job! Your clinician has ended the session.'.tr(),
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
              label: Text('My Progress'.tr()),
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
            child: Text('Done! 🌟'.tr()),
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
              child: Text('Session in progress'.tr(),
                  style: AppTextStyles.titleLarge
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ),
        content: Text(
          'Your therapist is running this session. It will finish when they end it — keep practising!'
              .tr(),
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
            child: Text('OK 👍'.tr()),
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
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.accent),
                const SizedBox(height: 20),
                Text('Connecting to session...'.tr()),
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
                    'Session not found 😕'.tr(),
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
                    label: Text('Try Again'.tr()),
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
                    child: Text('← Go Back'.tr()),
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
                    'Keep talking! You\'re doing great!'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // The token board. Sized to the space actually available
                  // rather than a fixed height: this is the one thing on the
                  // screen the child is meant to look at, and it previously
                  // sat small with empty space beneath it.
                  //
                  // There used to be a second row of gold stars below this,
                  // duplicating the same count in a different visual language.
                  // A preschooler seeing chocolates in a box and then a row of
                  // stars has to work out that they are the same thing, and the
                  // stars ignored the chosen theme entirely.
                  LayoutBuilder(
                    builder: (context, _) {
                      final screen = MediaQuery.of(context).size.height;
                      // Leave room for the greeting, the video panel and the
                      // reward banner; give everything else to the board.
                      final reserved = isSmallScreen ? 300.0 : 330.0;
                      final boardHeight =
                          (screen - reserved).clamp(200.0, 420.0);
                      return SizedBox(
                        height: boardHeight,
                        child: ThemeTokenBoardWidget(
                          theme: PlayTheme.values.firstWhere(
                            (t) => t.name == session.playTheme,
                            orElse: () => PlayTheme.initial,
                          ),
                          currentTokens: session.currentTokenCount,
                          tokenGoal: session.tokenGoal,
                        ),
                      );
                    },
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
                  if (_showEmbeddedVideoCall && _videoAllowed(session)) ...[
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
                              'Waiting for your therapist…'.tr(),
                              style: AppTextStyles.titleSmall
                                  .copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'They will start the video call'.tr(),
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
                        children: PlayTheme.selectable.take(6).map((t) {
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
                        color: _isSmoothFeedback
                            ? AppColors.smoothGreen.withValues(alpha: 0.2)
                            : AppColors.bumpyOrange.withValues(alpha: 0.15),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Fluent: a celebratory pop with a shimmer.
                              // Dysfluent: a soft flicker and settle — never a
                              // shake or a shrink, which would read as a
                              // reprimand to the child.
                              if (_isSmoothFeedback)
                                Text(
                                  _feedbackEmoji,
                                  style: const TextStyle(fontSize: 84),
                                )
                                    .animate()
                                    .scale(
                                      begin: const Offset(0.3, 0.3),
                                      end: const Offset(1, 1),
                                      duration: 500.ms,
                                      curve: Curves.elasticOut,
                                    )
                                    .shimmer(
                                      duration: 900.ms,
                                      color: AppColors.tokenGold,
                                    )
                              else
                                Text(
                                  _feedbackEmoji,
                                  style: TextStyle(
                                    fontSize: 76,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 250.ms)
                                    .then()
                                    .fadeOut(duration: 220.ms)
                                    .then()
                                    .fadeIn(duration: 260.ms),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40),
                                child: Text(
                                  _feedbackText,
                                  style:
                                      AppTextStyles.headlineMedium.copyWith(
                                    color: _isSmoothFeedback
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
    final theme = PlayTheme.values.firstWhere(
      (t) => t.name == (_session?.playTheme ?? ''),
      orElse: () => PlayTheme.diyaFestival,
    );
    final visual = _themeFeedbackGlyph(theme, isSmooth);
    _feedbackEmoji = visual.glyph;
    _isSmoothFeedback = isSmooth;

    if (isSmooth) {
      key = 'fluent_${Random().nextInt(5) + 1}';
    } else {
      key = 'dysfluent_${Random().nextInt(3) + 1}';
    }
    _feedbackText = BilingualPhrases.getPhrase(phrases, key, language);
    if (_feedbackText.isEmpty) {
      _feedbackText = isSmooth
          ? 'Great job! So smooth!'
          : "That's okay! Try again!";
    }

    setState(() => _showFeedback = true);

    // Play audio on kid's device too
    // The English phrase is spoken instead when the device has no voice for the
    // session language — the child hears words rather than mangled phonemes.
    final fallback = BilingualPhrases.getPhrase(phrases, key, 'en');
    if (isSmooth) {
      ref.read(audioServiceProvider).playSmoothFeedback(
            phrase: _feedbackText,
            languageCode: language,
            fallbackPhrase: fallback,
          );
    } else {
      ref.read(audioServiceProvider).playBumpyFeedback(
            phrase: _feedbackText,
            languageCode: language,
            fallbackPhrase: fallback,
          );
    }

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _showFeedback = false);
    });
  }
}
