import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../utils/app_localizations.dart';

/// Balloon popping.
///
/// Replaces the plant-watering game, which asked the child to tap one target
/// repeatedly and gave almost nothing back. This has several moving targets,
/// an immediate burst on contact, and a visible count — the three things that
/// hold a preschooler's attention in a reward game.
class BalloonPopGame extends StatefulWidget {
  const BalloonPopGame({super.key});

  @override
  State<BalloonPopGame> createState() => _BalloonPopGameState();
}

class _BalloonPopGameState extends State<BalloonPopGame>
    with SingleTickerProviderStateMixin {
  static const int _target = 12;

  final _rand = Random();
  final List<_Balloon> _balloons = [];
  final List<_Burst> _bursts = [];

  late final AnimationController _ticker;
  int _popped = 0;
  int _nextId = 0;

  static const List<Color> _colours = [
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFFFCA28),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
  ];

  @override
  void initState() {
    super.initState();
    // One controller drives every balloon, so there is a single repaint per
    // frame however many are on screen.
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_step);
    _ticker.repeat();
    for (var i = 0; i < 6; i++) {
      _balloons.add(_spawn(startLow: false));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  _Balloon _spawn({bool startLow = true}) => _Balloon(
        id: _nextId++,
        x: 0.08 + _rand.nextDouble() * 0.84,
        y: startLow ? 1.15 : 0.3 + _rand.nextDouble() * 0.85,
        speed: 0.0016 + _rand.nextDouble() * 0.0022,
        drift: (_rand.nextDouble() - 0.5) * 0.0008,
        size: 54 + _rand.nextDouble() * 26,
        colour: _colours[_rand.nextInt(_colours.length)],
      );

  void _step() {
    if (!mounted) return;
    setState(() {
      for (final b in _balloons) {
        b.y -= b.speed;
        b.x = (b.x + b.drift).clamp(0.05, 0.95);
        // A balloon that escapes off the top is replaced, so the screen never
        // empties and the child is never left with nothing to tap.
        if (b.y < -0.2) {
          final fresh = _spawn();
          b
            ..y = fresh.y
            ..x = fresh.x
            ..speed = fresh.speed
            ..drift = fresh.drift
            ..size = fresh.size
            ..colour = fresh.colour;
        }
      }
      _bursts.removeWhere((x) => DateTime.now().difference(x.at).inMilliseconds > 600);
    });
  }

  void _pop(_Balloon b, Size screen) {
    if (_popped >= _target) return;
    setState(() {
      _popped++;
      _bursts.add(_Burst(
        Offset(b.x * screen.width, b.y * screen.height),
        b.colour,
        DateTime.now(),
      ));
      final fresh = _spawn();
      b
        ..y = fresh.y
        ..x = fresh.x
        ..speed = fresh.speed
        ..size = fresh.size
        ..colour = fresh.colour;
    });

    if (_popped >= _target) {
      _ticker.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final done = _popped >= _target;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Stack(
          children: [
            // Balloons
            ..._balloons.map((b) => Positioned(
                  left: b.x * screen.width - b.size / 2,
                  top: b.y * screen.height - b.size / 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: done ? null : () => _pop(b, screen),
                    child: _BalloonShape(size: b.size, colour: b.colour),
                  ),
                )),

            // Pops
            ..._bursts.map((x) => Positioned(
                  left: x.at_.dx - 34,
                  top: x.at_.dy - 34,
                  child: IgnorePointer(
                    child: _PopBurst(colour: x.colour),
                  ),
                )),

            // Score
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(
                    '🎈  $_popped / $_target',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),

            if (done)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 34),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 60)),
                          const SizedBox(height: 10),
                          Text('All popped!'.tr(),
                              style: AppTextStyles.headlineSmall),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => context.pop(),
                            child: Text('Done'.tr()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Exit
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded, size: 28),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Balloon {
  final int id;
  double x, y, speed, drift, size;
  Color colour;
  _Balloon({
    required this.id,
    required this.x,
    required this.y,
    required this.speed,
    required this.drift,
    required this.size,
    required this.colour,
  });
}

class _Burst {
  final Offset at_;
  final Color colour;
  final DateTime at;
  const _Burst(this.at_, this.colour, this.at);
}

class _BalloonShape extends StatelessWidget {
  final double size;
  final Color colour;
  const _BalloonShape({required this.size, required this.colour});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.35,
      child: Column(
        children: [
          Container(
            width: size,
            height: size * 1.15,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.4),
                colors: [colour.withValues(alpha: 0.65), colour],
              ),
              borderRadius: BorderRadius.all(Radius.elliptical(size, size * 1.2)),
            ),
          ),
          // Knot and string.
          Container(width: 2.5, height: size * 0.2, color: colour),
        ],
      ),
    );
  }
}

/// The burst a balloon leaves behind.
class _PopBurst extends StatelessWidget {
  final Color colour;
  const _PopBurst({required this.colour});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (context, t, _) {
        return Opacity(
          opacity: (1 - t).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.5 + t * 1.5,
            child: SizedBox(
              width: 68,
              height: 68,
              child: CustomPaint(painter: _BurstPainter(colour)),
            ),
          ),
        );
      },
    );
  }
}

class _BurstPainter extends CustomPainter {
  final Color colour;
  const _BurstPainter(this.colour);

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final paint = Paint()
      ..color = colour
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 8; i++) {
      final a = (pi * 2 / 8) * i;
      canvas.drawCircle(
        centre + Offset(cos(a), sin(a)) * size.width * 0.34,
        size.width * 0.07,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.colour != colour;
}
