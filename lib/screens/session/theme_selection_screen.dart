import 'dart:math';
import '../../utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../config/theme/app_theme.dart';
import '../../config/constants/app_constants.dart';
import '../../config/routes/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/session.dart';
import 'session_setup_screen.dart';
import 'active_session_screen.dart';

/// Theme selection screen — clinician or child picks a play theme
class ThemeSelectionScreen extends ConsumerStatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  ConsumerState<ThemeSelectionScreen> createState() =>
      _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends ConsumerState<ThemeSelectionScreen> {
  PlayTheme? _selectedTheme;
  PlayTheme? _previewTheme;

  String _generateSessionCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  Future<void> _startSessionWithTheme() async {
    if (_selectedTheme == null) return;

    final currentConfig = ref.read(sessionConfigProvider);
    if (currentConfig != null) {
      final updatedConfig = currentConfig.copyWith(playTheme: _selectedTheme!.name);
      ref.read(sessionConfigProvider.notifier).state = updatedConfig;

      final user = ref.read(currentUserProvider);
      if (user != null) {
        final code = _generateSessionCode();
        final activeSession = ActiveSession.fromConfig(
          updatedConfig,
          sessionCode: code,
          clinicianId: user.uid,
        );
        try {
          await ref
              .read(firestoreServiceProvider)
              .createActiveSession(activeSession);
        } catch (e) {
          // Without the shared row the child's device can never find this
          // code. Starting the session anyway would leave the clinician
          // reading out a code that only ever answers "Session not found".
          debugPrint('createActiveSession failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 6),
                content: Text(
                  'Could not start the session — the child will not be able '
                  'to join. Check your connection and try again.'.tr(),
                ),
              ),
            );
          }
          return;
        }

        // Crucial: Set the active session state with the EXACT same code!
        ref.read(activeSessionProvider.notifier).state = ActiveSessionState(
          config: updatedConfig,
          sessionCode: code,
          startTime: DateTime.now(),
        );
      }
      if (mounted) {
        context.goNamed(AppRouter.activeSession);
      }
    } else {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(_selectedTheme);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Choose a Token'.tr()),
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Column(
        children: [
          // Preview area
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getThemeGradient(_previewTheme ?? PlayTheme.initial),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CustomPaint(
                      painter: _ThemePatternPainter(
                        theme: _previewTheme ?? PlayTheme.initial,
                      ),
                    ),
                  ),
                ),
                // Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (_previewTheme ?? PlayTheme.initial).emoji,
                        style: const TextStyle(fontSize: 56),
                      )
                          .animate(
                            key: ValueKey(_previewTheme),
                          )
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1, 1),
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 10),
                      Text(
                        (_previewTheme ?? PlayTheme.initial).displayName,
                        style: AppTextStyles.headlineMedium
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (_previewTheme ?? PlayTheme.initial).description,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Theme grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: PlayTheme.selectable.length,
              itemBuilder: (context, index) {
                final theme = PlayTheme.selectable[index];
                final isSelected = _selectedTheme == theme;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTheme = theme;
                      _previewTheme = theme;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textHint.withValues(alpha: 0.12),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected ? AppTheme.cardShadow : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          theme.emoji,
                          style: TextStyle(
                            fontSize: isSelected ? 38 : 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          theme.displayName.split(' ').first,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 100 + index * 60),
                      duration: 400.ms,
                    )
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    );
              },
            ),
          ),

          // Select button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _selectedTheme != null ? _startSessionWithTheme : null,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  _selectedTheme != null
                      ? 'Select ${_selectedTheme!.displayName}'
                      : 'Choose a Token',
                  style: AppTextStyles.buttonText,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.textHint.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getThemeGradient(PlayTheme theme) {
    switch (theme) {
      case PlayTheme.diyaFestival:
        return [const Color(0xFFFF9800), const Color(0xFFFF5722)];
      case PlayTheme.rangoliBuilder:
        return [const Color(0xFFE91E63), const Color(0xFF9C27B0)];
      case PlayTheme.mangoHarvest:
        return [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
      case PlayTheme.peacockGarden:
        return [const Color(0xFF00BCD4), const Color(0xFF006064)];
      case PlayTheme.lotusPond:
        return [const Color(0xFFFF4081), const Color(0xFFC51162)];
      case PlayTheme.kiteFestival:
        return [const Color(0xFF7C4DFF), const Color(0xFF304FFE)];

      // Container themes, tinted to their token.
      case PlayTheme.flowerBasket:
        return [const Color(0xFFFF7BA9), const Color(0xFFD81B60)];
      case PlayTheme.iceCreamBox:
        return [const Color(0xFF4FC3F7), const Color(0xFF0288D1)];
      case PlayTheme.chocolateBox:
        return [const Color(0xFF8D6E63), const Color(0xFF4E342E)];
      case PlayTheme.cakeStand:
        return [const Color(0xFFFF8A80), const Color(0xFFD84315)];
      case PlayTheme.coinPiggyBank:
        return [const Color(0xFFF48FB1), const Color(0xFFC2185B)];
      case PlayTheme.starChart:
        return [const Color(0xFFFFD54F), const Color(0xFFF9A825)];
      case PlayTheme.carGarage:
        return [const Color(0xFF78909C), const Color(0xFF37474F)];
      case PlayTheme.superheroStickers:
        return [const Color(0xFF9575CD), const Color(0xFF512DA8)];
      case PlayTheme.princessStickers:
        return [const Color(0xFFCE93D8), const Color(0xFF7B1FA2)];
      case PlayTheme.fishBowl:
        return [const Color(0xFF4DD0E1), const Color(0xFF00838F)];
    }
  }
}

/// Custom painter for decorative background pattern
class _ThemePatternPainter extends CustomPainter {
  final PlayTheme theme;

  _ThemePatternPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    for (int i = 0; i < 6; i++) {
      final x = (size.width / 5) * i;
      final y = size.height * 0.3 + (i.isEven ? -20 : 20);
      canvas.drawCircle(Offset(x, y), 30 + i * 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
