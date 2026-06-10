import 'package:flutter/material.dart';
import 'package:parfume_app/core/constants/app_constants.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

/// A selectable perfume tester button shown on the [TestersReadyView].
///
/// Animates in with a staggered scale effect based on [index].
/// Transitions between selected and unselected states via [AnimatedContainer].
/// Background stays white in both states so the button remains visible
/// against the logo background.
class TesterButton extends StatelessWidget {
  const TesterButton({
    super.key,
    required this.index,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(
        milliseconds: AppConstants.testerButtonBaseDelay +
            (index * AppConstants.testerButtonStaggerDelay),
      ),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: AppSizes.testerButtonSize,
          height: AppSizes.testerButtonSize,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.warningAmberDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.testerButtonRadius),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected
                  ? AppSizes.testerButtonBorderSelected
                  : AppSizes.testerButtonBorderNormal,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: AppSizes.testerButtonBlurRadius,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          // Material + InkWell inside so ripple is visible over the decoration.
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.testerButtonRadius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSizes.testerButtonRadius),
              splashColor: AppColors.primary.withValues(alpha: 0.2),
              highlightColor: AppColors.primary.withValues(alpha: 0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.headline.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.testerButtonFontSize,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXS),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}