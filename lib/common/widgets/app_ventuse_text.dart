import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

/// Renders the Ventusé brand name with its signature Montserrat font and
/// underline decoration.
///
/// Used inline within [Text.rich] spans on the idle screen.
class AppVentuseText extends StatelessWidget {
  const AppVentuseText({super.key, required this.text});

  /// The brand name string to display.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.headline.copyWith(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.underline,
        decorationThickness: AppSizes.underlineThickness,
      ),
    );
  }
}