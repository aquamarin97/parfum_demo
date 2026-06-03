import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

/// Outlined variant of the primary kiosk button.
///
/// Matches [PrimaryButton] in size and shape but uses a transparent
/// background with a coloured border. Pass `enabled: false` or
/// `onPressed: null` to disable.
class PrimaryOutlinedButton extends StatelessWidget {
  const PrimaryOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = AppSizes.fontBody,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.buttonPaddingH,
          vertical: AppSizes.buttonPaddingV,
        ),
        shape: const StadiumBorder(),
        side: const BorderSide(
          color: AppColors.primary,
          width: AppSizes.outlinedButtonBorderWidth,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.button.copyWith(
          fontSize: fontSize,
          color: AppColors.primary,
        ),
      ),
    );
  }
}