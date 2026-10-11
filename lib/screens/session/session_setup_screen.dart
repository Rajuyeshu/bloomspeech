import 'dart:math';
import '../../utils/app_localizations.dart';
import '../../services/language_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/routes/app_router.dart';
import '../../config/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/child_profile.dart';
import '../../models/session.dart';

/// Providers to hold session configuration state
final sessionConfigProvider = StateProvider<SessionConfig?>((ref) => null);

class SessionSetupScreen extends ConsumerStatefulWidget {
  final String childId;
  const SessionSetupScreen({super.key, required this.childId});

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  ChildProfile? _child;
  bool _isLoading = true;

  // Config values
  TherapyLevel _level = TherapyLevel.continuousSpeech;
  int _tokensPerFluent = AppConstants.defaultTokensPerFluent;
  int _tokensPerDysfluent = AppConstants.defaultTokensPerDysfluent;
  int _tokenGoal = AppConstants.maxTokenGoal; // 30 tokens default as requested
  RewardType _rewardType = RewardType.inAppMiniGame;
  MiniGameType _miniGame = MiniGameType.bubbleBurst;
  String _physicalReward = 'Sticker ⭐️';
  int _sessionTimer = 30; // 30min default as in sample mockup
  int _sessionNumber = 1;

  final List<String> _physicalRewardOptions = [
    'Sticker ⭐️',
    'Star Stamp 🌟',
    'Pencil Top ✏️',
    'Toy Badge 🏅',
    'Extra Play Time ⏰',
  ];

  @override
  void initState() {
    super.initState();
    _loadChild();
  }

  Future<void> _loadChild() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final child = await ref.read(firestoreServiceProvider).getChild(
          clinicianId: user.uid,
          childId: widget.childId,
        );

    final sessionCount = await ref.read(firestoreServiceProvider).getSessionCount(
          clinicianId: user.uid,
          childId: widget.childId,
        );

