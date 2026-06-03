import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parfume_app/ui/screens/result/widgets/shared/countdown_timer.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../../../../viewmodel/result_view_model.dart';

/// Shown while the kiosk is waiting for the customer to complete payment.
///
/// Displays the price, a countdown timer, and — in debug builds only —
/// manual trigger buttons for payment success and failure.
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
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingL),
        CountdownTimer(timerNotifier: viewModel.timerNotifier),
        const SizedBox(height: AppSizes.spacingXL),
        if (kDebugMode) _DebugPaymentControls(viewModel: viewModel),
      ],
    );
  }
}

/// Manual payment trigger buttons shown only in debug builds.
///
/// Not compiled into release builds — guarded by [kDebugMode].
class _DebugPaymentControls extends StatelessWidget {
  const _DebugPaymentControls({required this.viewModel});

  final ResultViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: viewModel.onPaymentComplete,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingL,
              vertical: AppSizes.spacingS,
            ),
          ),
          child: Text('TEST: Payment OK', style: AppTextStyles.body.copyWith(color: Colors.white)),
        ),
        const SizedBox(width: AppSizes.spacingS),
        ElevatedButton(
          onPressed: viewModel.onPaymentError,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
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
      ],
    );
  }
}
