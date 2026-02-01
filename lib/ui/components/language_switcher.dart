// language_switcher.dart file
import 'package:flutter/material.dart';

import '../../data/models/language.dart';
import '../theme/app_colors.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final Language selected;
  final ValueChanged<Language> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: Language.values.map((language) {
          final isSelected = language == selected;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected ? AppColors.primary : null,
                foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
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