    if (mounted && child != null) {
      setState(() {
        _child = child;
        _sessionNumber = sessionCount + 1;
        _level = TherapyLevel.values.firstWhere(
          (l) => l.name == child.currentLevel,
          orElse: () => TherapyLevel.continuousSpeech,
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _proceedToThemeSelection() async {
    if (_child == null) return;

    final config = SessionConfig(
      childId: widget.childId,
      childName: _child!.name,
      sessionNumber: _sessionNumber,
      therapyLevel: _level.name,
      tokensPerFluent: _tokensPerFluent,
      tokensPerDysfluent: _tokensPerDysfluent,
      tokenGoal: _tokenGoal,
      rewardType: _rewardType.name,
      miniGame: _miniGame.name,
      sessionTimerMinutes: _sessionTimer,
      physicalReward: _rewardType == RewardType.physicalReward ? _physicalReward : null,
      playTheme: PlayTheme.initial.name,
      // The session carries the interface language so the child hears feedback
      // in the language of the therapy. Omitting it left SessionConfig on its
      // 'en' default, so switching the app to Kannada changed every label but
      // the spoken phrases stayed English.
      language: ref.read(appLanguageProvider).code,
    );

    // Save config in provider
    ref.read(sessionConfigProvider.notifier).state = config;

    if (mounted) {
      context.pushNamed(AppRouter.themeSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the interface language changes.
    ref.watch(appLanguageProvider);
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Session Setup'.tr(),
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D3142),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRouter.home);
            }
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF2D3142),
            size: 26,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Treatment Level Section ───
            _buildSectionHeader('treatment_level'.tr()),
            const SizedBox(height: 12),
            _buildTreatmentLevelGrid(),
            const SizedBox(height: 12),

            const SizedBox(height: 24),

            // ─── Token Configuration Card ───
            _buildSectionHeader('Token Configuration'),
            const SizedBox(height: 12),
            _buildTokenConfigurationCard(),

            const SizedBox(height: 24),

            // ─── Reward Type Section ───
            _buildSectionHeader('reward_type'.tr()),
            const SizedBox(height: 12),
            _buildRewardTypeCard(),

            const SizedBox(height: 24),

            // ─── Session Duration Alert ───
            _buildSectionHeader('Session Duration Alert'),
            const SizedBox(height: 12),
            _buildSessionDurationSelector(),

            const SizedBox(height: 36),

            // ─── Choose Theme CTA Button ───
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _proceedToThemeSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Choose Theme'.tr(),
                      style: AppTextStyles.buttonText.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 22),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF5E6472),
      ),
    );
  }

  // ─── Treatment Level Grid ───
  Widget _buildTreatmentLevelGrid() {
    // The four current levels. Hardcoding the list meant the retired sentence
    // level kept appearing here after it was withdrawn.
    final levels = TherapyLevel.selectable;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: levels.map((lvl) {
        final isSelected = _level == lvl;
        return GestureDetector(
          onTap: () => setState(() => _level = lvl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Text(
              lvl.displayName,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF4A5568),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  // ─── Token Configuration Card ───
  Widget _buildTokenConfigurationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        children: [
          // Fluent award (+)
          _buildCounterRow(
            label: 'Fluent award (+)'.tr(),
            value: _tokensPerFluent,
            minValue: AppConstants.minTokensPerFluent,
            maxValue: AppConstants.maxTokensPerFluent,
            onDecrement: () {
              if (_tokensPerFluent > AppConstants.minTokensPerFluent) {
                setState(() => _tokensPerFluent--);
              }
            },
            onIncrement: () {
              if (_tokensPerFluent < AppConstants.maxTokensPerFluent) {
                setState(() => _tokensPerFluent++);
              }
            },
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFEDF2F7)),

          // Dysfluent cost (-)
          _buildCounterRow(
            label: 'Dysfluent cost (-)'.tr(),
            value: _tokensPerDysfluent,
            minValue: AppConstants.minTokensPerDysfluent,
            maxValue: AppConstants.maxTokensPerDysfluent,
            onDecrement: () {
              if (_tokensPerDysfluent > AppConstants.minTokensPerDysfluent) {
                setState(() => _tokensPerDysfluent--);
              }
            },
            onIncrement: () {
              if (_tokensPerDysfluent < AppConstants.maxTokensPerDysfluent) {
                setState(() => _tokensPerDysfluent++);
              }
            },
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFEDF2F7)),

          // Token goal
          _buildCounterRow(
            label: 'Token goal'.tr(),
            value: _tokenGoal,
            minValue: AppConstants.minTokenGoal,
            maxValue: AppConstants.maxTokenGoal,
            onDecrement: () {
              if (_tokenGoal > AppConstants.minTokenGoal) {
                setState(() => _tokenGoal = max(AppConstants.minTokenGoal, _tokenGoal - 1));
              }
            },
            onIncrement: () {
              if (_tokenGoal < AppConstants.maxTokenGoal) {
                setState(() => _tokenGoal = min(AppConstants.maxTokenGoal, _tokenGoal + 1));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCounterRow({
    required String label,
    required int value,
    required int minValue,
    required int maxValue,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    final canDecrement = value > minValue;
    final canIncrement = value < maxValue;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3142),
          ),
        ),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrement Button
              InkWell(
                onTap: canDecrement ? onDecrement : null,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: canDecrement ? Colors.white : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: canDecrement
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    color: canDecrement
                        ? const Color(0xFF4A5568)
                        : const Color(0xFFCBD5E0),
                    size: 20,
                  ),
                ),
              ),

              // Value Display
              Container(
                constraints: const BoxConstraints(minWidth: 44),
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D3142),
                  ),
                ),
              ),

              // Increment Button
              InkWell(
                onTap: canIncrement ? onIncrement : null,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: canIncrement ? Colors.white : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: canIncrement
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: canIncrement
                        ? const Color(0xFF4A5568)
                        : const Color(0xFFCBD5E0),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Reward Type Card ───
  Widget _buildRewardTypeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        children: [
          // Radio Option 1: In-app animation
          _buildRewardRadioTile(
            type: RewardType.inAppAnimation,
            title: 'In-app animation'.tr(),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),

          // Radio Option 2: In-app mini-game
          _buildRewardRadioTile(
            type: RewardType.inAppMiniGame,
            title: 'In-app mini-game'.tr(),
          ),
          if (_rewardType == RewardType.inAppMiniGame) ...[
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: MiniGameType.selectable.map((game) {
                  final isSelected = _miniGame == game;
                  return GestureDetector(
                    onTap: () => setState(() => _miniGame = game),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(game.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game.displayName,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : const Color(0xFF2D3142),
                                  ),
                                ),
                                Text(
                                  game.description,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFF718096),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),

          // Radio Option 3: Physical reward
          _buildRewardRadioTile(
            type: RewardType.physicalReward,
            title: 'Physical reward'.tr(),
          ),
          if (_rewardType == RewardType.physicalReward) ...[
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 16, bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _physicalRewardOptions.map((opt) {
                  final isSelected = _physicalReward == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _physicalReward = opt),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundColor: const Color(0xFFF7FAFC),
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: isSelected ? AppColors.primary : const Color(0xFF4A5568),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardRadioTile({
    required RewardType type,
    required String title,
  }) {
    final isSelected = _rewardType == type;

    return InkWell(
      onTap: () => setState(() => _rewardType = type),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFA0AEC0),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: const Color(0xFF2D3142),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Session Duration Alert Selector ───
  Widget _buildSessionDurationSelector() {
    final options = AppConstants.sessionTimerOptions; // [0, 20, 30, 45]

    return Wrap(
      spacing: 10,
      children: options.map((mins) {
        final isSelected = _sessionTimer == mins;
        final label = mins == 0 ? 'Off' : '${mins}min';

        return GestureDetector(
          onTap: () => setState(() => _sessionTimer = mins),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.primary : const Color(0xFF4A5568),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
