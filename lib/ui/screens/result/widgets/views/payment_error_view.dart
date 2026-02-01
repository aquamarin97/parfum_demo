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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 80, color: AppColors.error),
        const SizedBox(height: 32),
        Text(
          "Lütfen tekrar deneyin veya iptal edin",
          style: AppTextStyles.title.copyWith(
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrimaryButton(
              label: "Tekrar Deneyin",
              onPressed: viewModel.retryPayment,
            ),
            const SizedBox(width: 24),
            OutlinedButton(
              onPressed: viewModel.cancelToIdle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 24,
                ),
                side: const BorderSide(color: AppColors.border, width: 2),
              ),
              child: Text(
                "İptal Et",
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