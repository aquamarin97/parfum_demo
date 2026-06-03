// app_colors.dart file
import 'package:flutter/material.dart';

/// Centralized color palette used across the app UI.
class AppColors {
  // Background
  static const Color background = Color(0xFFFFFDEE);

  // Brand / Primary
  static const Color primary = Color(0xFFEE741E);

  // Text
  static const Color textPrimary = Color(0xFFEC751B);
  static const Color textSecondary = Color(0xFFEC751B); // istersen sonra açarız
  static const Color buttonText = Color(0xFFFAFEEC);

  // Surfaces & UI
  static const Color surface = Color(0xFFFAFEEC);
  static const Color border = Color(0xFFEE741E);

  // Optional / legacy (şimdilik tutulabilir)
  static const Color secondary = Color(0xFFEE741E);
  static const Color accent = Color(0xFFEE741E);
  static const Color error = Color(0xFFB91C1C);

  static const Color underline = Color(0xFFDFC4A5);
  static const Color success = Color(0xFF38A169); // Yeşil

  // Logo painter colors
  static const Color logoPrimary = Color(0xFFF18142);
  static const Color logoSecondary = Color(0xFFEE741E);

  // Scent wave colors
  static const Color waveOrange = Color(0xFFF18142);
  static const Color wavePurple = Color(0xFF3C0F77);
}
