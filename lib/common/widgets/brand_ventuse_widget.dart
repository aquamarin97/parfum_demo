import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';


class VentuseText extends StatelessWidget {
  final String text;
  const VentuseText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.headline.copyWith(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.underline,
        decorationThickness: 1.5,
      ),
    );
  }
}