import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

/// Rangoli painting mini-game reward
class RangoliPaintGame extends StatefulWidget {
  const RangoliPaintGame({super.key});

  @override
  State<RangoliPaintGame> createState() => _RangoliPaintGameState();
}

class _RangoliPaintGameState extends State<RangoliPaintGame> {
  final List<Color> _palette = [
    const Color(0xFFE91E63),
    const Color(0xFFFF5722),
    const Color(0xFFFF9800),
    const Color(0xFFFFEB3B),
    const Color(0xFF4CAF50),
    const Color(0xFF2196F3),
    const Color(0xFF9C27B0),
    const Color(0xFF00BCD4),
  ];

  Color _selectedColor = const Color(0xFFE91E63);
  final Map<int, Color> _filledPetals = {};
  static const int _totalPetals = 16;

  bool get _isComplete => _filledPetals.length >= _totalPetals;

  void _fillPetal(int index) {
    if (_filledPetals.containsKey(index)) return;

    setState(() {
      _filledPetals[index] = _selectedColor;
    });

    if (_isComplete) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showComplete();
      });
    }
  }

  void _showComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎨 Beautiful Rangoli!'),
        content: Text(
          'You created a wonderful rangoli pattern!',
          style: AppTextStyles.bodyLarge,
        ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🎨 Rangoli Painter',
                      style: AppTextStyles.headlineSmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_filledPetals.length}/$_totalPetals',
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),

              // Rangoli
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: CustomPaint(
                      painter: _RangoliPainter(
                        filledPetals: _filledPetals,
                        totalPetals: _totalPetals,
                      ),
                      child: Stack(
                        children: List.generate(_totalPetals, (index) {
                          final angle =
                              (2 * pi / _totalPetals) * index - pi / 2;
                          final isOuter = index % 2 == 0;
                          final radius = isOuter ? 110.0 : 75.0;
                          final cx = 150 + radius * cos(angle);
                          final cy = 150 + radius * sin(angle);

                          return Positioned(
                            left: cx - 22,
                            top: cy - 22,
                            child: GestureDetector(
                              onTap: () => _fillPetal(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _filledPetals[index] ??
                                      Colors.white.withValues(alpha: 0.6),
                                  border: Border.all(
                                    color: _filledPetals.containsKey(index)
                                        ? _filledPetals[index]!
                                        : AppColors.textHint.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  boxShadow: _filledPetals.containsKey(index)
                                      ? [
                                          BoxShadow(
                                            color: _filledPetals[index]!
                                                .withValues(alpha: 0.4),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),

              // Color palette
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text('Pick a color',
                        style: AppTextStyles.labelMedium),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _palette.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 40 : 32,
                            height: isSelected ? 40 : 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.white, width: 3)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            color.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Tap petals to color them!',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangoliPainter extends CustomPainter {
  final Map<int, Color> filledPetals;
  final int totalPetals;

  _RangoliPainter({required this.filledPetals, required this.totalPetals});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.textHint.withValues(alpha: 0.2);

    // Draw concentric circles
    canvas.drawCircle(center, 40, paint);
    canvas.drawCircle(center, 75, paint);
    canvas.drawCircle(center, 110, paint);

    // Draw lines from center
    for (int i = 0; i < totalPetals; i++) {
      final angle = (2 * pi / totalPetals) * i - pi / 2;
      final end = Offset(
        center.dx + 120 * cos(angle),
        center.dy + 120 * sin(angle),
      );
      canvas.drawLine(center, end, paint);
    }

    // Draw center dot
    final centerPaint = Paint()
      ..color = AppColors.rangoliTheme
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 15, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
