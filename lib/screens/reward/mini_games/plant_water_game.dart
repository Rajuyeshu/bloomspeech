import 'dart:async';
import '../../../utils/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

/// Plant watering mini-game reward
class PlantWaterGame extends StatefulWidget {
  const PlantWaterGame({super.key});

  @override
  State<PlantWaterGame> createState() => _PlantWaterGameState();
}

class _PlantWaterGameState extends State<PlantWaterGame>
    with TickerProviderStateMixin {
  double _waterLevel = 0;
  int _growthStage = 0; // 0=seed, 1=sprout, 2=small, 3=medium, 4=full, 5=flower
  int _timeLeft = 60;
  Timer? _timer;
  bool _isWatering = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft <= 0) {
        timer.cancel();
        _showComplete();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _water() {
    setState(() {
      _waterLevel = (_waterLevel + 0.05).clamp(0, 1);
      if (_waterLevel >= 0.2 && _growthStage == 0) _growthStage = 1;
      if (_waterLevel >= 0.4 && _growthStage == 1) _growthStage = 2;
      if (_waterLevel >= 0.6 && _growthStage == 2) _growthStage = 3;
      if (_waterLevel >= 0.8 && _growthStage == 3) _growthStage = 4;
      if (_waterLevel >= 1.0 && _growthStage == 4) {
        _growthStage = 5;
        _showComplete();
      }
    });
  }

  void _showComplete() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_growthStage >= 5 ? '🌸 Beautiful!' : '🌱 Good Effort!'),
        content: Text(
          _growthStage >= 5
              ? 'Your plant bloomed into a beautiful flower!'
              : 'Your plant grew ${_growthStage} stages!',
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Done'.tr()),
          ),
        ],
      ),
    );
  }

  String _getPlantEmoji() {
    switch (_growthStage) {
      case 0: return '🟤'; // seed
      case 1: return '🌱'; // sprout
      case 2: return '🪴'; // small plant
      case 3: return '🌿'; // medium plant
      case 4: return '🌳'; // tree
      case 5: return '🌸'; // flower
      default: return '🌱';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE8F5E9),
              Color.lerp(const Color(0xFFC8E6C9), const Color(0xFF81C784), _waterLevel)!,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('🌱 Stage: $_growthStage/5',
                          style: AppTextStyles.titleMedium),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('⏱ ${_timeLeft}s',
                          style: AppTextStyles.titleMedium),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Plant
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _getPlantEmoji(),
                  key: ValueKey(_growthStage),
                  style: TextStyle(fontSize: 80 + (_growthStage * 15).toDouble()),
                ),
              ),

              const SizedBox(height: 20),

              // Water progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text('Water Level'.tr(),
                        style: AppTextStyles.labelMedium),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _waterLevel,
                        minHeight: 14,
                        backgroundColor: Colors.white.withValues(alpha: 0.5),
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Water button
              GestureDetector(
                onTapDown: (_) => setState(() => _isWatering = true),
                onTapUp: (_) => setState(() => _isWatering = false),
                onTap: _water,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: _isWatering ? 110 : 120,
                  height: _isWatering ? 110 : 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.info.withValues(alpha: 0.4),
                        blurRadius: _isWatering ? 8 : 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💧', style: TextStyle(fontSize: 36)),
                      Text(
                        'Water!'.tr(),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Tap to water your plant!'.tr(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
