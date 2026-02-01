import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';


class PerfumeReadyView extends StatelessWidget {
  const PerfumeReadyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: const Icon(
                Icons.check_circle_outline,
                size: 120,
                color: AppColors.success,
              ),
            );
          },
        ),
      ],
    );
  }
}