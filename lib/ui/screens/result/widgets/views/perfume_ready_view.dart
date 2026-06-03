import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';

/// Shown when the perfume dispenser has finished — displays an animated
/// success icon.
class PerfumeReadyView extends StatelessWidget {
  const PerfumeReadyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.spacingXXL),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: const Icon(
              Icons.check_circle_outline,
              size: AppSizes.regularIconSize,
              color: AppColors.success,
            ),
          ),
        ),
      ],
    );
  }
}