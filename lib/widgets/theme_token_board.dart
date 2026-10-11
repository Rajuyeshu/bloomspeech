import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
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

  /// The slots vacated by the most recent loss, and how long ago it happened.
  ///
  /// Response Cost only works if the child perceives the cost. Gaining a token
  /// was obvious — something appeared — while losing one simply meant a glyph
  /// faded to an outline, which is easy to miss on a board of twenty. These
  /// fields drive a brief, deliberately conspicuous departure animation so the
  /// loss is an event rather than an absence.
  Set<int> _lostSlots = const {};
  Timer? _lostTimer;

  static const Duration _lossWindow = Duration(milliseconds: 1400);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ThemeTokenBoardWidget old) {
    super.didUpdateWidget(old);

    // A reward cycle also drops the count — to zero — but that is a
    // celebration, not a cost, and must not be shown as a loss.
    final isReset = widget.currentTokens == 0 && old.currentTokens >= old.tokenGoal;

    if (widget.currentTokens < old.currentTokens && !isReset) {
      setState(() {
        _lostSlots = {
          for (var i = widget.currentTokens; i < old.currentTokens; i++) i
        };
      });
      _lostTimer?.cancel();
      _lostTimer = Timer(_lossWindow, () {
        if (mounted) setState(() => _lostSlots = const {});
      });
    } else if (widget.currentTokens > old.currentTokens && _lostSlots.isNotEmpty) {
      // Earning again cancels the departure immediately — otherwise the slot
      // the child just refilled would still be animating away.
      _lostTimer?.cancel();
      setState(() => _lostSlots = const {});
    }
  }

  @override
  void dispose() {
    _lostTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: screenHeight < 750 ? 220 : 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: _getThemeBackgroundDecoration(widget.theme),
          // Hard backstop. The per-theme layouts size themselves to fit, but
          // clipping guarantees a token can never be painted over the stats row
          // below the board even if a future theme miscalculates.
          clipBehavior: Clip.hardEdge,
          child: LayoutBuilder(
            builder: (context, box) {
              // Chrome scales with the box. Fixed 16px padding plus a fixed
              // 16px gap left too little for the canvas on a short phone and
              // the column overflowed its own container.
              final tight = box.maxHeight < 200;
              final pad = tight ? 8.0 : 16.0;
              final gap = tight ? 6.0 : 12.0;

              return Padding(
                padding: EdgeInsets.all(pad),
                child: Column(
                  children: [
                    // Header Badge
                    _buildThemeBadge(
                        widget.theme, widget.currentTokens, widget.tokenGoal),

                    SizedBox(height: gap),

                    // Interactive Theme Canvas
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: _buildThemeCanvas(
                              widget.theme,
                              widget.currentTokens,
                              widget.tokenGoal,
                              _pulseController.value,
                            ),
                          ),
                          // A loss has to be an event the child notices, not a
                          // glyph quietly becoming an outline. The departing
                          // token animates out and this says plainly how many
                          // went with it.
                          if (_lostSlots.isNotEmpty)
                            IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.bumpyOrange,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.22),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(widget.theme.emoji,
                                        style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '−${_lostSlots.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 140.ms)
                                  .scale(
                                      begin: const Offset(0.6, 0.6),
                                      end: const Offset(1, 1))
                                  .then(delay: 700.ms)
                                  .fadeOut(duration: 340.ms)
                                  .moveY(end: -18),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Theme-specific background card styling (Light and clean pastels)
  BoxDecoration _getThemeBackgroundDecoration(PlayTheme theme) {
    // Container themes take their card tint from the vessel's own palette, so
    // a new theme needs no change here.
    if (theme.container != TokenContainer.none) {
      final pal = _palette(theme);
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, pal.body.withValues(alpha: 0.16)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: pal.body.withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      );
    }

    switch (theme) {
      case PlayTheme.diyaFestival:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFDF5), Color(0xFFFFF5E0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
        );
      case PlayTheme.rangoliBuilder:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF0F5), Color(0xFFFFE4E1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: const Color(0xFFF8BBD0), width: 1.5),
        );
      case PlayTheme.mangoHarvest:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
        );
      case PlayTheme.peacockGarden:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFE0F2F1)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: const Color(0xFFB2EBF2), width: 1.5),
        );
      case PlayTheme.lotusPond:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE0F2F1), Color(0xFFE8F5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: const Color(0xFFB2DFDB), width: 1.5),
        );
      case PlayTheme.kiteFestival:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8EAF6), Color(0xFFE1F5FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: const Color(0xFFC5CAE9), width: 1.5),
        );
      default:
        // Container themes were handled above.
        return BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        );
    }
  }

  /// Theme Title Badge (Light and clean design)
  Widget _buildThemeBadge(PlayTheme theme, int current, int goal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(theme.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          // Flexible + ellipsis: the theme name is the only variable-width
          // part, and on a narrow phone "Mango Harvest"/"Peacock Garden"
          // pushed the badge past the board edge.
          Flexible(
            child: Text(
              theme.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
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
                fontSize: 13,
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
    // Themes with a container share one canvas: the vessel is painted behind,
    // and the tokens pack into its interior using the same grid maths the
    // existing themes use (and that the layout tests already cover).
    if (theme.container != TokenContainer.none) {
      return _buildContainerCanvas(theme, current, goal, pulse);
    }

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
      default:
        // Unreachable: every non-legacy theme was handled above. Falling back
        // to a container board is still correct rather than blank.
        return _buildContainerCanvas(theme, current, goal, pulse);
    }
  }

  /// A vessel with tokens collecting inside it.
  Widget _buildContainerCanvas(
      PlayTheme theme, int current, int goal, double pulse) {
    final count = goal.clamp(1, 30);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final interior = _interiorOf(theme.container, size);

        // Pack against the INTERIOR, not the whole canvas, so tokens can never
        // spill outside the vessel that is meant to be holding them.
        final inner = BoxConstraints(
          maxWidth: interior.width,
          maxHeight: interior.height,
        );
        final cell = _gridCell(count, inner);
        final glyph = _gridTokenSize(count, inner);

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ContainerPainter(theme.container, _palette(theme)),
              ),
            ),
            Positioned(
              left: interior.left,
              top: interior.top,
              width: interior.width,
              height: interior.height,
              // Most vessels hold their contents; a cake stand supports them
              // from below, so its tokens rest on the plate rather than
              // floating in the middle of the interior.
              child: Align(
                alignment: theme.container == TokenContainer.cakeStand
                    ? Alignment.bottomCenter
                    : Alignment.center,
                child: Wrap(
                  spacing: 0,
                  runSpacing: 0,
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  children: List.generate(count, (index) {
                    final earned = index < current;
                    final justLost = _lostSlots.contains(index);

                    // A token on its way out: struck through, tipped over and
                    // greyed, so the child sees it leave rather than noticing
                    // later that it is gone.
                    if (justLost) {
                      return SizedBox(
                        key: ValueKey('token-$index'),
                        width: cell,
                        height: cell,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                theme.emoji,
                                style: TextStyle(
                                  fontSize: glyph,
                                  color: Colors.black.withValues(alpha: 0.45),
                                ),
                              ),
                              Icon(
                                Icons.close_rounded,
                                size: glyph * 0.95,
                                color: AppColors.bumpyOrange,
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .shake(hz: 5, offset: const Offset(2.5, 0))
                          .then()
                          .fadeOut(duration: 520.ms)
                          .scaleXY(end: 0.45)
                          .moveY(end: 26);
                    }

                    return SizedBox(
                      key: ValueKey('token-$index'),
                      width: cell,
                      height: cell,
                      child: Center(
                        child: Text(
                          theme.emoji,
                          style: TextStyle(
                            fontSize: glyph,
                            // Unearned tokens stay visible as faint outlines so
                            // the child can see how many are still to come.
                            color: earned ? null : Colors.black26,
                            shadows: earned
                                ? [
                                    Shadow(
                                      color: _palette(theme)
                                          .glow
                                          .withValues(alpha: 0.85),
                                      blurRadius: (glyph * 0.30) + (pulse * 5),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    )
                        .animate(target: earned ? 1 : 0)
                        .scale(
                            begin: const Offset(0.55, 0.55),
                            end: const Offset(1.0, 1.0))
                        .moveY(begin: -10, end: 0);
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  // 🪔 1. Diya Festival Canvas (Brass Thali with Glowing Diyas)
  Widget _buildDiyaFestivalCanvas(int current, int goal, double pulse) {
    final count = goal.clamp(1, 30);

    return LayoutBuilder(
      builder: (context, constraints) {
        // The centre lamp and its counter occupy the middle of the thali,
        // so the rings must stop short of it.
        final slots = _ringSlots(count, constraints, holeFraction: 0.6);
        final radius = min(constraints.maxWidth, constraints.maxHeight) * 0.40;

        // The Stack must span the whole canvas: token positions are
        // computed from `constraints`, but a Stack shrink-wraps to its
        // largest non-positioned child (the thali, the mandala). Without
        // this the tokens were laid out against a coordinate space far
        // wider than the Stack they live in, so they were painted outside
        // the board — and the board's clip erased them. The counter said
        // ten were lit and the child saw none.
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
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

            // Diyas arranged on as many rings as the goal needs.
            ...List.generate(count, (index) {
              final slot = slots[index];
              final isLit = index < current;

              return Positioned(
                key: ValueKey('token-$index'),
                left: slot.center.dx - slot.size / 2,
                top: slot.center.dy - slot.size / 2,
                child: SizedBox(
                  width: slot.size,
                  height: slot.size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isLit)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orangeAccent.withValues(alpha: 0.8),
                                blurRadius: (slot.size * 0.35) + (pulse * 6),
                                spreadRadius: slot.size * 0.08,
                              ),
                            ],
                          ),
                        ),
                      FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          '🪔',
                          style: TextStyle(
                            fontSize: 30,
                            color: isLit
                                ? null
                                : Colors.grey.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(target: isLit ? 1 : 0)
                    .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.1, 1.1)),
              );
            }),

            // Centre lamp, width-limited to the reserved hole so a long
            // counter cannot grow out under the innermost ring of diyas.
            SizedBox(
              width: min(constraints.maxWidth, constraints.maxHeight) * 0.34,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔥',
                        style: TextStyle(
                            fontSize: min(constraints.maxWidth,
                                    constraints.maxHeight) *
                                0.16))
                    .animate()
                    .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.1, 1.1),
                        duration: 1.seconds),
                Text(
                  '$current LIT',
                  style: TextStyle(
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.w900,
                    fontSize: min(constraints.maxWidth,
                            constraints.maxHeight) *
                        0.07,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              ),
            ),
          ],
          ),
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
        // Petals ring the mandala; the centre is reserved for the badge.
        final slots = _ringSlots(count, constraints, holeFraction: 0.6);
        final radius = min(constraints.maxWidth, constraints.maxHeight) * 0.40;

        // The Stack must span the whole canvas: token positions are
        // computed from `constraints`, but a Stack shrink-wraps to its
        // largest non-positioned child (the thali, the mandala). Without
        // this the tokens were laid out against a coordinate space far
        // wider than the Stack they live in, so they were painted outside
        // the board — and the board's clip erased them. The counter said
        // ten were lit and the child saw none.
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
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
              final slot = slots[index];
              final isFilled = index < current;
              final petalColor = colors[index % colors.length];

              return Positioned(
                key: ValueKey('token-$index'),
                left: slot.center.dx - slot.size / 2,
                top: slot.center.dy - slot.size / 2,
                child: Container(
                  width: slot.size,
                  height: slot.size,
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
                      width: slot.size > 26 ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Text(
                          isFilled ? '🌸' : '${index + 1}',
                          style: TextStyle(
                            fontSize: isFilled ? 20 : 12,
                            color: isFilled ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                    .animate(target: isFilled ? 1 : 0)
                    .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.1, 1.1))
                    .rotate(begin: 0, end: 0.1),
              );
            }),

            SizedBox(
              width: min(constraints.maxWidth, constraints.maxHeight) * 0.34,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎨',
                    style: TextStyle(
                        fontSize: min(constraints.maxWidth,
                                constraints.maxHeight) *
                            0.18)),
                Text(
                  'RANGOLI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: min(constraints.maxWidth,
                            constraints.maxHeight) *
                        0.06,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              ),
            ),
          ],
          ),
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
            // Tree scaled to the canvas — a fixed 160px glyph overflowed a
            // short board by ~100px.
            Text(
              '🌳',
              style: TextStyle(
                fontSize:
                    min(constraints.maxWidth, constraints.maxHeight) * 0.78,
              ),
            ),

            // Mangoes on tree branches
            ...List.generate(count, (index) {
              final isRipe = index < current;
              // Canopy grid sized to the goal — the old fixed 44x38 spacing
              // pushed mangoes off the board once the goal passed ~15.
              final perRow = count <= 10 ? 5 : (count <= 20 ? 6 : 7);
              final rows = (count / perRow).ceil();
              final stepX =
                  (constraints.maxWidth * 0.86) / perRow.clamp(1, 99);
              final stepY =
                  (constraints.maxHeight * 0.62) / rows.clamp(1, 99);
              final row = index % perRow;
              final col = index ~/ perRow;
              final offsetX = (row - (perRow - 1) / 2) * stepX;
              final offsetY = (col - (rows - 1) / 2) * stepY - 10;
              final mangoSize = min(stepX, stepY) * 0.78;

              return Transform.translate(
                offset: Offset(offsetX, offsetY),
                child: Container(
                  width: mangoSize,
                  height: mangoSize,
                  alignment: Alignment.center,
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
        // Upper half only (angles pi..2pi in Flutter's y-down space), keeping
        // the middle clear for the bird itself.
        final fan = _ringSlots(
          count,
          constraints,
          startAngle: pi,
          sweep: pi,
          // The bird is anchored to the bottom edge, not the middle, so the
          // fan only needs a small hole — and every ring it gets back is one
          // more row of feathers instead of a tighter, overlapping arc.
          holeFraction: 0.22,
        );

        // The Stack must span the whole canvas: token positions are
        // computed from `constraints`, but a Stack shrink-wraps to its
        // largest non-positioned child (the thali, the mandala). Without
        // this the tokens were laid out against a coordinate space far
        // wider than the Stack they live in, so they were painted outside
        // the board — and the board's clip erased them. The counter said
        // ten were lit and the child saw none.
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
          alignment: Alignment.center,
          children: [
            // Fan feathers, spread over the upper half of the board.
            //
            // These used to be placed on a single half-circle at a glyph size
            // computed for a FULL ring — half the arc, the same number of
            // feathers, so at a goal of 10 or more they overlapped into an
            // unreadable smear and the child could not tell how many they had
            // earned. `sweep` now tells the layout it only has half a turn to
            // work with, so it lays out a genuine multi-row fan.
            ...List.generate(count, (index) {
              final slot = fan[index];
              final isFanned = index < current;

              return Positioned(
                key: ValueKey('token-$index'),
                left: slot.center.dx - slot.size / 2,
                top: slot.center.dy - slot.size / 2,
                child: Container(
                  width: slot.size,
                  height: slot.size,
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
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      isFanned ? '🦚' : '🪶',
                      style: TextStyle(
                        fontSize: 26,
                        color: isFanned ? null : Colors.white24,
                      ),
                    ),
                  ),
                )
                    .animate(target: isFanned ? 1 : 0)
                    .scale(begin: const Offset(0.6, 0.6), end: const Offset(1.1, 1.1)),
              );
            }),

            // Peacock Center
            Positioned(
              bottom: 20,
              child: Column(
                children: [
                  Text('🦚',
                      style: TextStyle(
                          fontSize: min(constraints.maxWidth,
                                  constraints.maxHeight) *
                              0.26)),
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
          ),
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

            // Grid of Blooming Lotuses, sized so a 30-token goal still fits.
            Wrap(
              spacing: 0,
              runSpacing: 0,
              alignment: WrapAlignment.center,
              children: List.generate(count, (index) {
                final isBloomed = index < current;
                final cell = _gridCell(count, constraints);
                return Container(
                  width: cell,
                  height: cell,
                  alignment: Alignment.center,
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
                      fontSize: _gridTokenSize(count, constraints),
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
              spacing: 0,
              runSpacing: 0,
              alignment: WrapAlignment.center,
              children: List.generate(count, (index) {
                final isFlying = index < current;
                final cell = _gridCell(count, constraints);
                return Container(
                  width: cell,
                  height: cell,
                  alignment: Alignment.center,
                  decoration: isFlying
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                              blurRadius: (cell * 0.28) + (pulse * 4),
                            ),
                          ],
                        )
                      : null,
                  child: Text(
                    '🪁',
                    style: TextStyle(
                      fontSize: _gridTokenSize(count, constraints),
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


/// Colours for a container theme: the vessel, its shading, and the glow behind
/// an earned token.
class _Palette {
  final Color body;
  final Color shade;
  final Color line;
  final Color glow;
  const _Palette(this.body, this.shade, this.line, this.glow);
}

_Palette _palette(PlayTheme theme) {
  // Keyed by theme, not by container kind: two themes can share a container and
  // still need to look different.
  //
  // Every body colour here is a PALE tint. The first version used the vessel's
  // natural colour at full strength, which put brown chocolates on a brown box
  // and made the tokens hard to pick out — the one thing the child has to be
  // able to count. Saturation now lives in the outline and the shading, which
  // define the container without competing with what it holds.
  switch (theme) {
    case PlayTheme.flowerBasket:
      return const _Palette(Color(0xFFEBD3B0), Color(0xFFD4AF85),
          Color(0xFF8A5522), Color(0xFFFF6FA0));
    case PlayTheme.iceCreamBox:
      return const _Palette(Color(0xFFD8F0F9), Color(0xFFA9DCEC),
          Color(0xFF2E7D9E), Color(0xFF33C9F0));
    case PlayTheme.chocolateBox:
      // Cream box, dark outline: chocolate is a dark token and needs a light
      // field behind it.
      return const _Palette(Color(0xFFF6E7D7), Color(0xFFE2CBB4),
          Color(0xFF5A3A22), Color(0xFFFFB03A));
    case PlayTheme.cakeStand:
      return const _Palette(Color(0xFFFBF1E4), Color(0xFFEADCC7),
          Color(0xFF9E7C55), Color(0xFFFF7EC0));
    case PlayTheme.coinPiggyBank:
      return const _Palette(Color(0xFFFBDAE7), Color(0xFFF0B9D0),
          Color(0xFFC25E80), Color(0xFFFFC107));
    case PlayTheme.starChart:
      // A faintly blue page so a yellow star reads against it.
      return const _Palette(Color(0xFFEFF4FB), Color(0xFFDCE5F2),
          Color(0xFF6B7FA8), Color(0xFFFFB300));
    case PlayTheme.carGarage:
      return const _Palette(Color(0xFFE3E9EC), Color(0xFFC7D2D8),
          Color(0xFF4E5F68), Color(0xFF19B5E0));
    case PlayTheme.superheroStickers:
      return const _Palette(Color(0xFFDCE8FB), Color(0xFFBDD3F3),
          Color(0xFF3F6BB0), Color(0xFFFFB300));
    case PlayTheme.fishBowl:
      return const _Palette(Color(0xFFDFF3F7), Color(0xFFB7E4EE),
          Color(0xFF2A8CA6), Color(0xFF16C4E8));
    default:
      return const _Palette(Color(0xFFE8E8E8), Color(0xFFD0D0D0),
          Color(0xFF7A7A7A), Color(0xFFFFB300));
  }
}

/// Where tokens sit inside each vessel, as a rect within the canvas.
///
/// Deliberately generous margins: the tokens must read as being *in* the
/// container, and a child counting them should never see one clipped by its
/// edge.
Rect _interiorOf(TokenContainer kind, Size s) {
  final w = s.width, h = s.height;
  switch (kind) {
    case TokenContainer.basket:
      return Rect.fromLTWH(w * 0.20, h * 0.34, w * 0.60, h * 0.46);
    case TokenContainer.box:
      return Rect.fromLTWH(w * 0.18, h * 0.30, w * 0.64, h * 0.50);
    case TokenContainer.piggyBank:
      return Rect.fromLTWH(w * 0.24, h * 0.34, w * 0.52, h * 0.42);
    case TokenContainer.notebook:
      return Rect.fromLTWH(w * 0.24, h * 0.18, w * 0.62, h * 0.66);
    case TokenContainer.garage:
      return Rect.fromLTWH(w * 0.18, h * 0.38, w * 0.64, h * 0.44);
    case TokenContainer.stickerAlbum:
      return Rect.fromLTWH(w * 0.16, h * 0.20, w * 0.68, h * 0.62);
    case TokenContainer.cakeStand:
      return Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.68, h * 0.48);
    case TokenContainer.fishBowl:
      return Rect.fromLTWH(w * 0.22, h * 0.30, w * 0.56, h * 0.46);
    case TokenContainer.none:
      return Rect.fromLTWH(w * 0.10, h * 0.10, w * 0.80, h * 0.80);
  }
}

/// Draws the vessel behind the tokens.
class _ContainerPainter extends CustomPainter {
  final TokenContainer kind;
  final _Palette p;
  const _ContainerPainter(this.kind, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final fill = Paint()..color = p.body..style = PaintingStyle.fill;
    final shade = Paint()..color = p.shade..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = p.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.006)
      ..strokeCap = StrokeCap.round;

    switch (kind) {
      case TokenContainer.basket:
        // Handle arc above, then a tapered weave body.
        canvas.drawArc(
            Rect.fromLTWH(w * 0.28, h * 0.10, w * 0.44, h * 0.46), math.pi, math.pi,
            false, stroke);
        final body = Path()
          ..moveTo(w * 0.16, h * 0.32)
          ..lineTo(w * 0.84, h * 0.32)
          ..lineTo(w * 0.74, h * 0.86)
          ..lineTo(w * 0.26, h * 0.86)
          ..close();
        canvas.drawPath(body, fill);
        canvas.drawPath(body, stroke);
        for (var i = 1; i < 4; i++) {
          final t = i / 4;
          canvas.drawLine(
            Offset(w * (0.16 + 0.10 * t), h * (0.32 + 0.54 * t)),
            Offset(w * (0.84 - 0.10 * t), h * (0.32 + 0.54 * t)),
            stroke,
          );
        }
        break;

      case TokenContainer.box:
        // Open box: back wall, then a front panel the tokens sit behind.
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * 0.14, h * 0.26, w * 0.72, h * 0.60),
                Radius.circular(w * 0.03)),
            fill);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * 0.14, h * 0.26, w * 0.72, h * 0.60),
                Radius.circular(w * 0.03)),
            stroke);
        // Open lid flaps.
        canvas.drawLine(Offset(w * 0.14, h * 0.26), Offset(w * 0.04, h * 0.14), stroke);
        canvas.drawLine(Offset(w * 0.86, h * 0.26), Offset(w * 0.96, h * 0.14), stroke);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.14, h * 0.78, w * 0.72, h * 0.08), shade);
        break;

      case TokenContainer.piggyBank:
        final bodyRect = Rect.fromLTWH(w * 0.18, h * 0.28, w * 0.64, h * 0.52);
        canvas.drawRRect(
            RRect.fromRectAndRadius(bodyRect, Radius.circular(h * 0.26)), fill);
        canvas.drawRRect(
            RRect.fromRectAndRadius(bodyRect, Radius.circular(h * 0.26)), stroke);
        // Ear, snout, coin slot, trotters.
        final ear = Path()
          ..moveTo(w * 0.30, h * 0.31)
          ..lineTo(w * 0.36, h * 0.18)
          ..lineTo(w * 0.44, h * 0.30)
          ..close();
        canvas.drawPath(ear, shade);
        canvas.drawOval(
            Rect.fromLTWH(w * 0.78, h * 0.46, w * 0.12, h * 0.16), shade);
        canvas.drawLine(Offset(w * 0.44, h * 0.30), Offset(w * 0.60, h * 0.30), stroke);
        for (final x in [0.32, 0.62]) {
          canvas.drawRect(
              Rect.fromLTWH(w * x, h * 0.78, w * 0.07, h * 0.10), shade);
        }
        break;

      case TokenContainer.notebook:
        final page = Rect.fromLTWH(w * 0.18, h * 0.10, w * 0.70, h * 0.82);
        canvas.drawRRect(
            RRect.fromRectAndRadius(page, Radius.circular(w * 0.015)), fill);
        canvas.drawRRect(
            RRect.fromRectAndRadius(page, Radius.circular(w * 0.015)), stroke);
        // Spiral binding down the left edge.
        for (var i = 0; i < 7; i++) {
          final y = h * (0.16 + i * 0.11);
          canvas.drawArc(
              Rect.fromLTWH(w * 0.13, y, w * 0.10, h * 0.05), -math.pi / 2,
              math.pi, false, stroke);
        }
        // Faint rules so it reads as a page.
        final rule = Paint()
          ..color = p.line.withValues(alpha: 0.22)
          ..strokeWidth = 1;
        for (var i = 1; i < 8; i++) {
          final y = h * (0.10 + i * 0.10);
          canvas.drawLine(Offset(w * 0.22, y), Offset(w * 0.84, y), rule);
        }
        break;

      case TokenContainer.garage:
        // Roof, then a building with an open door.
        final roof = Path()
          ..moveTo(w * 0.08, h * 0.34)
          ..lineTo(w * 0.50, h * 0.10)
          ..lineTo(w * 0.92, h * 0.34)
          ..close();
        canvas.drawPath(roof, shade);
        canvas.drawPath(roof, stroke);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.14, h * 0.34, w * 0.72, h * 0.54), fill);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.14, h * 0.34, w * 0.72, h * 0.54), stroke);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.14, h * 0.86, w * 0.72, h * 0.06), shade);
        break;

      case TokenContainer.stickerAlbum:
        final page = Rect.fromLTWH(w * 0.10, h * 0.12, w * 0.80, h * 0.78);
        canvas.drawRRect(
            RRect.fromRectAndRadius(page, Radius.circular(w * 0.035)), fill);
        canvas.drawRRect(
            RRect.fromRectAndRadius(page, Radius.circular(w * 0.035)), stroke);
        // Album tab.
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * 0.36, h * 0.04, w * 0.28, h * 0.10),
                Radius.circular(w * 0.02)),
            shade);
        break;

      case TokenContainer.cakeStand:
        // Tokens sit on the plate, so the stand is drawn beneath them. The
        // plate needs real depth or the cakes read as floating.
        final plate = RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.08, h * 0.62, w * 0.84, h * 0.12),
            Radius.circular(h * 0.06));
        canvas.drawRRect(plate, fill);
        canvas.drawRRect(plate, stroke);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * 0.08, h * 0.69, w * 0.84, h * 0.05),
                Radius.circular(h * 0.025)),
            shade);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.45, h * 0.71, w * 0.10, h * 0.16), shade);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * 0.28, h * 0.87, w * 0.44, h * 0.06),
                Radius.circular(h * 0.03)),
            fill);
        break;

      case TokenContainer.fishBowl:
        // Round bowl on a small base, with a waterline so it reads as water.
        final bowl = Rect.fromLTWH(w * 0.16, h * 0.18, w * 0.68, h * 0.66);
        canvas.drawOval(bowl, fill);
        canvas.drawOval(bowl, stroke);
        final water = Path()
          ..moveTo(w * 0.20, h * 0.34)
          ..quadraticBezierTo(w * 0.50, h * 0.28, w * 0.80, h * 0.34);
        canvas.drawPath(water, stroke);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * 0.36, h * 0.82, w * 0.28, h * 0.08),
                Radius.circular(h * 0.04)),
            shade);
        break;

      case TokenContainer.none:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ContainerPainter old) =>
      old.kind != kind || old.p.body != p.body;
}

