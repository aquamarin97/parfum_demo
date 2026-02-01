import 'package:flutter/material.dart';
import 'package:parfume_app/ui/screens/result/widgets/components/countdown_timer.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../result_view_model.dart';

class WaitingPaymentView extends StatelessWidget {
  const WaitingPaymentView({super.key, required this.viewModel});

  final ResultViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Fiyat: 490 TL",
          style: AppTextStyles.headline.copyWith(
            fontFamily: 'NotoSans',
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        CountdownTimer(timerNotifier: viewModel.timerNotifier),

        const SizedBox(height: 48),

        // Test butonları (DEBUG MODE)
        if (true) // Production'da false yapın
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: viewModel.onPaymentComplete,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text("TEST:Ödeme Tamam", style: TextStyle(fontSize: 50),),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: viewModel.onPaymentError,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text("TEST:Ödeme Hata", style: TextStyle(fontSize: 50)),
              ),
            ],
          ),
      ],
    );
  }
}
