import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

/// Bubble Burst mini-game reward
class BubbleBurstGame extends StatefulWidget {
  const BubbleBurstGame({super.key});

  @override
  State<BubbleBurstGame> createState() => _BubbleBurstGameState();
}

class _BubbleBurstGameState extends State<BubbleBurstGame> {
  final List<_Bubble> _bubbles = [];
  int _score = 0;
  int _timeLeft = 60;
  Timer? _timer;
  Timer? _bubbleSpawner;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    // Timer countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft <= 0) {
        timer.cancel();
        _bubbleSpawner?.cancel();
        _showGameOver();
      } else {
        setState(() => _timeLeft--);
      }
    });

    // Spawn bubbles
    _bubbleSpawner = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (_bubbles.length < 12) {
        setState(() {
          _bubbles.add(_Bubble(
            id: DateTime.now().millisecondsSinceEpoch,
            x: 30 + _random.nextDouble() * (MediaQuery.of(context).size.width - 100),
            y: MediaQuery.of(context).size.height * 0.3 +
                _random.nextDouble() * (MediaQuery.of(context).size.height * 0.5),
            size: 40 + _random.nextDouble() * 30,
            color: [
              AppColors.primary,
              AppColors.secondary,
              AppColors.accent,
              AppColors.smoothGreen,
              AppColors.info,
              AppColors.lotusTheme,
            ][_random.nextInt(6)],
          ));
        });
      }
    });
  }

  void _popBubble(int id) {
    setState(() {
      _bubbles.removeWhere((b) => b.id == id);
      _score++;
    });
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Great Job!'),
        content: Text('You popped $_score bubbles!',
            style: AppTextStyles.bodyLarge),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bubbleSpawner?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Top bar
              Positioned(
                top: 10,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('🫧 Score: $_score',
                          style: AppTextStyles.titleMedium),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _timeLeft <= 10
                            ? AppColors.error.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('⏱ ${_timeLeft}s',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: _timeLeft <= 10 ? AppColors.error : null,
                          )),
                    ),
                  ],
                ),
              ),

              // Bubbles
              ..._bubbles.map((bubble) {
                return Positioned(
                  left: bubble.x,
                  top: bubble.y,
                  child: GestureDetector(
                    onTap: () => _popBubble(bubble.id),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: bubble.size,
                            height: bubble.size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: bubble.color.withValues(alpha: 0.6),
                              border: Border.all(
                                color: bubble.color.withValues(alpha: 0.8),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: bubble.color.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: bubble.size * 0.3,
                                height: bubble.size * 0.2,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble {
  final int id;
  final double x;
  final double y;
  final double size;
  final Color color;

  _Bubble({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
  });
}
