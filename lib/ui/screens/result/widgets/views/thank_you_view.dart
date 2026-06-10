import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../../../../viewmodel/result_view_model.dart';

/// Final screen of the result flow — thanks the customer and shows
/// a farewell message.
class ThankYouView extends StatelessWidget {
  const ThankYouView({super.key, required this.viewModel});

  final ResultViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = viewModel.strings;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.spacingL),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, AppSizes.thankYouSlideOffset * (1 - value)),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.elasticOut,
                    builder: (context, scaleValue, _) => Transform.scale(
                      scale: scaleValue,
                      child: Icon(
                        Icons.favorite,
                        size: AppSizes.regularIconSize,
                        color: AppColors.success.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  Text(
                    strings.t('thank_you_message'),
                    style: AppTextStyles.topHeader,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  Text(
                    strings.t('goodbye_message'),
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}