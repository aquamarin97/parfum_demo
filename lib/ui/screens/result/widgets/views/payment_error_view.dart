import 'package:flutter/material.dart';
import 'package:parfume_app/ui/components/primary_button.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../../../../viewmodel/result_view_model.dart';

/// Shown when payment fails, offering retry and cancel options.
class PaymentErrorView extends StatelessWidget {
  const PaymentErrorView({super.key, required this.viewModel});

  final ResultViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = viewModel.strings;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.spacingM),
        const Icon(
          Icons.error_outline,
          size: AppSizes.regularIconSize,
          color: AppColors.error,
        ),
        Text(
          strings.t('retry_or_cancel'),
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.bold, fontSize: AppSizes.fontMainBody),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingXS),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: strings.t('retry_payment'),
                onPressed: viewModel.retryPayment,
                fontSize: AppSizes.fontBody,
                paddingHorizontal: AppSizes.spacingXL,
                paddingvertical: AppSizes.spacingM,
              ),
            ),
            const SizedBox(width: AppSizes.spacingL),
            Expanded(
              child: OutlinedButton(
                onPressed: viewModel.cancelToIdle,
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
                  strings.t('cancel_payment'),
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
