import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system for BloomSpeech
class AppTextStyles {
  AppTextStyles._();

  // ─── Display (Splash, Reward Screens) ───
  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle displaySmall = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ─── Headings ───
  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle headlineSmall = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ─── Title ───
  static TextStyle titleLarge = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle titleMedium = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle titleSmall = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ─── Body ───
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ─── Label ───
  static TextStyle labelLarge = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static TextStyle labelMedium = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // ─── Special Styles ───
  static TextStyle tokenCount = GoogleFonts.poppins(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.tokenGold,
    height: 1.1,
  );

  static TextStyle feedbackText = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.3,
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.4,
  );

  static TextStyle chipText = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    height: 1.3,
  );

  static TextStyle statValue = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle statLabel = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
    height: 1.3,
    letterSpacing: 0.8,
  );

  // ─── Kannada Text ───
  static TextStyle kannadaBody = const TextStyle(
    fontFamily: 'NotoSansKannada',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static TextStyle kannadaFeedback = const TextStyle(
    fontFamily: 'NotoSansKannada',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.4,
  );
}
