import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/routes/app_router.dart';
import '../../config/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/crash_log.dart';
import '../../services/firestore_service.dart';
import '../../services/audio_service.dart';
import '../../services/video_call_service.dart';
import '../../models/session.dart';
import '../../utils/bilingual_phrases.dart';
import '../../utils/app_localizations.dart';
import '../../services/language_service.dart';
import '../../widgets/embedded_video_call.dart';
import '../../widgets/theme_token_board.dart';
import 'session_setup_screen.dart';

/// Active session state
final activeSessionProvider = StateProvider<ActiveSessionState?>((ref) => null);

/// The result of recording one utterance: the next state, and whether that
/// utterance completed a reward cycle.
class TokenOutcome {
  final ActiveSessionState state;
  final bool goalReached;
  const TokenOutcome({required this.state, required this.goalReached});
}

class ActiveSessionState {
  final SessionConfig config;
  final int currentTokens;
  final int rewardCycles;
  final List<Utterance> utterances;
  final DateTime startTime;
  final String? sessionCode;
  final bool showingReward;
  final String? lastFeedbackType;

  ActiveSessionState({
    required this.config,
    this.currentTokens = 0,
    this.rewardCycles = 0,
    this.utterances = const [],
    required this.startTime,
    this.sessionCode,
    this.showingReward = false,
    this.lastFeedbackType,
  });

  /// Record one fluent utterance.
  ///
  /// Extracted from the button handler so the response-cost arithmetic — the
  /// clinical heart of the app — can be tested without a widget tree, an
  /// audio device or a network round trip.
  TokenOutcome recordFluent({DateTime? at}) {
    final now = at ?? DateTime.now();
    final newTokens = currentTokens + config.tokensPerFluent;
    final utterance = Utterance(
      id: now.millisecondsSinceEpoch.toString(),
      timestamp: now,
      type: UtteranceType.fluent,
      // Deliberately the pre-reset figure: the record is of what the child
      // earned, not of the board being cleared for the next cycle.
      tokenCountAfter: newTokens,
    );
    final withUtterance = [...utterances, utterance];

    if (newTokens >= config.tokenGoal) {
      return TokenOutcome(
        state: copyWith(
          currentTokens: 0,
          utterances: withUtterance,
          rewardCycles: rewardCycles + 1,
          showingReward: true,
          lastFeedbackType: 'fluent',
        ),
        goalReached: true,
      );
    }

    return TokenOutcome(
      state: copyWith(
        currentTokens: newTokens,
        utterances: withUtterance,
        lastFeedbackType: 'fluent',
      ),
      goalReached: false,
    );
  }

  /// Record one dysfluent utterance. The token count is the response cost and
  /// must never fall below zero — a negative board would be both meaningless
  /// to the child and impossible to draw.
  TokenOutcome recordDysfluent({DateTime? at}) {
    final now = at ?? DateTime.now();
    final newTokens = max(0, currentTokens - config.tokensPerDysfluent);
    final utterance = Utterance(
      id: now.millisecondsSinceEpoch.toString(),
      timestamp: now,
      type: UtteranceType.dysfluent,
      tokenCountAfter: newTokens,
    );

    return TokenOutcome(
      state: copyWith(
        currentTokens: newTokens,
        utterances: [...utterances, utterance],
        lastFeedbackType: 'dysfluent',
      ),
      goalReached: false,
    );
  }

  ActiveSessionState copyWith({
    SessionConfig? config,
    int? currentTokens,
    int? rewardCycles,
    List<Utterance>? utterances,
    DateTime? startTime,
    String? sessionCode,
    bool? showingReward,
    String? lastFeedbackType,
  }) {
    return ActiveSessionState(
      config: config ?? this.config,
      currentTokens: currentTokens ?? this.currentTokens,
      rewardCycles: rewardCycles ?? this.rewardCycles,
      utterances: utterances ?? this.utterances,
      startTime: startTime ?? this.startTime,
      sessionCode: sessionCode ?? this.sessionCode,
      showingReward: showingReward ?? this.showingReward,
      lastFeedbackType: lastFeedbackType ?? this.lastFeedbackType,
    );
  }
}

