import 'package:flutter/material.dart';
import 'package:parfume_app/ui/components/primary_button.dart';
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
        Text(
          strings.t('gift_card_question'),
          style: AppTextStyles.title.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: strings.t('yes'),
                onPressed: () => viewModel.onGiftCardAnswer(true),
                fontSize: AppSizes.fontBody,
                paddingHorizontal: AppSizes.spacingXL,
                paddingvertical: AppSizes.spacingM,
              ),
            ),
            const SizedBox(width: AppSizes.spacingM),
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
                    fontSize: AppSizes.fontBody,
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