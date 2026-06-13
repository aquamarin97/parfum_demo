import 'package:flutter/material.dart';
import 'package:parfume_app/ui/screens/result/widgets/shared/countdown_timer.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../../../../viewmodel/result_view_model.dart';

class WaitingPaymentView extends StatelessWidget {
  const WaitingPaymentView({super.key, required this.viewModel});

  final ResultViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = viewModel.strings;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.spacingM),
        Text(
          viewModel.priceLabel,
          style: AppTextStyles.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingM),
        CountdownTimer(timerNotifier: viewModel.timerNotifier),
        const SizedBox(height: AppSizes.spacingL),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: viewModel.backToTesterSelection,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.warningAmberDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.spacingM,
                  ),
                  side: const BorderSide(
                    color: AppColors.warningAmberDark,
                    width: AppSizes.testerButtonBorderNormal,
                  ),
                ),
                child: Text(
                  strings.t('change_selection'),
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
                onPressed: viewModel.cancelToIdle,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
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