class ActiveSessionScreen extends ConsumerStatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _feedbackAnimController;
  late AnimationController _tokenAnimController;
  Timer? _sessionTimer;
  /// Monotonic — unaffected by device clock or time-zone changes.
  final Stopwatch _sessionStopwatch = Stopwatch();
  Duration _elapsedTime = Duration.zero;
  String? _feedbackMessage;
  bool _showFeedback = false;
  bool _isSmoothFeedback = true;
  bool _showEmbeddedVideoCall = true;

  // ─── Clinician control over the kid's call ───
  bool _kidVideoStarted = false;
  bool _kidAudioMuted = false;
  bool _kidVideoMuted = false;

  /// Writes a control flag to the session row; the kid's device polls it.
  /// Push a call-control flag to the child's device.
  ///
  /// Awaited and checked. This used to be fire-and-forget over a method that
  /// swallowed its own errors, so a failed write left the clinician in the
  /// video call alone with no indication that the child had never been told to
  /// join — which looks exactly like "video only works on one device".
  Future<void> _setKidCallFlag(String key, bool value) async {
    final code = ref.read(activeSessionProvider)?.sessionCode;
    if (code == null) return;

    final ok = await ref
        .read(firestoreServiceProvider)
        .updateActiveSession(sessionCode: code, data: {key: value});

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 6),
          content: Text(
            "Could not reach the child's device — they may not join the "
            'video call. Check your connection.'.tr(),
          ),
        ),
      );
    }
  }

  String _generateSessionCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _feedbackAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _tokenAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Initialize session state
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final config = ref.read(sessionConfigProvider);

      // Render the feedback phrases to audio before the first utterance. The
      // first use of a phrase otherwise pays the synthesis cost inline, which
      // is audible as a lag between the clinician's tap and the child hearing
      // it — and in a response-contingent treatment that delay is the thing
      // that weakens the contingency.
      if (config != null) {
        unawaited(ref.read(audioServiceProvider).warmUp(config.language));
      }
      final currentSessionState = ref.read(activeSessionProvider);
      final user = ref.read(currentUserProvider);

      if (currentSessionState != null) {
        if (currentSessionState.sessionCode == null) {
          final code = _generateSessionCode();
          ref.read(activeSessionProvider.notifier).state =
              currentSessionState.copyWith(
            sessionCode: code,
          );
          // Save fallback to Supabase
          if (user != null) {
            final activeSession = ActiveSession.fromConfig(
              currentSessionState.config,
              sessionCode: code,
              clinicianId: user.uid,
            );
            // A failure here means the child can never join this code; the
            // clinician needs to know rather than read out a dead code.
            try {
              await ref
                  .read(firestoreServiceProvider)
                  .createActiveSession(activeSession);
            } catch (e) {
              debugPrint('createActiveSession failed: $e');
              _warnSessionNotShared();
            }
          }
        }
      } else if (config != null) {
        final code = _generateSessionCode();
        ref.read(activeSessionProvider.notifier).state = ActiveSessionState(
          config: config,
          sessionCode: code,
          startTime: DateTime.now(),
        );
        // Save fallback to Supabase
        if (user != null) {
          final activeSession = ActiveSession.fromConfig(
            config,
            sessionCode: code,
            clinicianId: user.uid,
          );
          // A failure here means the child can never join this code; the
          // clinician needs to know rather than read out a dead code.
          try {
            await ref
                .read(firestoreServiceProvider)
                .createActiveSession(activeSession);
          } catch (e) {
            debugPrint('createActiveSession failed: $e');
            _warnSessionNotShared();
          }
        }
      }
    });

    // Elapsed time comes from a monotonic Stopwatch, not from subtracting
    // wall-clock times. Subtracting `DateTime.now()` meant that changing the
    // device clock or time zone mid-session made the timer jump — or run
    // negative, which then produced a negative stored duration.
    _sessionStopwatch.start();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedTime = _sessionStopwatch.elapsed);
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _feedbackAnimController.dispose();
    _tokenAnimController.dispose();
    _sessionTimer?.cancel();
    _sessionStopwatch.stop();
    super.dispose();
  }

  /// Warn that the child's own progress screens will not show this session.
  ///
  /// The session itself is still saved against the child record, so the
  /// clinician loses nothing — it is the child's view that stays empty.
  void _warnProgressNotLinked(bool columnMissing) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 9),
        content: Text(
          columnMissing
              ? 'Saved, but your database is missing the kid_user_id column, '
                  'so no child device can be linked. Run '
                  'supabase_setup_all.sql.'
              : "Saved, but this child's own device could not be linked — "
                  'their progress screen will stay empty. See Settings › Data '
                  'Diagnostics.',
        ),
      ),
    );
  }

  /// Tell the clinician the session code will not reach the child's device.
  void _warnSessionNotShared() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 6),
        content: Text(
          'This session could not be shared — the child will not be able to '
          'join with this code.'.tr(),
        ),
      ),
    );
  }

  void _onSmooth() {
    final state = ref.read(activeSessionProvider);
    if (state == null) return;

    final outcome = state.recordFluent();
    ref.read(activeSessionProvider.notifier).state = outcome.state;

    if (outcome.goalReached) {
      _confettiController.play();
      _showRewardScreen();
    }

    _showFeedbackOverlay(true);

    // Play audio
    final phrases = BilingualPhrases.feedback;
    final key = 'fluent_${Random().nextInt(5) + 1}';
    final phrase = BilingualPhrases.getPhrase(
      phrases,
      key,
      state.config.language,
    );
    ref.read(audioServiceProvider).playSmoothFeedback(
          phrase: phrase.isNotEmpty ? phrase : 'Wow, that was smooth speech!',
          languageCode: state.config.language,
          // Spoken instead if the device has no voice for the session
          // language: an English phrase the child can understand beats
          // Kannada text read by an English voice.
          fallbackPhrase: BilingualPhrases.getPhrase(phrases, key, 'en'),
        );

    // Sync to Firestore for dual-device
    _syncToFirestore();
  }

  void _onBumpy() {
    final state = ref.read(activeSessionProvider);
    if (state == null) return;

    ref.read(activeSessionProvider.notifier).state =
        state.recordDysfluent().state;

    _showFeedbackOverlay(false);

    // Play audio
    final phrases = BilingualPhrases.feedback;
    final key = 'dysfluent_${Random().nextInt(3) + 1}';
    final phrase = BilingualPhrases.getPhrase(
      phrases,
      key,
      state.config.language,
    );
    ref.read(audioServiceProvider).playBumpyFeedback(
          phrase: phrase.isNotEmpty ? phrase : 'Oh, that was a bumpy one! Try again!',
          languageCode: state.config.language,
          // Spoken instead if the device has no voice for the session
          // language: an English phrase the child can understand beats
          // Kannada text read by an English voice.
          fallbackPhrase: BilingualPhrases.getPhrase(phrases, key, 'en'),
        );

    _syncToFirestore();
  }

  void _showFeedbackOverlay(bool isSmooth) {
    setState(() {
      _showFeedback = true;
      _isSmoothFeedback = isSmooth;
      _feedbackMessage =
          isSmooth ? 'Smooth! ✨' : 'Bumpy! 🔄';
    });

    _feedbackAnimController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showFeedback = false);
      }
    });
  }

  void _showRewardScreen() {
    // The reward and its mini-game belong to the child. The clinician stays on
    // the session screen — they need the Smooth/Bumpy controls and the token
    // board while the child plays, and a full-screen game on the clinician's
    // device serves no clinical purpose.
    //
    // The flags below are what the child's device polls to open the reward.
    // The child clears them when they finish, so this side never navigates.
    final state = ref.read(activeSessionProvider);
    if (state?.sessionCode != null) {
      ref.read(firestoreServiceProvider).updateActiveSession(
        sessionCode: state!.sessionCode!,
        data: {
          'rewardActive': true,
          'miniGameActive': true,
          'currentTokenCount': 0,
          'rewardCyclesCompleted': state.rewardCycles,
        },
      );
    }

    ref.read(activeSessionProvider.notifier).state =
        ref.read(activeSessionProvider)?.copyWith(showingReward: false);

    // Tell the clinician what the child is seeing, since they no longer see it.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.smoothGreen,
          duration: const Duration(seconds: 4),
          content: Text(
            state?.config.rewardType == 'physicalReward'
                ? '🎁 Goal reached — hand ${state?.config.childName ?? 'the child'} '
                    'their reward'
                : '🎉 Reward sent to ${state?.config.childName ?? 'the child'}',
          ),
        ),
      );
    }
  }

  void _syncToFirestore() {
    final state = ref.read(activeSessionProvider);
    if (state?.sessionCode == null) return;

    ref.read(firestoreServiceProvider).updateActiveSession(
      sessionCode: state!.sessionCode!,
      data: {
        'currentTokenCount': state.currentTokens,
        'lastFeedbackType': state.lastFeedbackType,
        'lastFeedbackTime': DateTime.now(),
        'rewardCyclesCompleted': state.rewardCycles,
      },
    );
  }

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Session?'.tr()),
        content: Text(
          'Are you sure you want to end this therapy session? Session data will be saved.'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: Text('End Session'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Signal session completed to kid's device. Also clear the video flag so
      // a kid whose app reads this before the completed status still drops out
      // of the meeting rather than sitting in an abandoned call.
      final state = ref.read(activeSessionProvider);
      if (state?.sessionCode != null) {
        await ref.read(firestoreServiceProvider).updateActiveSession(
          sessionCode: state!.sessionCode!,
          data: {'status': 'completed', 'kidVideoStarted': false},
        );
      }

      // Leave the conference on this device too.
      await VideoCallService.leaveCall();
      try {
        await _saveSession();
      } catch (e) {
        // Never let a failed save look like a successful one — that is why
        // progress and history could silently stay empty.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 8),
              content: Text('Could not save this session: $e'),
            ),
          );
        }
        return;
      }
      if (mounted) {
        context.goNamed(AppRouter.sessionSummary);
      }
    }
  }

  Future<void> _saveSession() async {
    final user = ref.read(currentUserProvider);
    final state = ref.read(activeSessionProvider);
    if (user == null || state == null) return;

    // Attach the kid's login to this child before saving. Done here, with the
    // clinician's credentials, because the clinician owns the child row —
    // the kid's own attempt is refused whenever row-level security restricts
    // `children` to its owner, which left the kid's progress permanently empty.
    if (state.sessionCode != null) {
      // Every branch here used to fail silently — including simply finding no
      // kid id, which is what happens when `active_sessions.kid_user_id` does
      // not exist. The session saved, the clinician saw success, and the
      // child's progress screens stayed empty for good with nothing recorded
      // anywhere to say why.
      try {
        final active = await ref
            .read(firestoreServiceProvider)
            .fetchActiveSession(state.sessionCode!);
        final kidId = active?.kidUserId;

        if (kidId == null || kidId.isEmpty) {
          // Two very different situations produce a null id, and conflating
          // them is why this took several rounds to pin down.
          final columnMissing = active != null && !active.kidUserIdColumnPresent;
          final noDeviceJoined = active != null && active.kidUserIdColumnPresent;

          final String reason;
          if (columnMissing) {
            reason = 'active_sessions.kid_user_id does not exist in this '
                'database. Run supabase_setup_all.sql in the Supabase SQL '
                'editor; until then no child device can be linked.';
          } else if (noDeviceJoined) {
            reason = 'The column exists and is empty: no child device joined '
                'this session with the code. Nothing is wrong if you were '
                'testing alone.';
          } else {
            reason = 'The session row could not be read back at save time, so '
                'the child could not be linked.';
          }

          debugPrint('linkKidToChild skipped — $reason');
          CrashLog.record(
              columnMissing
                  ? 'Database missing kid_user_id column'
                  : noDeviceJoined
                      ? 'No child device joined this session'
                      : 'Kid not linked to child',
              StackTrace.fromString(reason));

          // A session the clinician ran alone is not a failure and must not be
          // reported as one — that warning appearing on every solo test is
          // what made the real problem hard to see.
          if (!noDeviceJoined) _warnProgressNotLinked(columnMissing);
        } else {
          await ref.read(firestoreServiceProvider).linkKidToChild(
                childId: state.config.childId,
                kidUserId: kidId,
              );
        }
      } catch (e, stack) {
        debugPrint('Linking kid to child on save failed: $e');
        CrashLog.record('Kid not linked to child: $e', stack);
        // A thrown error is never the missing-column case; that is detected
        // from the row itself above.
        _warnProgressNotLinked(false);
      }
    }

    // Same monotonic source as the on-screen timer, so a clock change
    // during the session cannot record a wrong or negative duration.
    final duration = _sessionStopwatch.elapsed;
    final stats = SessionStats.calculate(
      utterances: state.utterances,
      rewardCycles: state.rewardCycles,
      duration: duration,
    );

    final session = Session(
      id: '',
      childId: state.config.childId,
      clinicianId: user.uid,
      sessionNumber: state.config.sessionNumber,
      date: state.startTime,
      therapyLevel: state.config.therapyLevel,
      playTheme: state.config.playTheme,
      miniGame: state.config.miniGame,
      config: state.config,
      stats: stats,
    );

    final sessionId = await ref.read(firestoreServiceProvider).saveSession(
          clinicianId: user.uid,
          childId: state.config.childId,
          session: session,
        );

    // Save utterances
    if (state.utterances.isNotEmpty) {
      await ref.read(firestoreServiceProvider).saveUtterances(
            clinicianId: user.uid,
            childId: state.config.childId,
            sessionId: sessionId,
            utterances: state.utterances,
          );
    }

    // Clean up the active session — but only after a grace period.
    //
    // The kid's device discovers "session over" by polling this row every 2s
    // and reading status == completed. Deleting it right away almost always
    // wins that race, the poll returns null, and the kid is left stranded on
    // the session screen forever. Keep the completed row around long enough
    // for the kid to observe it.
    final code = state.sessionCode;
    if (code != null) {
      final service = ref.read(firestoreServiceProvider);
      Future.delayed(
        const Duration(seconds: 30),
        () => service.deleteActiveSession(code),
      );
    }
  }

  String _shortenLevel(String level) {
    switch (level) {
      case 'word': return 'Word';
      case 'sentence': return 'Sentence';
      case 'continuousSpeech': return 'Continuous';
      case 'narrative': return 'Narrative';
      case 'conversational': return 'Conversation';
      default: return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeSessionProvider);
    // Rebuild this screen when the interface language changes.
    ref.watch(appLanguageProvider);
    if (state == null) {
      return Scaffold(
        body: Center(child: Text('No active session'.tr())),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 750;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _endSession();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Main content
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8F6FF), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                  children: [
                    // ─── Top Bar ───
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Level Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth < 400 ? 8 : 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stairs_rounded,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  _shortenLevel(state.config.therapyLevel),
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: screenWidth < 400 ? 11 : 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
  
                          if (state.sessionCode != null) ...[
                            SizedBox(width: screenWidth < 400 ? 4 : 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth < 400 ? 8 : 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                screenWidth < 400
                                    ? '#${state.sessionCode}'
                                    : 'Code: ${state.sessionCode}',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: screenWidth < 400 ? 11 : 12,
                                ),
                              ),
                            ),
                          ],
  
                          const Spacer(),
  
                          // Timer
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth < 400 ? 8 : 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined,
                                    size: screenWidth < 400 ? 12 : 16,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(_elapsedTime),
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontSize: screenWidth < 400 ? 11 : 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
  
                          if (state.sessionCode != null) ...[
                            SizedBox(width: screenWidth < 400 ? 2 : 8),
                            IconButton(
                              onPressed: () => setState(
                                  () => _showEmbeddedVideoCall = !_showEmbeddedVideoCall),
                              icon: Icon(_showEmbeddedVideoCall
                                  ? Icons.videocam_rounded
                                  : Icons.videocam_outlined),
                              color: _showEmbeddedVideoCall
                                  ? AppColors.primary
                                  : AppColors.textHint,
                              iconSize: screenWidth < 400 ? 22 : 28,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Toggle Video Call'.tr(),
                            ),
                          ],
  
                          SizedBox(width: screenWidth < 400 ? 6 : 8),
  
                          // End Session
                          IconButton(
                            onPressed: _endSession,
                            icon: const Icon(Icons.stop_circle_outlined),
                            color: AppColors.secondary,
                            iconSize: screenWidth < 400 ? 24 : 28,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'end_session'.tr(),
                          ),
                        ],
                      ),
                    ),

                  // ─── Child Info ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      state.config.childName,
                      style: AppTextStyles.headlineMedium,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ─── Interactive Theme Token Board ───
                  SizedBox(
                    height: isSmallScreen ? 180 : 240,
                    child: ThemeTokenBoardWidget(
                      theme: PlayTheme.values.firstWhere(
                        (t) => t.name == state.config.playTheme,
                        orElse: () => PlayTheme.diyaFestival,
                      ),
                      currentTokens: state.currentTokens,
                      tokenGoal: state.config.tokenGoal,
                    ),
                  ),

                  // ─── Stats Row ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatPill(
                          'Fluent Word',
                          '${state.utterances.where((u) => u.type == UtteranceType.fluent).length}',
                          AppColors.smoothGreen,
                        ),
                        _buildStatPill(
                          'Stuttered Word',
                          '${state.utterances.where((u) => u.type == UtteranceType.dysfluent).length}',
                          AppColors.bumpyOrange,
                        ),
                        _buildStatPill(
                          'Total',
                          '${state.utterances.length}',
                          AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  // ─── Embedded Video Call (inline, below token board) ───
                  //
                  // Collapsed for in-person ("offline") sessions: the panel is
                  // replaced by a slim bar rather than left as dead space, so
                  // the token board and Smooth/Bumpy controls get the room.
                  // The tall video panel appears only once a call is actually
                  // running. Before that — an in-person ("offline") session, or
                  // before the clinician starts video — it collapses to this
                  // one-line bar. The old behaviour rendered a 180px dark
                  // "Join Video Call" card at all times, which wasted the space
                  // an in-person session needs and clipped its own button.
                  if (state.sessionCode != null &&
                      (!_showEmbeddedVideoCall || !_kidVideoStarted))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: InkWell(
                        onTap: () {
                          // Tapping the bar starts the call for both sides.
                          setState(() {
                            _showEmbeddedVideoCall = true;
                            _kidVideoStarted = true;
                          });
                          _setKidCallFlag('kidVideoStarted', true);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.videocam_off_rounded,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _showEmbeddedVideoCall
                                      ? 'Video call not started'.tr()
                                      : 'In-person session — video off'.tr(),
                                  style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ),
                              Text(
                                'Start'.tr(),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (_showEmbeddedVideoCall &&
                      _kidVideoStarted &&
                      state.sessionCode != null) ...[
                    Container(
                      height: isSmallScreen ? 130 : 180,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: EmbeddedVideoCallWidget(
                          // This screen rebuilds every second for the session
                          // timer; the key keeps the call State alive across
                          // those rebuilds instead of restarting the call.
                          key: ValueKey('call-${state.sessionCode}'),
                          sessionCode: state.sessionCode!,
                          userName: 'Clinician',
                          isClinician: true,
                          // Starting the kid's video puts the clinician in the
                          // same room at the same time.
                          autoJoin: _kidVideoStarted,
                        ),
                      ),
                    ),
                    _buildKidCallControls(),
                  ],

                  const SizedBox(height: 12),

                  // ─── Smooth / Bumpy Buttons ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // SMOOTH button
                        Expanded(
                          child: GestureDetector(
                            onTap: _onSmooth,
                            child: Container(
                              height: isSmallScreen ? 72 : 90,
                              decoration: BoxDecoration(
                                gradient: AppColors.smoothGradient,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.smoothGreen
                                        .withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: isSmallScreen ? 26 : 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'smooth'.tr(),
                                    style:
                                        AppTextStyles.buttonText.copyWith(
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                                  Text(
                                    '+${state.config.tokensPerFluent} token',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // BUMPY button
                        Expanded(
                          child: GestureDetector(
                            onTap: _onBumpy,
                            child: Container(
                              height: isSmallScreen ? 72 : 90,
                              decoration: BoxDecoration(
                                gradient: AppColors.bumpyGradient,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.bumpyOrange
                                        .withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.replay_circle_filled_rounded,
                                    color: Colors.white,
                                    size: isSmallScreen ? 26 : 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'bumpy'.tr(),
                                    style:
                                        AppTextStyles.buttonText.copyWith(
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                                  Text(
                                    '-${state.config.tokensPerDysfluent} token',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
                    ),
                  ),
                ),
              ),
            ),

          // ─── Feedback Overlay ───
          if (_showFeedback)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showFeedback ? 1 : 0,
                  child: Container(
                    color: (_isSmoothFeedback
                            ? AppColors.smoothGreen
                            : AppColors.bumpyOrange)
                        .withValues(alpha: 0.15),
                    child: Center(
                      child: Text(
                        _feedbackMessage ?? '',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: _isSmoothFeedback
                              ? AppColors.smoothGreenDark
                              : AppColors.bumpyOrangeDark,
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1, 1),
                            duration: 400.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: 200.ms),
                    ),
                  ),
                ),
              ),
            ),

          // ─── Confetti ───
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              colors: const [
                AppColors.tokenGold,
                AppColors.primary,
                AppColors.secondary,
                AppColors.accent,
                AppColors.smoothGreen,
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  /// Clinician-only controls over the kid's device.
  ///
  /// These write flags to the shared session row; the kid's app polls them and
  /// applies them to its own Jitsi client. Doing it cooperatively avoids
  /// needing real moderator rights, which the public server will not grant.
  Widget _buildKidCallControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _kidControlButton(
              icon: _kidVideoStarted
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline_rounded,
              label: _kidVideoStarted ? 'Stop video call' : 'Start video call',
              active: _kidVideoStarted,
              onTap: () {
                setState(() => _kidVideoStarted = !_kidVideoStarted);
                _setKidCallFlag('kidVideoStarted', _kidVideoStarted);
              },
            ),
          ),
          const SizedBox(width: 8),
          _kidControlButton(
            icon: _kidAudioMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: _kidAudioMuted ? 'Unmute' : 'Mute',
            active: _kidAudioMuted,
            onTap: () {
              setState(() => _kidAudioMuted = !_kidAudioMuted);
              _setKidCallFlag('kidAudioMuted', _kidAudioMuted);
            },
          ),
          const SizedBox(width: 8),
          _kidControlButton(
            icon: _kidVideoMuted
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            label: _kidVideoMuted ? 'Cam on' : 'Cam off',
            active: _kidVideoMuted,
            onTap: () {
              setState(() => _kidVideoMuted = !_kidVideoMuted);
              _setKidCallFlag('kidVideoMuted', _kidVideoMuted);
            },
          ),
        ],
      ),
    );
  }

  Widget _kidControlButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final color = active ? AppColors.secondary : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
