import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

/// Primary action button used throughout the kiosk UI.
///
/// Defaults to the standard kiosk button size; callers may override
/// [fontSize], [paddingHorizontal], and [paddingVertical] for context-specific
/// layouts. Pass `enabled: false` or `onPressed: null` to disable.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = AppSizes.fontButton,
    this.enabled = true,
    this.paddingHorizontal = AppSizes.buttonPaddingH,
    this.paddingVertical = AppSizes.buttonPaddingV,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final double fontSize;
  final double paddingHorizontal;
  final double paddingVertical;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: paddingHorizontal,
          vertical: paddingVertical,
        ),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: AppTextStyles.button.copyWith(fontSize: fontSize),
      ),
    );
  }
}