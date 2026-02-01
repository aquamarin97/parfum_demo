import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';


class CountdownTimer extends StatelessWidget {
  const CountdownTimer({
    super.key,
    required this.timerNotifier,
  });

  final ValueNotifier<int> timerNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: timerNotifier,
      builder: (context, remainingSeconds, child) {
        final minutes = remainingSeconds ~/ 60;
        final seconds = remainingSeconds % 60;
        final isUrgent = remainingSeconds < 60;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isUrgent
                ? AppColors.error.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUrgent ? AppColors.error : AppColors.border,
              width: 2,
            ),
          ),
          child: Text(
            "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
            style: AppTextStyles.headline.copyWith(
              fontFamily: 'NotoSans',
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: isUrgent ? AppColors.error : AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}