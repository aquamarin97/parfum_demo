import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parfume_app/ui/screens/result/widgets/shared/countdown_timer.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../../../../viewmodel/result_view_model.dart';

/// Shown while the kiosk is waiting for the customer to complete payment.
///
/// Provides three actions:
/// 1. Go back to tester selection (wrong choice).
/// 2. Cancel the entire flow.
/// 3. Complete payment (handled by PLC or debug buttons).
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
          strings.t('price_label'),
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
        if (kDebugMode) ...[
          const SizedBox(height: AppSizes.spacingL),
          _DebugPaymentControls(viewModel: viewModel),
        ],
      ],
    );
  }
}

/// Manual payment trigger buttons shown only in debug builds.
class _DebugPaymentControls extends StatelessWidget {
  const _DebugPaymentControls({required this.viewModel});

  final ResultViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: viewModel.onPaymentComplete,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingL,
                vertical: AppSizes.spacingS,
              ),
            ),
            child: Text(
              'TEST: Payment OK',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spacingS),
        Expanded(
          child: ElevatedButton(
            onPressed: viewModel.onPaymentError,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingL,
                vertical: AppSizes.spacingS,
              ),
            ),
            child: Text(
              'TEST: Payment Error',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}