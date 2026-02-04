// plc_error_screen.dart - FIXED LAYOUT
import 'package:flutter/material.dart';
import 'package:parfume_app/plc/error/plc_error_codes.dart';
import 'package:parfume_app/ui/components/primary_button.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../viewmodel/app_view_model.dart';

class PLCErrorScreen extends StatelessWidget {
  const PLCErrorScreen({
    super.key,
    required this.viewModel,
    required this.errorCode,
    required this.errorMessage,
    this.technicalDetail,
    this.onRetry,
  });

  final AppViewModel viewModel;
  final int errorCode;
  final String errorMessage;
  final String? technicalDetail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = viewModel.strings;
    final showTechnicalDetails = _shouldShowTechnicalDetails();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        size: 120,
                        color: AppColors.error,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),

              // Error title
              Text(
                strings.errorTitle,
                style: AppTextStyles.title.copyWith(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // User-friendly error message
              Text(
                errorMessage,
                style: AppTextStyles.body.copyWith(
                  fontFamily: 'NotoSans',
                  fontSize: 45,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Error code
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  'Hata Kodu: $errorCode',
                  style: AppTextStyles.body.copyWith(
                    fontFamily: 'Courier',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),

              // Technical details (if enabled)
              if (showTechnicalDetails && technicalDetail != null) ...[
                const SizedBox(height: 32),
                _buildTechnicalDetailsCard(),
              ],

              const SizedBox(height: 48),

              // ✅ Action buttons - FIXED LAYOUT
              // Ekranın %80'ini kullan, butonları Flexible/Expanded yap
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Row(
                  children: [
                    if (onRetry != null) ...[
                      Flexible(
                        child: PrimaryButton(
                          label: 'Tekrar Dene',
                          onPressed: onRetry,
                          fontSize: 45, // 50 → 45 (biraz küçült)
                          paddingHorizontal: 60, // 80 → 60
                          paddingvertical: 20, // 24 → 20
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                    Flexible(
                      child: OutlinedButton(
                        onPressed: viewModel.resetToIdle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 60, // 80 → 60
                            vertical: 20, // 24 → 20
                          ),
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          strings.backToStart,
                          style: AppTextStyles.body.copyWith(
                            fontFamily: 'NotoSans',
                            fontSize: 45, // 50 → 45
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicalDetailsCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.textSecondary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Teknik Detaylar',
                style: AppTextStyles.body.copyWith(
                  fontFamily: 'NotoSans',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            PLCErrorCodes.getTechnicalDescription(errorCode),
            style: AppTextStyles.body.copyWith(
              fontFamily: 'NotoSans',
              fontSize: 32,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          if (technicalDetail != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                technicalDetail!,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 28,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _shouldShowTechnicalDetails() {
    // Production'da false, debug modda true
    return true; // Şimdilik her zaman göster
  }
}