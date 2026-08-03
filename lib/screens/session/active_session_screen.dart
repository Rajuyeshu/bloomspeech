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
import '../../services/firestore_service.dart';
import '../../services/audio_service.dart';
import '../../models/session.dart';
import '../../utils/bilingual_phrases.dart';
import '../../widgets/embedded_video_call.dart';
import '../../widgets/theme_token_board.dart';
import 'session_setup_screen.dart';

/// Active session state
final activeSessionProvider = StateProvider<ActiveSessionState?>((ref) => null);

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
  Duration _elapsedTime = Duration.zero;
  String? _feedbackMessage;
  bool _showFeedback = false;
  bool _isSmoothFeedback = true;
  bool _showEmbeddedVideoCall = true;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(sessionConfigProvider);
      final currentSessionState = ref.read(activeSessionProvider);

      if (currentSessionState != null) {
        if (currentSessionState.sessionCode == null) {
          ref.read(activeSessionProvider.notifier).state =
              currentSessionState.copyWith(
            sessionCode: _generateSessionCode(),
          );
        }
      } else if (config != null) {
        ref.read(activeSessionProvider.notifier).state = ActiveSessionState(
          config: config,
          sessionCode: _generateSessionCode(),
          startTime: DateTime.now(),
        );
      }
    });

    // Start elapsed time timer
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(
              ref.read(activeSessionProvider)?.startTime ?? DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _feedbackAnimController.dispose();
    _tokenAnimController.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _onSmooth() {
    final state = ref.read(activeSessionProvider);
    if (state == null) return;

    final newTokens =
        state.currentTokens + state.config.tokensPerFluent;
    final utterance = Utterance(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: UtteranceType.fluent,
      tokenCountAfter: newTokens,
    );

    final newUtterances = [...state.utterances, utterance];

    // Check if goal reached
    if (newTokens >= state.config.tokenGoal) {
      // Reward!
      _confettiController.play();
      ref.read(activeSessionProvider.notifier).state = state.copyWith(
        currentTokens: 0,
        utterances: newUtterances,
        rewardCycles: state.rewardCycles + 1,
        showingReward: true,
        lastFeedbackType: 'fluent',
      );
      _showRewardScreen();
    } else {
      ref.read(activeSessionProvider.notifier).state = state.copyWith(
        currentTokens: newTokens,
        utterances: newUtterances,
        lastFeedbackType: 'fluent',
      );
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
          phrase: phrase.isNotEmpty
              ? phrase
              : 'Wow, that was smooth speech!',
          languageCode: state.config.language,
        );

    // Sync to Firestore for dual-device
    _syncToFirestore();
  }

  void _onBumpy() {
    final state = ref.read(activeSessionProvider);
    if (state == null) return;

    final newTokens = max(0, state.currentTokens - state.config.tokensPerDysfluent);
    final utterance = Utterance(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: UtteranceType.dysfluent,
      tokenCountAfter: newTokens,
    );

    ref.read(activeSessionProvider.notifier).state = state.copyWith(
      currentTokens: newTokens,
      utterances: [...state.utterances, utterance],
      lastFeedbackType: 'dysfluent',
    );

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
          phrase: phrase.isNotEmpty
              ? phrase
              : 'Oh, that was a bumpy one! Try again!',
          languageCode: state.config.language,
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
    // Navigate to reward screen after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.pushNamed(AppRouter.reward);
      }
    });
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
        title: const Text('End Session?'),
        content: const Text(
          'Are you sure you want to end this therapy session? Session data will be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _saveSession();
      if (mounted) {
        context.goNamed(AppRouter.sessionSummary);
      }
    }
  }

  Future<void> _saveSession() async {
    final user = ref.read(currentUserProvider);
    final state = ref.read(activeSessionProvider);
    if (user == null || state == null) return;

    final duration = DateTime.now().difference(state.startTime);
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

    // Clean up active session
    if (state.sessionCode != null) {
      await ref
          .read(firestoreServiceProvider)
          .deleteActiveSession(state.sessionCode!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeSessionProvider);
    if (state == null) {
      return const Scaffold(
        body: Center(child: Text('No active session')),
      );
    }

    final progress = state.config.tokenGoal > 0
        ? state.currentTokens / state.config.tokenGoal
        : 0.0;

    return Scaffold(
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
              child: Column(
                children: [
                  // ─── Top Bar ───
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Level Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
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
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                state.config.therapyLevel,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (state.sessionCode != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Code: ${state.sessionCode}',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Timer
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(_elapsedTime),
                                style: AppTextStyles.labelMedium,
                              ),
                            ],
                          ),
                        ),

                        if (state.sessionCode != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => setState(
                                () => _showEmbeddedVideoCall = !_showEmbeddedVideoCall),
                            icon: Icon(_showEmbeddedVideoCall
                                ? Icons.videocam_rounded
                                : Icons.videocam_outlined),
                            color: _showEmbeddedVideoCall
                                ? AppColors.primary
                                : AppColors.textHint,
                            iconSize: 28,
                            tooltip: 'Toggle Video Call',
                          ),
                        ],

                        const SizedBox(width: 8),

                        // End Session
                        IconButton(
                          onPressed: _endSession,
                          icon: const Icon(Icons.stop_circle_outlined),
                          color: AppColors.secondary,
                          iconSize: 28,
                          tooltip: 'End Session',
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
                  Expanded(
                    flex: _showEmbeddedVideoCall ? 3 : 5,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatPill(
                          'Fluent',
                          '${state.utterances.where((u) => u.type == UtteranceType.fluent).length}',
                          AppColors.smoothGreen,
                        ),
                        _buildStatPill(
                          'Bumpy',
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

                  const SizedBox(height: 12),

                  // ─── Embedded Video Call (inline, below token board) ───
                  if (_showEmbeddedVideoCall && state.sessionCode != null)
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: EmbeddedVideoCallWidget(
                            sessionCode: state.sessionCode!,
                            userName: 'Clinician',
                            isClinician: true,
                          ),
                        ),
                      ),
                    ),

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
                              height: 90,
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
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Smooth',
                                    style:
                                        AppTextStyles.buttonText.copyWith(
                                      fontSize: 16,
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
                              height: 90,
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
                                  const Icon(
                                    Icons.replay_circle_filled_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bumpy',
                                    style:
                                        AppTextStyles.buttonText.copyWith(
                                      fontSize: 16,
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
