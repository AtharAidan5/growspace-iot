import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/plant.dart';

/// Dark, plant-forward palette: deep green-black surfaces, neon lime accent.
class AppColors {
  static const background = Color(0xFF0C1310);
  static const surface = Color(0xFF16201B);
  static const surfaceLight = Color(0xFF1F2C26);
  static const accent = Color(0xFFB6F09C); // neon lime
  static const accentDim = Color(0xFF5C8A4A);
  static const textPrimary = Color(0xFFF2F7F0);
  static const textSecondary = Color(0xFF8FA396);

  static const healthy = Color(0xFF6EE7A0);
  static const dry = Color(0xFFFFA94D);
  static const wet = Color(0xFF74C0FC);
  static const hot = Color(0xFFFF6B6B);
  static const cold = Color(0xFF66D9E8);
  static const unknown = Color(0xFF868E96);
}

Color statusColor(PlantStatus status) {
  switch (status) {
    case PlantStatus.healthy:
      return AppColors.healthy;
    case PlantStatus.dry:
      return AppColors.dry;
    case PlantStatus.wet:
      return AppColors.wet;
    case PlantStatus.hot:
      return AppColors.hot;
    case PlantStatus.cold:
      return AppColors.cold;
    case PlantStatus.unknown:
      return AppColors.unknown;
  }
}

String statusLabel(PlantStatus status) {
  switch (status) {
    case PlantStatus.healthy:
      return 'Thriving';
    case PlantStatus.dry:
      return 'Thirsty';
    case PlantStatus.wet:
      return 'Soaked';
    case PlantStatus.hot:
      return 'Too hot';
    case PlantStatus.cold:
      return 'Too cold';
    case PlantStatus.unknown:
      return 'No data';
  }
}

String statusEmoji(PlantStatus status) {
  switch (status) {
    case PlantStatus.healthy:
      return '🌱';
    case PlantStatus.dry:
      return '🏜️';
    case PlantStatus.wet:
      return '💧';
    case PlantStatus.hot:
      return '🥵';
    case PlantStatus.cold:
      return '🥶';
    case PlantStatus.unknown:
      return '📡';
  }
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.accentDim,
      surface: AppColors.surface,
      background: AppColors.background,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}
