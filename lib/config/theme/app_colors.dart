import 'package:flutter/material.dart';

/// BloomSpeech color palette — warm, child-friendly, Indian-inspired
class AppColors {
  AppColors._();

  // ─── Primary Palette (Saffron & Teal) ───
  static const Color primary = Color(0xFF6C63FF);       // Soft violet
  static const Color primaryLight = Color(0xFF9B94FF);
  static const Color primaryDark = Color(0xFF4A42DB);

  static const Color secondary = Color(0xFFFF6B6B);     // Warm coral
  static const Color secondaryLight = Color(0xFFFF9B9B);
  static const Color secondaryDark = Color(0xFFE54545);

  static const Color accent = Color(0xFFFFB347);        // Golden saffron
  static const Color accentLight = Color(0xFFFFD08A);
  static const Color accentDark = Color(0xFFE89920);

  // ─── Semantic Colors ───
  static const Color success = Color(0xFF4CAF50);       // Fluent / Smooth
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color successSurface = Color(0xFFC8E6C9);

  static const Color warning = Color(0xFFFF9800);       // Alert / Attention
  static const Color warningLight = Color(0xFFFFF3E0);

  static const Color error = Color(0xFFFF7043);         // Dysfluent / Bumpy (warm, non-punitive)
  static const Color errorLight = Color(0xFFFBE9E7);
  static const Color errorSurface = Color(0xFFFFCCBC);

  static const Color info = Color(0xFF29B6F6);
  static const Color infoLight = Color(0xFFE1F5FE);

  // ─── Therapy-Specific Colors ───
  static const Color smoothGreen = Color(0xFF66BB6A);   // Smooth speech button
  static const Color smoothGreenDark = Color(0xFF43A047);
  static const Color bumpyOrange = Color(0xFFFF8A65);   // Bumpy speech button
  static const Color bumpyOrangeDark = Color(0xFFE64A19);

  // ─── Token Board Colors ───
  static const Color tokenGold = Color(0xFFFFD700);
  static const Color tokenEmpty = Color(0xFFE0E0E0);
  static const Color tokenGlow = Color(0xFFFFF8E1);

  // ─── Background & Surface ───
  static const Color background = Color(0xFFF8F6FF);    // Very light violet tint
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F0FF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ─── Dark Theme ───
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF252547);
  static const Color darkSurfaceVariant = Color(0xFF2D2D5E);
  static const Color darkCard = Color(0xFF2A2A4A);

  // ─── Text Colors ───
  static const Color textPrimary = Color(0xFF2D2D3F);
  static const Color textSecondary = Color(0xFF6B6B80);
  static const Color textHint = Color(0xFF9E9EB5);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFE8E8F0);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9B94FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFFB347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient smoothGradient = LinearGradient(
    colors: [Color(0xFF66BB6A), Color(0xFF81C784)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient bumpyGradient = LinearGradient(
    colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient celebrationGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4A42DB), Color(0xFF2D2D5E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Level Colors ───
  static const Color levelWord = Color(0xFF66BB6A);
  static const Color levelSentence = Color(0xFF42A5F5);
  static const Color levelContinuous = Color(0xFFAB47BC);
  static const Color levelNarrative = Color(0xFFFF7043);
  static const Color levelConversational = Color(0xFFFFCA28);

  // ─── Theme Accent Colors (for play themes) ───
  static const Color diyaTheme = Color(0xFFFF9800);
  static const Color rangoliTheme = Color(0xFFE91E63);
  static const Color mangoTheme = Color(0xFF4CAF50);
  static const Color peacockTheme = Color(0xFF00BCD4);
  static const Color lotusTheme = Color(0xFFFF4081);
  static const Color kiteTheme = Color(0xFF7C4DFF);
}
