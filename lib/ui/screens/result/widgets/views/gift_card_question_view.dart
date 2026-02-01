import 'package:flutter/material.dart';
import 'package:parfume_app/ui/components/primary_button.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../result_view_model.dart';

class GiftCardQuestionView extends StatelessWidget {
  const GiftCardQuestionView({super.key, required this.viewModel});

  final ResultViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = viewModel.strings; // ✅

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        
        Text(
          strings.giftCardQuestion, // ✅
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
              label: strings.yes, // ✅
              onPressed: () => viewModel.onGiftCardAnswer(true),
              fontSize: 50,
              paddingHorizontal: 120,
              paddingvertical: 24,
            ),
            
            const SizedBox(width: 24),
            
            OutlinedButton(
              onPressed: () => viewModel.onGiftCardAnswer(false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 100,
                  vertical: 24,
                ),
                side: const BorderSide(color: AppColors.border, width: 2),
              ),
              child: Text(
                strings.no, // ✅
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