import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Màu lấy từ ElytraPalette trong Elytra.fig
class AppColors {
  const AppColors._();

  static const primary = Color(0xFF16A34A);
  static const primaryDark = Color(0xFF15803D);
  static const primaryContainer = Color(0xFFDCFCE7);
  static const primaryDisabled = Color(0x6616A34A); // primary, độ đậm 40%
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const outline = Color(0xFFE8EEF4);
  static const sliderInactive = Color(0xFFE2E8F0); // phần chưa chọn của thanh trượt
  static const outlineStrong = Color(0xFFCBD5E1);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF334155);
  static const textMuted = Color(0xFF64748B);
  static const textSubtle = Color(0xFF94A3B8);
  static const error = Color(0xFFE11D48);
  static const errorContainer = Color(0xFFFFE4E6);
}

/// Theme chung: font Be Vietnam Pro, màu chủ đạo xanh lá, nền xám nhạt
ThemeData buildAppTheme() => ThemeData(
      // Lấy tên font từ google_fonts rồi đặt cho cả app
      fontFamily: GoogleFonts.beVietnamPro().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        error: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
