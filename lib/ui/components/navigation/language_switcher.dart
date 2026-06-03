import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';

import '../../../data/models/language.dart';
import '../../theme/app_colors.dart';

/// Horizontal language selector shown in the bottom-right corner of the
/// kiosk shell.
///
/// Always renders left-to-right regardless of the active locale so the
/// button order stays predictable on RTL screens.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({
    super.key,
    required this.selected,
    required this.available,
    required this.onSelect,
  });

  /// The currently active language.
  final Language selected;

  /// All languages available for selection.
  final List<Language> available;

  /// Called when the user selects a language.
  final ValueChanged<Language> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.radioOptionPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowExtraLight,
            blurRadius: AppSizes.languageSwitcherShadowBlur,
            offset: Offset(0, AppSizes.languageSwitcherShadowOffsetY),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // Always LTR so button order is predictable on RTL screens.
        textDirection: TextDirection.ltr,
        children: available.map((language) {
          final isSelected = language == selected;
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.languageSwitcherButtonSpacing,
            ),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    isSelected ? AppColors.primary : null,
                foregroundColor:
                    isSelected ? Colors.white : AppColors.textPrimary,
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              onPressed: () => onSelect(language),
              child: Text(language.label),
            ),
          );
        }).toList(),
      ),
    );
  }
}