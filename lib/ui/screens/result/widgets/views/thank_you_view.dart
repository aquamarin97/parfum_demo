import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../result_view_model.dart';

class ThankYouView extends StatelessWidget {
  const ThankYouView({super.key, required this.viewModel}); // ✅ ViewModel ekle

  final ResultViewModel viewModel; // ✅

  @override
  Widget build(BuildContext context) {
    final strings = viewModel.strings; // ✅

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.elasticOut,
                      builder: (context, scaleValue, _) {
                        return Transform.scale(
                          scale: scaleValue,
                          child: Icon(
                            Icons.favorite,
                            size: 100,
                            color: const Color.fromARGB(255, 31, 207, 40).withOpacity(0.85),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    Text(
                      strings.thankYouMessage, // ✅
                      style: AppTextStyles.title.copyWith(
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 50,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      strings.goodbyeMessage, // ✅
                      style: AppTextStyles.body.copyWith(
                        fontFamily: 'NotoSans',
                        fontSize: 40,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}