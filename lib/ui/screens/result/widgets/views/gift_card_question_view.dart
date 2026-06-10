import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../../../../viewmodel/result_view_model.dart';

/// Asks the customer whether they would like a gift card.
class GiftCardQuestionView extends StatelessWidget {
  const GiftCardQuestionView({super.key, required this.viewModel});

  final ResultViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = viewModel.strings;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.spacingL),
        Text(
          strings.t('gift_card_question'),
          style: AppTextStyles.topHeader,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingL),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => viewModel.onGiftCardAnswer(true),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.warningAmberDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingXL,
                    vertical: AppSizes.spacingM,
                  ),
                  side: const BorderSide(
                    color: AppColors.warningAmberDark,
                    width: AppSizes.testerButtonBorderNormal,
                  ),
                ),
                child: Text(
                  strings.t('yes'),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spacingL),
            Expanded(
              child: OutlinedButton(
                onPressed: () => viewModel.onGiftCardAnswer(false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingXL,
                    vertical: AppSizes.spacingM,
                  ),
                  side: const BorderSide(
                    color: AppColors.border,
                    width: AppSizes.testerButtonBorderNormal,
                  ),
                ),
                child: Text(
                  strings.t('no'),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
