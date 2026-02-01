// app_text_styles.dart file
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Font aile ismini bir değişkende tutmak yönetimi kolaylaştırır
  static const String _fontFamily = 'NotoSans';

  static const TextStyle headline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 100,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 80,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 50,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 42,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 100,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    color: AppColors.textSecondary,
  );

  // TOP BAR STYLES
  static const TextStyle topBarTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 50,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle topBarAction = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 50,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
