import 'package:flutter/material.dart';
import 'package:parfume_app/data/plc/plc_error_asset_source.dart';
import 'package:parfume_app/domain/plc/i_plc_error_string_source.dart';
import 'package:parfume_app/domain/plc/plc_exceptions.dart';
import 'package:parfume_app/ui/components/primary_button.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../../viewmodel/app_view_model.dart';

/// Displays a PLC fault screen with a localised error message.
///
/// The message is loaded asynchronously from [errorStringSource] using
/// [languageCode]. While loading, or if the source returns no data for the
/// given [errorCode], [PLCErrorCodes.getTechnicalDescription] is used as a
/// fallback.
class PLCErrorScreen extends StatefulWidget {
  const PLCErrorScreen({
    super.key,
    required this.viewModel,
    required this.errorCode,
    required this.languageCode,
    this.technicalDetail,
    this.onRetry,
    this.errorStringSource = const PlcErrorAssetSource(),
  });

  final AppViewModel viewModel;
  final int errorCode;
  final String languageCode;
  final String? technicalDetail;
  final VoidCallback? onRetry;

  /// Source for localised error messages. Defaults to the bundled asset source.
  final IPlcErrorStringSource errorStringSource;

  @override
  State<PLCErrorScreen> createState() => _PLCErrorScreenState();
}

class _PLCErrorScreenState extends State<PLCErrorScreen> {
  late final Future<Map<int, String>?> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _messagesFuture = widget.errorStringSource.load(widget.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<int, String>?>(
      future: _messagesFuture,
      builder: (context, snapshot) {
        final message = snapshot.data?[widget.errorCode]
            ?? snapshot.data?[PLCErrorCodes.unknownError]
            ?? PLCErrorCodes.getTechnicalDescription(widget.errorCode);
        return _buildContent(context, message);
      },
    );
  }

  Widget _buildContent(BuildContext context, String errorMessage) {
    final strings = widget.viewModel.strings;
    final showTechnicalDetails = _shouldShowTechnicalDetails();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                        color: AppColors.error.withValues(alpha: 0.1),
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

              Text(
                strings.t('error_title'),
                style: AppTextStyles.title.copyWith(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              Text(
                errorMessage,
                style: AppTextStyles.body.copyWith(
                  fontFamily: 'NotoSans',
                  fontSize: 45,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  'Error Code: ${widget.errorCode}',
                  style: AppTextStyles.body.copyWith(
                    fontFamily: 'Courier',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),

              if (showTechnicalDetails && widget.technicalDetail != null) ...[
                const SizedBox(height: 32),
                _buildTechnicalDetailsCard(),
              ],

              const SizedBox(height: 48),

              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Row(
                  children: [
                    if (widget.onRetry != null) ...[
                      Flexible(
                        child: PrimaryButton(
                          label: strings.t('retry_payment'),
                          onPressed: widget.onRetry,
                          fontSize: 45,
                          paddingHorizontal: 60,
                          paddingvertical: 20,
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                    Flexible(
                      child: OutlinedButton(
                        onPressed: widget.viewModel.resetToIdle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 60,
                            vertical: 20,
                          ),
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          strings.t('back_to_start'),
                          style: AppTextStyles.body.copyWith(
                            fontFamily: 'NotoSans',
                            fontSize: 45,
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
                'Technical Details',
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
            PLCErrorCodes.getTechnicalDescription(widget.errorCode),
            style: AppTextStyles.body.copyWith(
              fontFamily: 'NotoSans',
              fontSize: 32,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          if (widget.technicalDetail != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.technicalDetail!,
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

  bool _shouldShowTechnicalDetails() => true;
}