/// Where one token glyph sits, and how big it should be drawn.
class _TokenSlot {
  final Offset center;
  final double size;
  const _TokenSlot(this.center, this.size);
}

/// Lays [count] tokens out inside [c] so they always fit.
///
/// Rings march inward from the outer edge, shrinking the glyph until every
/// token has a place.
///
/// [holeFraction] keeps the middle of the board clear for the theme's
/// centrepiece. Without it the innermost ring landed directly underneath the
/// centre badge: with a goal of 10 the diya board drew nine diyas on the outer
/// ring and buried the tenth behind the lamp, so the counter read "10 LIT"
/// while the child could only ever see nine light up.
///
/// [startAngle] and [sweep] narrow the layout to an arc. The peacock fan needs
/// that — it spreads its feathers over the upper half only, which is half the
/// arc length a full ring provides.
List<_TokenSlot> _ringSlots(
  int count,
  BoxConstraints c, {
  double holeFraction = 0.0,
  double startAngle = -pi / 2,
  double sweep = 2 * pi,
}) {
  final w = c.maxWidth, h = c.maxHeight;
  final cx = w / 2, cy = h / 2;
  final maxR = min(w, h) * 0.40;
  if (count <= 0) return const [];
  if (maxR <= 0) {
    return List.generate(count, (_) => _TokenSlot(Offset(cx, cy), 12));
  }

  final full = sweep >= 2 * pi - 1e-6;
  final holeR = maxR * holeFraction.clamp(0.0, 0.9);
  // The floor is deliberately low. When no size fits, the fallback below
  // dumps every token onto a single arc where they overlap badly, so it is
  // far better to keep shrinking: a small token the child can still count
  // beats a large one buried under its neighbour.
  const minSize = 5.0, maxSize = 40.0, gap = 1.18;

  // A closed ring wraps, so n tokens need n gaps. An open arc does not: its
  // first and last tokens sit on the two ends, so n tokens need n-1 gaps.
  double angleAt(int i, int n) {
    if (full) return startAngle + (2 * pi / n) * i;
    if (n == 1) return startAngle + sweep / 2;
    return startAngle + sweep * i / (n - 1);
  }

  int capacity(double r, double size) {
    final n = ((full ? 2 * pi : sweep) * r / (size * gap)).floor();
    return full ? max(1, n) : max(1, n + 1);
  }

  for (var size = maxSize; size >= minSize; size -= 1) {
    // Rings spaced so neighbours cannot touch, stopping before the hole. The
    // ring count is derived rather than fixed — with a hard cap the layout
    // silently returned fewer slots than tokens and the caller threw a
    // RangeError.
    final radii = <double>[];
    final inner = max(holeR, size * 0.55);
    for (var r = maxR; r >= inner; r -= size * gap) {
      radii.add(r);
    }
    if (radii.isEmpty) radii.add(maxR);

    final caps = radii.map((r) => capacity(r, size)).toList();
    if (caps.fold<int>(0, (a, b) => a + b) < count) continue;

    final slots = <_TokenSlot>[];
    var remaining = count;
    for (var ring = 0; ring < radii.length && remaining > 0; ring++) {
      final n = min(remaining, caps[ring]);
      for (var i = 0; i < n; i++) {
        final a = angleAt(i, n);
        slots.add(_TokenSlot(
          Offset(cx + radii[ring] * cos(a), cy + radii[ring] * sin(a)),
          size,
        ));
      }
      remaining -= n;
    }
    return slots;
  }

  // Nothing fits cleanly (a very small board): one evenly divided ring at the
  // minimum size. Always returns exactly `count` slots.
  return List.generate(count, (i) {
    final a = angleAt(i, count);
    return _TokenSlot(
        Offset(cx + maxR * cos(a), cy + maxR * sin(a)), minSize);
  });
}

/// Largest square cell that fits [count] tokens inside [c] as a grid.
///
/// The previous version divided the area by the token count, which ignores
/// integer packing: 18 tokens in a 340x180 box "averaged" to 38px each, but
/// 38px cells only tile 5 across x 4 down and the fourth row fell outside the
/// board. This walks the cell size down until whole columns times whole rows
/// genuinely covers the count, so the grid can never overflow.
double _gridCell(int count, BoxConstraints c) {
  final w = c.maxWidth * 0.96;
  final h = c.maxHeight * 0.96;
  if (w <= 0 || h <= 0 || count <= 0) return 12;

  for (var cell = 44.0; cell >= 8.0; cell -= 0.5) {
    final cols = (w / cell).floor();
    final rows = (h / cell).floor();
    if (cols >= 1 && rows >= 1 && cols * rows >= count) return cell;
  }
  return 8;
}

/// Glyph size inside a [_gridCell], leaving a little breathing room.
double _gridTokenSize(int count, BoxConstraints c) =>
    _gridCell(count, c) * 0.72;
