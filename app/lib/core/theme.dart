import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Màu lấy từ ElytraPalette trong Elytra.fig
class AppColors {
  const AppColors._();

  static const primary = Color(0xFF16A34A);
  static const primaryDark = Color(0xFF15803D); // nền nút chính chữ trắng
  static const primaryContainer = Color(0xFFDCFCE7);
  static const primarySurface = Color(0xFFF0FDF4);
  static const primaryOutline = Color(0xFFBBF7D0);
  static const primaryDisabled = Color(0x6615803D); // primaryDark, độ đậm 40%
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF8FAFC);
  static const outline = Color(0xFFE8EEF4);
  static const sliderInactive = Color(0xFFE2E8F0); // phần chưa chọn của thanh trượt
  static const outlineStrong = Color(0xFFD1DCE8);
  static const placeholder = Color(0xFFCBD5E1);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF334155);
  static const textMuted = Color(0xFF5B6B80);
  static const textSubtle = Color(0xFF94A3B8); // chỉ cho icon/đường kẻ, không dùng cho chữ
  static const error = Color(0xFFE11D48);
  static const errorContainer = Color(0xFFFFE4E6);
  static const onErrorContainer = Color(0xFFBE123C);

  // Màu theo chất đa lượng
  static const protein = Color(0xFF0284C7);
  static const proteinContainer = Color(0xFFE0F2FE);
  static const onProteinContainer = Color(0xFF075985);
  static const proteinOutline = Color(0xFFBAE6FD);
  static const carbs = Color(0xFFD97706);
  static const carbsContainer = Color(0xFFFEF3C7);
  static const onCarbsContainer = Color(0xFF92400E);
  static const carbsOutline = Color(0xFFFDE68A);
  static const fat = Color(0xFF6366F1);
  static const fatContainer = Color(0xFFEEF2FF);
  static const onFatContainer = Color(0xFF4F46E5);
  static const fatOutline = Color(0xFFC7D2FE);
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
