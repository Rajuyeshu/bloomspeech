import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/theme/app_theme.dart';
import '../../config/constants/app_constants.dart';
import '../../services/language_service.dart';
import '../../utils/app_localizations.dart';
import '../../services/video_call_service.dart';

// ═══════════════════════════════════════════════════════════════
// 1. CHILD SELECTION SCREEN (Clinician picks or adds a child)
// ═══════════════════════════════════════════════════════════════
class PreviewChildSelectionScreen extends ConsumerStatefulWidget {
  const PreviewChildSelectionScreen({super.key});

  @override
  ConsumerState<PreviewChildSelectionScreen> createState() =>
      _PreviewChildSelectionScreenState();
}

class _PreviewChildSelectionScreenState
    extends ConsumerState<PreviewChildSelectionScreen> {
  int? _selectedIndex;

  // Mock children
  final _mockChildren = [
    _MockChild('Aarav', 7, 'Word', 12, 78.5, '🧒'),
    _MockChild('Priya', 5, 'Sentence', 8, 65.2, '👧'),
    _MockChild('Karthik', 9, 'Narrative', 22, 88.1, '🧑'),
    _MockChild('Meera', 6, 'Word', 4, 52.3, '👧'),
  ];

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final isKn = language == AppLanguage.kannada;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('select_child'.tr(language)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            Text(
              'who_is_session_for'.tr(language),
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              isKn
                  ? 'ಹೊಸ ಅಥವಾ ಈಗಾಗಲೇ ಇರುವ ಮಗುವನ್ನು ಆರಿಸಿ'
                  : 'Select an existing child or add a new one',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // ─── Add New Child Card ───
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PreviewAddChildScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'add_new_child'.tr(language),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'register_new_patient'.tr(language),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 28),

            // ─── Existing Children ───
            Text(
              'existing_children'.tr(language),
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              isKn
                  ? '${_mockChildren.length} ನೋಂದಾಯಿಸಲಾಗಿದೆ'
                  : '${_mockChildren.length} registered',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 14),

            ...List.generate(_mockChildren.length, (index) {
              final child = _mockChildren[index];
              final isSelected = _selectedIndex == index;
              final levelColor = _getLevelColor(child.level);

              return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textHint.withValues(alpha: 0.1),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected ? AppTheme.cardShadow : null,
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: levelColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                child.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      child.name,
                                      style: AppTextStyles.titleMedium,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isKn
                                          ? '${child.age} ವರ್ಷ'
                                          : '${child.age}y',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildTag(
                                      isKn
                                          ? (child.level == 'Word'
                                                ? 'ಪದ'
                                                : child.level == 'Sentence'
                                                ? 'ವಾಕ್ಯ'
                                                : child.level == 'Narrative'
                                                ? 'ಕಥೆ'
                                                : child.level)
                                          : child.level,
                                      levelColor,
                                    ),
                                    const SizedBox(width: 6),
                                    _buildTag(
                                      isKn
                                          ? '${child.sessions} ಸೆಷನ್‌ಗಳು'
                                          : '${child.sessions} sessions',
                                      AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Fluency
                          Column(
                            children: [
                              Text(
                                '${child.fluency.toStringAsFixed(0)}%',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: child.fluency >= 80
                                      ? AppColors.success
                                      : child.fluency >= 50
                                      ? AppColors.warning
                                      : AppColors.error,
                                ),
                              ),
                              Text(
                                isKn ? 'ಸರಾಗತೆ' : 'fluency',
                                style: AppTextStyles.labelSmall,
                              ),
                            ],
                          ),

                          if (isSelected) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 200 + index * 100),
                    duration: 500.ms,
                  )
                  .slideX(begin: 0.05, end: 0);
            }),

            const SizedBox(height: 24),

            // ─── Start Session Button ───
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _selectedIndex != null
                    ? () {
                        final child = _mockChildren[_selectedIndex!];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PreviewSessionSetupScreen(
                              childName: child.name,
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: Text(
                  _selectedIndex != null
                      ? '${'start_session_with'.tr(language)} ${_mockChildren[_selectedIndex!].name}'
                      : isKn
                      ? 'ಮುಂದುವರೆಯಲು ಮಗುವನ್ನು ಆರಿಸಿ'
                      : 'Select a child to continue',
                  style: AppTextStyles.buttonText,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.textHint.withValues(
                    alpha: 0.15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Word':
        return AppColors.levelWord;
      case 'Sentence':
        return AppColors.levelSentence;
      case 'Continuous':
        return AppColors.levelContinuous;
      case 'Narrative':
        return AppColors.levelNarrative;
      case 'Conversational':
        return AppColors.levelConversational;
      default:
        return AppColors.primary;
    }
  }
}

class _MockChild {
  final String name;
  final int age;
  final String level;
  final int sessions;
  final double fluency;
  final String emoji;
  _MockChild(
    this.name,
    this.age,
    this.level,
    this.sessions,
    this.fluency,
    this.emoji,
  );
}

// ═══════════════════════════════════════════════════════════════
// 2. ADD CHILD SCREEN (Preview)
// ═══════════════════════════════════════════════════════════════
class PreviewAddChildScreen extends ConsumerStatefulWidget {
  const PreviewAddChildScreen({super.key});

  @override
  ConsumerState<PreviewAddChildScreen> createState() =>
      _PreviewAddChildScreenState();
}

class _PreviewAddChildScreenState extends ConsumerState<PreviewAddChildScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = 'Male';
  DateTime? _selectedDob;
  String _selectedLanguage = 'English';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final isKn = language == AppLanguage.kannada;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('add_new_child'.tr(language)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Profile Photo ───
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.warmGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.child_care_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ─── Name ───
            Text('child_name'.tr(language), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecor(
                isKn
                    ? 'ಮಗುವಿನ ಪೂರ್ಣ ಹೆಸರನ್ನು ನಮೂದಿಸಿ'
                    : 'Enter child\'s full name',
                Icons.person_outline,
              ),
            ),

            const SizedBox(height: 18),

            // ─── Date of Birth ───
            Text('dob'.tr(language), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2019),
                  firstDate: DateTime(2010),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDob = date);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.textHint.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDob != null
                          ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}'
                          : isKn
                          ? 'ಹುಟ್ಟಿದ ದಿನಾಂಕವನ್ನು ಆರಿಸಿ'
                          : 'Select date of birth',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _selectedDob != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ─── Gender ───
            Text('gender'.tr(language), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: ['Male', 'Female', 'Other'].map((gender) {
                final isSelected = _selectedGender == gender;
                final displayGender = isKn
                    ? (gender == 'Male'
                          ? 'ಗಂಡು'
                          : gender == 'Female'
                          ? 'ಹೆಣ್ಣು'
                          : 'ಇತರೆ')
                    : gender;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = gender),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: gender != 'Other' ? 10 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textHint.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              gender == 'Male'
                                  ? '👦'
                                  : gender == 'Female'
                                  ? '👧'
                                  : '🧒',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              displayGender,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // ─── Language Preference ───
            Text('language_pref'.tr(language), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: ['English', 'Kannada'].map((lang) {
                final isSelected = _selectedLanguage == lang;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedLanguage = lang),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: lang != 'Kannada' ? 10 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.textHint.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          lang == 'English' ? '🇬🇧 English' : '🇮🇳 ಕನ್ನಡ',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // ─── Notes ───
            Text(
              'notes'.tr(language) + (isKn ? ' (ಐಚ್ಛಿಕ)' : ' (Optional)'),
              style: AppTextStyles.labelLarge,
            ),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 3,
              decoration: _inputDecor(
                isKn
                    ? 'ಮಗುವಿನ ಬಗ್ಗೆ ಯಾವುದೇ ಹೆಚ್ಚುವರಿ ಟಿಪ್ಪಣಿಗಳು...'
                    : 'Any additional notes about the child...',
                Icons.notes_rounded,
              ),
            ),

            const SizedBox(height: 32),

            // ─── Save Button ───
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isKn
                            ? 'ಮಗುವಿನ ವಿವರಗಳನ್ನು ಸೇರಿಸಲಾಗಿದೆ!'
                            : 'Child added! (Preview mode)',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  isKn ? 'ಮಗುವಿನ ವಿವರ ಉಳಿಸಿ' : 'Save Child',
                  style: AppTextStyles.buttonText,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.textHint.withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.textHint.withValues(alpha: 0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. SESSION SETUP — Treatment Level, Token config, Rewards
// ═══════════════════════════════════════════════════════════════
class PreviewSessionSetupScreen extends ConsumerStatefulWidget {
  final String childName;
  const PreviewSessionSetupScreen({super.key, this.childName = 'Aarav'});

  @override
  ConsumerState<PreviewSessionSetupScreen> createState() =>
      _PreviewSessionSetupScreenState();
}

class _PreviewSessionSetupScreenState
    extends ConsumerState<PreviewSessionSetupScreen> {
  TherapyLevel _selectedLevel = TherapyLevel.word;
  int _tokensRequired = 5;
  PlayTheme _selectedTheme = PlayTheme.diyaFestival;
  MiniGameType _selectedReward = MiniGameType.bubbleBurst;
  bool _timerEnabled = true;
  int _timerMinutes = 20;
  bool _dualDevice = false;

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final isKn = language == AppLanguage.kannada;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isKn
              ? '${widget.childName} ಅವರ ಸೆಷನ್'
              : 'Session for ${widget.childName}',
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Child info ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🧒', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.childName,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isKn
                              ? 'ಕೊನೆಯ ಸೆಷನ್: ೨ ದಿನಗಳ ಹಿಂದೆ'
                              : 'Last session: 2 days ago',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // ═══ TREATMENT LEVEL ═══
            _buildSectionHeader(
              '📊 ' + 'treatment_level'.tr(language),
              'select_speech_complexity'.tr(language),
            ),
            const SizedBox(height: 12),
            ...TherapyLevel.values.map((level) {
              final isSelected = _selectedLevel == level;
              final levelColor = _getLevelColor(level);
              final displayLevelName = isKn
                  ? (level == TherapyLevel.word
                        ? 'ಪದ ಮಟ್ಟ'
                        : level == TherapyLevel.sentence
                        ? 'ವಾಕ್ಯ ಮಟ್ಟ'
                        : level == TherapyLevel.continuousSpeech
                        ? 'ನಿರಂತರ ಮಾತು'
                        : level == TherapyLevel.narrative
                        ? 'ಕಥೆ ಹೇಳುವುದು'
                        : 'ಸಂಭಾಷಣೆ')
                  : level.displayName;

              final displayLevelDesc = isKn
                  ? (level == TherapyLevel.word
                        ? 'ಒಂದೇ ಗುರಿ ಪದಗಳು'
                        : level == TherapyLevel.sentence
                        ? 'ಸರಾಗವಾಗಿ ಹೇಳುವ ಚಿಕ್ಕ ವಾಕ್ಯಗಳು'
                        : level == TherapyLevel.continuousSpeech
                        ? '೨-೪ ಸಣ್ಣ ವಾಕ್ಯಗಳ ಮಾತು'
                        : level == TherapyLevel.narrative
                        ? 'ಕಥೆಗಳ ಮೂಲಕ ಮಾತು ಕಲಿಕೆ'
                        : 'ಮುಖಾಮುಖಿ ಮಾತುಕತೆ ಸಂಭಾಷಣೆ')
                  : level.description;

              return GestureDetector(
                onTap: () => setState(() => _selectedLevel = level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? levelColor.withValues(alpha: 0.1)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? levelColor
                          : AppColors.textHint.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${level.levelNumber}',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: levelColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayLevelName,
                              style: AppTextStyles.titleSmall,
                            ),
                            Text(
                              displayLevelDesc,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: levelColor,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // ═══ TOKEN BOARD CONFIG ═══
            _buildSectionHeader(
              '🎯 ' + 'token_board'.tr(language),
              isKn
                  ? 'ಬಹುಮಾನಕ್ಕಾಗಿ ಬೇಕಾದ ನಕ್ಷತ್ರಗಳು'
                  : 'Tokens needed for reward',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTokenButton(Icons.remove_rounded, () {
                        if (_tokensRequired > 3) {
                          setState(() => _tokensRequired--);
                        }
                      }),
                      const SizedBox(width: 24),
                      Text(
                        '$_tokensRequired',
                        style: AppTextStyles.displaySmall.copyWith(
                          color: AppColors.tokenGold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 24),
                      _buildTokenButton(Icons.add_rounded, () {
                        if (_tokensRequired < 10) {
                          setState(() => _tokensRequired++);
                        }
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'tokens_to_earn_reward'.tr(language),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Token preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_tokensRequired, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Icon(
                          Icons.star_rounded,
                          size: _tokensRequired > 7 ? 22 : 28,
                          color: i < 3
                              ? AppColors.tokenGold
                              : AppColors.tokenGold.withValues(alpha: 0.2),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ═══ PLAY THEME ═══
            _buildSectionHeader(
              '🎨 ' + 'play_theme'.tr(language),
              'theme_subtitle'.tr(language),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: PlayTheme.values.length,
                itemBuilder: (context, index) {
                  final theme = PlayTheme.values[index];
                  final isSelected = _selectedTheme == theme;
                  final displayThemeName = isKn
                      ? (theme == PlayTheme.diyaFestival
                            ? 'ದೀಪಾವಳಿ'
                            : theme == PlayTheme.rangoliBuilder
                            ? 'ರಂಗೋಲಿ'
                            : theme == PlayTheme.mangoHarvest
                            ? 'ಮಾವಿನ ಹಣ್ಣು'
                            : theme == PlayTheme.peacockGarden
                            ? 'ನವಿಲು'
                            : theme == PlayTheme.lotusPond
                            ? 'ಕಮಲ'
                            : 'ಗಾಳಿಪಟ')
                      : theme.displayName.split(' ').first;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedTheme = theme),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 90,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textHint.withValues(alpha: 0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            theme.emoji,
                            style: TextStyle(fontSize: isSelected ? 32 : 28),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayThemeName,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 14,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ═══ REWARD TYPE ═══
            _buildSectionHeader(
              '🏆 ' + 'reward_type'.tr(language),
              'reward_subtitle'.tr(language),
            ),
            const SizedBox(height: 12),
            ...MiniGameType.values.map((game) {
              final isSelected = _selectedReward == game;
              final displayGameName = isKn
                  ? (game == MiniGameType.bubbleBurst
                        ? 'ಗುಳ್ಳೆ ಒಡೆಯುವುದು'
                        : game == MiniGameType.plantWatering
                        ? 'ಗಿಡಕ್ಕೆ ನೀರು ಹಾಕುವುದು'
                        : 'ರಂಗೋಲಿ ಬಣ್ಣಿಸುವುದು')
                  : game.displayName;
              final displayGameDesc = isKn
                  ? (game == MiniGameType.bubbleBurst
                        ? 'ಬಣ್ಣ ಬಣ್ಣದ ಗುಳ್ಳೆಗಳನ್ನು ಒಡೆಯಿರಿ!'
                        : game == MiniGameType.plantWatering
                        ? 'ಗಿಡಕ್ಕೆ ನೀರುಣಿಸಿ ಅದು ಬೆಳೆಯುವುದನ್ನು ನೋಡಿ!'
                        : 'ಸುಂದರ ರಂಗೋಲಿಗೆ ಬಣ್ಣ ತುಂಬಿರಿ!')
                  : game.description;

              return GestureDetector(
                onTap: () => setState(() => _selectedReward = game),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textHint.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(game.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayGameName,
                              style: AppTextStyles.titleSmall,
                            ),
                            Text(
                              displayGameDesc,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.accent,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // ═══ SESSION OPTIONS ═══
            _buildSectionHeader(
              '⚙️ ' + (isKn ? 'ಆಯ್ಕೆಗಳು' : 'Options'),
              isKn ? 'ಸಮಯ ಮತ್ತು ಸಂಪರ್ಕ' : 'Timer & device sync',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  // Timer toggle
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isKn ? 'ಸೆಶನ್ ಸಮಯ' : 'Session Timer',
                              style: AppTextStyles.titleSmall,
                            ),
                            Text(
                              isKn
                                  ? 'ನಿಗದಿತ ಸಮಯದ ನಂತರ ಕೊನೆಗೊಳಿಸಿ'
                                  : 'Auto-end after set duration',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _timerEnabled,
                        onChanged: (v) => setState(() => _timerEnabled = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                  if (_timerEnabled) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [15, 20, 30, 45].map((min) {
                        final isSelected = _timerMinutes == min;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(isKn ? '${min}ನಿ' : '${min}m'),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
                            onSelected: (_) =>
                                setState(() => _timerMinutes = min),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const Divider(height: 24),
                  // Dual device
                  Row(
                    children: [
                      const Icon(
                        Icons.devices_rounded,
                        color: AppColors.secondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isKn ? 'ದ್ವಿ-ಸಾಧನ ವಿಧಾನ' : 'Dual-Device Mode',
                              style: AppTextStyles.titleSmall,
                            ),
                            Text(
                              isKn
                                  ? 'ಮಗು ಬೇರೆ ಮೊಬೈಲ್ ಮೂಲಕ ಲಾಗಿನ್ ಆಗುತ್ತದೆ'
                                  : 'Kid joins on separate device',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _dualDevice,
                        onChanged: (v) => setState(() => _dualDevice = v),
                        activeThumbColor: AppColors.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ═══ START SESSION BUTTON ═══
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PreviewActiveSessionScreen(
                        childName: widget.childName,
                        level: _selectedLevel,
                        tokensRequired: _tokensRequired,
                        theme: _selectedTheme,
                        reward: _selectedReward,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_filled_rounded, size: 28),
                label: Text(
                  'start_therapy_button'.tr(language),
                  style: AppTextStyles.buttonText.copyWith(fontSize: 17),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 6,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headlineSmall),
        Text(
          subtitle,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  Widget _buildTokenButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  Color _getLevelColor(TherapyLevel level) {
    switch (level) {
      case TherapyLevel.word:
        return AppColors.levelWord;
      case TherapyLevel.sentence:
        return AppColors.levelSentence;
      case TherapyLevel.continuousSpeech:
        return AppColors.levelContinuous;
      case TherapyLevel.narrative:
        return AppColors.levelNarrative;
      case TherapyLevel.conversational:
        return AppColors.levelConversational;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 4. ACTIVE THERAPY SESSION (Token Board + Smooth/Bumpy)
// ═══════════════════════════════════════════════════════════════
class PreviewActiveSessionScreen extends ConsumerStatefulWidget {
  final String childName;
  final TherapyLevel level;
  final int tokensRequired;
  final PlayTheme theme;
  final MiniGameType reward;

  const PreviewActiveSessionScreen({
    super.key,
    this.childName = 'Aarav',
    this.level = TherapyLevel.word,
    this.tokensRequired = 5,
    this.theme = PlayTheme.diyaFestival,
    this.reward = MiniGameType.bubbleBurst,
  });

  @override
  ConsumerState<PreviewActiveSessionScreen> createState() =>
      _PreviewActiveSessionScreenState();
}

class _PreviewActiveSessionScreenState
    extends ConsumerState<PreviewActiveSessionScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  int _tokensEarned = 0;
  int _fluentCount = 0;
  int _dysfluentCount = 0;
  int _rewardCycles = 0;
  String? _feedbackText;
  Color? _feedbackColor;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _recordSmooth() {
    final language = ref.read(appLanguageProvider);
    setState(() {
      _fluentCount++;
      _tokensEarned++;
      _feedbackText = 'smooth_feedback'.tr(language);
      _feedbackColor = AppColors.smoothGreen;
      _showFeedback = true;
    });
    _hideFeedbackAfterDelay();

    if (_tokensEarned >= widget.tokensRequired) {
      _confettiController.play();
      setState(() {
        _rewardCycles++;
        _tokensEarned = 0;
      });
    }
  }

  void _recordBumpy() {
    final language = ref.read(appLanguageProvider);
    setState(() {
      _dysfluentCount++;
      if (_tokensEarned > 0) _tokensEarned--;
      _feedbackText = 'bumpy_feedback'.tr(language);
      _feedbackColor = AppColors.bumpyOrange;
      _showFeedback = true;
    });
    _hideFeedbackAfterDelay();
  }

  void _hideFeedbackAfterDelay() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showFeedback = false);
    });
  }

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
            content: Text('Could not start video call: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final isKn = language == AppLanguage.kannada;
    final total = _fluentCount + _dysfluentCount;
    final fluencyPct = total > 0 ? (_fluentCount / total * 100) : 0.0;

    final displayLevelName = isKn
        ? (widget.level == TherapyLevel.word
              ? 'ಪದ ಮಟ್ಟ'
              : widget.level == TherapyLevel.sentence
              ? 'ವಾಕ್ಯ ಮಟ್ಟ'
              : widget.level == TherapyLevel.continuousSpeech
              ? 'ನಿರಂತರ ಮಾತು'
              : widget.level == TherapyLevel.narrative
              ? 'ಕಥೆ ಹೇಳುವುದು'
              : 'ಸಂಭಾಷಣೆ')
        : widget.level.displayName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.childName} — $displayLevelName'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () => _joinVideoCall(
                'preview_room_${widget.childName.replaceAll(RegExp(r'\s+'), '').toLowerCase()}',
                'Clinician / SLP'),
            icon: const Icon(Icons.videocam_rounded),
            color: AppColors.primary,
            tooltip: isKn ? 'ವಿಡಿಯೋ ಕರೆ ಸೇರಿ' : 'Join Video Call',
          ),
          // Live stats
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: fluencyPct >= 80
                  ? AppColors.successLight
                  : AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${fluencyPct.toStringAsFixed(0)}%',
              style: AppTextStyles.labelLarge.copyWith(
                color: fluencyPct >= 80 ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ─── Token Ring ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.theme.emoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'token_board'.tr(language),
                        style: AppTextStyles.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isKn
                            ? '$_tokensEarned / ${widget.tokensRequired} ನಕ್ಷತ್ರಗಳು'
                            : '$_tokensEarned / ${widget.tokensRequired} tokens',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Token stars
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(widget.tokensRequired, (i) {
                          final earned = i < _tokensEarned;
                          return AnimatedScale(
                            scale: earned ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              earned
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 40,
                              color: earned
                                  ? AppColors.tokenGold
                                  : AppColors.tokenGold.withValues(alpha: 0.2),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isKn
                            ? '🏆 ಬಹುಮಾನ ಚಕ್ರಗಳು: $_rewardCycles'
                            : '🏆 Reward cycles: $_rewardCycles',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.tokenGold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─── Quick Stats ───
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickStat(
                        isKn ? 'ಸರಾಗ' : 'Fluent',
                        '$_fluentCount',
                        AppColors.smoothGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickStat(
                        isKn ? 'ತೊಡರಿದ' : 'Dysfluent',
                        '$_dysfluentCount',
                        AppColors.bumpyOrange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickStat(
                        isKn ? 'ಒಟ್ಟು' : 'Total',
                        '$total',
                        AppColors.info,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ─── SMOOTH / BUMPY BUTTONS ───
                Text(
                  'record_utterance'.tr(language),
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    // Smooth button
                    Expanded(
                      child: GestureDetector(
                        onTap: _recordSmooth,
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: AppColors.smoothGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.smoothGreen.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.waves_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'smooth'.tr(language),
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'fluent_speech'.tr(language),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Bumpy button
                    Expanded(
                      child: GestureDetector(
                        onTap: _recordBumpy,
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: AppColors.bumpyGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.bumpyOrange.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.graphic_eq_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'bumpy'.tr(language),
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'dysfluent_speech'.tr(language),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // End session
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.stop_circle_outlined,
                      color: AppColors.error,
                      size: 22,
                    ),
                    label: Text(
                      'end_session'.tr(language),
                      style: AppTextStyles.buttonText.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Feedback overlay ───
          if (_showFeedback)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child:
                      Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: _feedbackColor?.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _feedbackText ?? '',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          )
                          .animate()
                          .scale(
                            begin: const Offset(0.6, 0.6),
                            end: const Offset(1, 1),
                            duration: 300.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: 200.ms),
                ),
              ),
            ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: const [
                AppColors.tokenGold,
                AppColors.smoothGreen,
                AppColors.primary,
                AppColors.accent,
                AppColors.secondary,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}
