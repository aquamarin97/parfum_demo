import 'package:flutter/material.dart';
import 'package:parfume_app/core/constants/app_constants.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

/// A selectable perfume tester button shown on the [TestersReadyView].
///
/// Animates in with a staggered scale effect based on [index].
/// Transitions between selected and unselected states via [AnimatedContainer].
class TesterButton extends StatelessWidget {
  const TesterButton({
    super.key,
    required this.index,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  /// Zero-based position used for staggered entry animation timing.
  final int index;

  /// Large numeral displayed at the centre of the button (e.g. `'1'`).
  final String label;

  /// Whether this button is currently selected.
  final bool isSelected;

  /// Called when the user taps the button.
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
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.testerButtonRadius),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: AppSizes.testerButtonSize,
              height: AppSizes.testerButtonSize,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppSizes.testerButtonRadius),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.headline.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.testerButtonFontSize,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXS),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}