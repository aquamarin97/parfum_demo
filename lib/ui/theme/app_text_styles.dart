// app_text_styles.dart file
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizes.dart';

/// Centralized text styles used by the app theme and shared widgets.
class AppTextStyles {
  // Font aile ismini bir değişkende tutmak yönetimi kolaylaştırır
  static const String _fontFamily = 'NotoSans';

  static const TextStyle headline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppSizes.fontHeadline,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppSizes.fontTitle,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle topHeader = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppSizes.fontTopHeader,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppSizes.fontBody,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppSizes.fontLabel,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppSizes.fontButton,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppSizes.fontHint,
    color: AppColors.textSecondary,
  );

  // TOP BAR STYLES
  static const TextStyle topBarTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppSizes.fontTopBar,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle topBarAction = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppSizes.fontTopBar,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
