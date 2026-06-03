import 'package:flutter/material.dart';
import 'package:parfume_app/core/constants/app_constants.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

/// Displays a mm:ss countdown driven by [timerNotifier].
///
/// Switches to an urgent visual style (red border and text) when the
/// remaining time drops below [AppConstants.timerUrgentThreshold] seconds.
class CountdownTimer extends StatelessWidget {
  const CountdownTimer({super.key, required this.timerNotifier});

  final ValueNotifier<int> timerNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: timerNotifier,
      builder: (context, remainingSeconds, child) {
        final minutes = remainingSeconds ~/ 60;
        final seconds = remainingSeconds % 60;
        final isUrgent = remainingSeconds < AppConstants.timerUrgentThreshold;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.timerPaddingH,
            vertical: AppSizes.timerPaddingV,
          ),
          decoration: BoxDecoration(
            color: isUrgent
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            border: Border.all(
              color: isUrgent ? AppColors.error : AppColors.border,
              width: AppSizes.timerBorderWidth,
            ),
          ),
          child: Text(
            '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}',
            style: AppTextStyles.headline.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.timerFontSize,
              color: isUrgent ? AppColors.error : AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}
