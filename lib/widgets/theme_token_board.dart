import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/constants/app_constants.dart';
import '../config/theme/app_colors.dart';

/// Ultra-interactive, kid-attractive theme token board widget
class ThemeTokenBoardWidget extends StatefulWidget {
  final PlayTheme theme;
  final int currentTokens;
  final int tokenGoal;
  final bool isInteractive;
  final VoidCallback? onTokenTap;

  const ThemeTokenBoardWidget({
    super.key,
    required this.theme,
    required this.currentTokens,
    required this.tokenGoal,
    this.isInteractive = false,
    this.onTokenTap,
  });

  @override
  State<ThemeTokenBoardWidget> createState() => _ThemeTokenBoardWidgetState();
}

class _ThemeTokenBoardWidgetState extends State<ThemeTokenBoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 380),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: _getThemeBackgroundDecoration(widget.theme),
          child: Column(
            children: [
              // Header Badge
              _buildThemeBadge(widget.theme, widget.currentTokens, widget.tokenGoal),

              const SizedBox(height: 16),

              // Interactive Theme Canvas
              Expanded(
                child: Center(
                  child: _buildThemeCanvas(
                    widget.theme,
                    widget.currentTokens,
                    widget.tokenGoal,
                    _pulseController.value,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Theme-specific background card styling
  BoxDecoration _getThemeBackgroundDecoration(PlayTheme theme) {
    switch (theme) {
      case PlayTheme.diyaFestival:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C1930), Color(0xFF1E1022)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: const Color(0xFFFFD700), width: 2),
        );
      case PlayTheme.rangoliBuilder:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D0B33), Color(0xFF16031C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: const Color(0xFFFF4081), width: 2),
        );
      case PlayTheme.mangoHarvest:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F3818), Color(0xFF061A0A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: const Color(0xFF81C784), width: 2),
        );
      case PlayTheme.peacockGarden:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A2239), Color(0xFF04101D)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: const Color(0xFF00E5FF), width: 2),
        );
      case PlayTheme.lotusPond:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF06283D), Color(0xFF02121D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B4D8).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: const Color(0xFF90E0EF), width: 2),
        );
      case PlayTheme.kiteFestival:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F2B5B), Color(0xFF0D1433)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: const Color(0xFFB388FF), width: 2),
        );
    }
  }

  /// Theme Title Badge
  Widget _buildThemeBadge(PlayTheme theme, int current, int goal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(theme.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            theme.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tokenGold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$current / $goal ⭐',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive Theme Visual Canvas Switcher
  Widget _buildThemeCanvas(
    PlayTheme theme,
    int current,
    int goal,
    double pulse,
  ) {
    switch (theme) {
      case PlayTheme.diyaFestival:
        return _buildDiyaFestivalCanvas(current, goal, pulse);
      case PlayTheme.rangoliBuilder:
        return _buildRangoliCanvas(current, goal, pulse);
      case PlayTheme.mangoHarvest:
        return _buildMangoHarvestCanvas(current, goal, pulse);
      case PlayTheme.peacockGarden:
        return _buildPeacockCanvas(current, goal, pulse);
      case PlayTheme.lotusPond:
        return _buildLotusPondCanvas(current, goal, pulse);
      case PlayTheme.kiteFestival:
        return _buildKiteCanvas(current, goal, pulse);
    }
  }

  // 🪔 1. Diya Festival Canvas (Brass Thali with Glowing Diyas)
  Widget _buildDiyaFestivalCanvas(int current, int goal, double pulse) {
    final count = goal.clamp(1, 30);

    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = min(constraints.maxWidth, constraints.maxHeight) * 0.38;
        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Brass Thali Plate
            Container(
              width: radius * 2.3,
              height: radius * 2.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.25),
                    const Color(0xFFB8860B).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                  width: 3,
                ),
              ),
            ),

            // Diyas Arranged in Circle
            ...List.generate(count, (index) {
              final angle = (2 * pi / count) * index - (pi / 2);
              final isLit = index < current;
              final x = center.dx + radius * cos(angle) - 24;
              final y = center.dy + radius * sin(angle) - 24;

              return Positioned(
                left: x,
                top: y,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        if (isLit)
                          // Flame Glow Effect
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orangeAccent.withValues(alpha: 0.8),
                                  blurRadius: 16 + (pulse * 8),
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        Text(
                          isLit ? '🪔' : '🪔',
                          style: TextStyle(
                            fontSize: 34,
                            color: isLit ? null : Colors.grey.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                    .animate(target: isLit ? 1 : 0)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.15, 1.15))
                    .shake(duration: 400.ms),
              );
            }),

            // Center Brass Lamp
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 42))
                    .animate()
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.seconds)
                    .then()
                    .shake(),
                Text(
                  '$current LIT',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // 🎨 2. Rangoli Canvas (Vibrant Lotus Mandala Petal Wheel)
  Widget _buildRangoliCanvas(int current, int goal, double pulse) {
    final count = goal.clamp(1, 30);
    final colors = [
      const Color(0xFFFF1744),
      const Color(0xFFF50057),
      const Color(0xFFD500F9),
      const Color(0xFF651FFF),
      const Color(0xFF00E5FF),
      const Color(0xFF00E676),
      const Color(0xFFFFEA00),
      const Color(0xFFFF9100),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = min(constraints.maxWidth, constraints.maxHeight) * 0.38;
        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Center Rangoli Mandala
            Container(
              width: radius * 2.2,
              height: radius * 2.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
            ),

            ...List.generate(count, (index) {
              final angle = (2 * pi / count) * index - (pi / 2);
              final isFilled = index < current;
              final petalColor = colors[index % colors.length];
              final x = center.dx + radius * cos(angle) - 22;
              final y = center.dy + radius * sin(angle) - 22;

              return Positioned(
                left: x,
                top: y,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isFilled ? petalColor : Colors.white10,
                    shape: BoxShape.circle,
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: petalColor.withValues(alpha: 0.8),
                              blurRadius: 12 + (pulse * 6),
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                    border: Border.all(
                      color: isFilled ? Colors.white : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isFilled ? '🌸' : '${index + 1}',
                      style: TextStyle(
                        fontSize: isFilled ? 22 : 12,
                        color: isFilled ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                    .animate(target: isFilled ? 1 : 0)
                    .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.1, 1.1))
                    .rotate(begin: 0, end: 0.1),
              );
            }),

            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎨', style: TextStyle(fontSize: 48)),
                Text(
                  'RANGOLI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // 🥭 3. Mango Harvest Canvas (Tree with Growing Golden Mangoes)
  Widget _buildMangoHarvestCanvas(int current, int goal, double pulse) {
    final count = goal.clamp(1, 30);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Tree Trunk & Leaves Icon
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🌳', style: TextStyle(fontSize: 160)),
              ],
            ),

            // Mangoes on tree branches
            ...List.generate(count, (index) {
              final isRipe = index < current;
              // Distribute in tree canopy area
              final row = index % 5;
              final col = index ~/ 5;
              final offsetX = (row - 2) * 44.0;
              final offsetY = (col - 2) * 38.0 - 20;

              return Transform.translate(
                offset: Offset(offsetX, offsetY),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: isRipe
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.yellowAccent.withValues(alpha: 0.6),
                              blurRadius: 12 + (pulse * 4),
                              spreadRadius: 2,
                            ),
                          ],
                        )
                      : null,
                  child: Text(
                    isRipe ? '🥭' : '🥭',
                    style: TextStyle(
                      fontSize: 32,
                      color: isRipe ? null : Colors.black45,
                    ),
                  ),
                )
                    .animate(target: isRipe ? 1 : 0)
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.15, 1.15))
                    .moveY(begin: -10, end: 0),
              );
            }),
          ],
        );
      },
    );
  }

  // 🦚 4. Peacock Garden Canvas (Royal Peacock Tail Feathers)
  Widget _buildPeacockCanvas(int current, int goal, double pulse) {
    final count = goal.clamp(1, 30);

    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = min(constraints.maxWidth, constraints.maxHeight) * 0.38;
        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2 + 30);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Fan Feathers Arc
            ...List.generate(count, (index) {
              final angle = (pi / (count + 1)) * (index + 1) + pi;
              final isFanned = index < current;
              final x = center.dx + radius * cos(angle) - 20;
              final y = center.dy + radius * sin(angle) - 20;

              return Positioned(
                left: x,
                top: y,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: isFanned
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                              blurRadius: 10 + (pulse * 5),
                            )
                          ],
                        )
                      : null,
                  child: Text(
                    isFanned ? '🦚' : '🪶',
                    style: TextStyle(
                      fontSize: 30,
                      color: isFanned ? null : Colors.white24,
                    ),
                  ),
                )
                    .animate(target: isFanned ? 1 : 0)
                    .scale(begin: const Offset(0.6, 0.6), end: const Offset(1.1, 1.1)),
              );
            }),

            // Peacock Center
            const Positioned(
              bottom: 20,
              child: Column(
                children: [
                  Text('🦚', style: TextStyle(fontSize: 70)),
                  Text(
                    'ROYAL PEACOCK',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // 🌸 5. Lotus Pond Canvas (Turquoise Pond with Blooming Lotus Flowers)
  Widget _buildLotusPondCanvas(int current, int goal, double pulse) {
    final count = goal.clamp(1, 30);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Water Ripple Circles
            Container(
              width: constraints.maxWidth * 0.8,
              height: constraints.maxHeight * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
                border: Border.all(color: const Color(0xFF90E0EF).withValues(alpha: 0.3), width: 2),
              ),
            ),

            // Grid of Blooming Lotuses
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: List.generate(count, (index) {
                final isBloomed = index < current;
                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: isBloomed
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4081).withValues(alpha: 0.7),
                              blurRadius: 14 + (pulse * 6),
                              spreadRadius: 2,
                            ),
                          ],
                        )
                      : null,
                  child: Text(
                    isBloomed ? '🌸' : '🪷',
                    style: TextStyle(
                      fontSize: 34,
                      color: isBloomed ? null : Colors.white24,
                    ),
                  ),
                )
                    .animate(target: isBloomed ? 1 : 0)
                    .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.2, 1.2))
                    .shake(duration: 400.ms);
              }),
            ),
          ],
        );
      },
    );
  }

  // 🪁 6. Kite Festival Canvas (Kites Flying in Sky)
  Widget _buildKiteCanvas(int current, int goal, double pulse) {
    final count = goal.clamp(1, 30);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Clouds Background
            const Positioned(
              top: 10,
              left: 20,
              child: Text('☁️', style: TextStyle(fontSize: 40)),
            ),
            const Positioned(
              top: 30,
              right: 30,
              child: Text('☁️', style: TextStyle(fontSize: 50)),
            ),

            // Flying Kites
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: List.generate(count, (index) {
                final isFlying = index < current;
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: isFlying
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                              blurRadius: 12 + (pulse * 6),
                            ),
                          ],
                        )
                      : null,
                  child: Text(
                    isFlying ? '🪁' : '🪁',
                    style: TextStyle(
                      fontSize: 34,
                      color: isFlying ? null : Colors.white24,
                    ),
                  ),
                )
                    .animate(target: isFlying ? 1 : 0)
                    .scale(begin: const Offset(0.6, 0.6), end: const Offset(1.15, 1.15))
                    .moveY(begin: 15, end: 0);
              }),
            ),
          ],
        );
      },
    );
  }
}
