// thank_you_view.dart
import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';


class ThankYouView extends StatelessWidget {
  const ThankYouView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Column(
                  children: [
                    // Başarı ikonu
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
                            color: AppColors.primary.withOpacity(0.85),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Ana mesaj
                    Text(
                      "Güzel günlerde kullanın",
                      style: AppTextStyles.title.copyWith(
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Alt mesaj
                    Text(
                      "Size özel kokunuz hazır!\nİyi günler dileriz...",
                      style: AppTextStyles.body.copyWith(
                        fontFamily: 'NotoSans',
                        fontSize: 20,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Küçük not / teşvik (isteğe bağlı)
                    Opacity(
                      opacity: 0.7,
                      child: Text(
                        "Kokunuzu en kısa sürede teslim alabilirsiniz",

                        textAlign: TextAlign.center,
                      ),
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