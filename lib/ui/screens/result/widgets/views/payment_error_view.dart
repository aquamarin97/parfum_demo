import 'package:flutter/material.dart';
import 'package:parfume_app/ui/components/primary_button.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../result_view_model.dart';

class PaymentErrorView extends StatelessWidget {
  const PaymentErrorView({super.key, required this.viewModel});

  final ResultViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = viewModel.strings; // ✅

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 30),

        const Icon(Icons.error_outline, size: 80, color: AppColors.error),

        const SizedBox(height: 10),

        Text(
          strings.retryOrCancel, // ✅
          style: AppTextStyles.title.copyWith(
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrimaryButton(
              label: strings.retryPayment, // ✅
              onPressed: viewModel.retryPayment,
              fontSize: 50,
              paddingHorizontal: 48,
              paddingvertical: 24,
            ),

            const SizedBox(width: 32),

            OutlinedButton(
              onPressed: viewModel.cancelToIdle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 148,
                  vertical: 24,
                ),
                side: const BorderSide(color: AppColors.border, width: 2),
              ),
              child: Text(
                strings.cancelPayment, // ✅
                style: AppTextStyles.body.copyWith(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
