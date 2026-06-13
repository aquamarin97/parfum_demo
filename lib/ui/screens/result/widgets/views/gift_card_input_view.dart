import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../../../../viewmodel/result_view_model.dart';

const int _maxLength = 30;

/// Collects the gift-card recipient name (max 30 characters) after the
/// customer answers "Yes" to the gift-card question.
class GiftCardInputView extends StatefulWidget {
  const GiftCardInputView({super.key, required this.viewModel});

  final ResultViewModel viewModel;

  @override
  State<GiftCardInputView> createState() => _GiftCardInputViewState();
}

class _GiftCardInputViewState extends State<GiftCardInputView> {
  final TextEditingController _controller = TextEditingController();
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() => _charCount = _controller.text.length);
  }

  void _confirm() {
    widget.viewModel.submitGiftCardName(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.viewModel.strings;
    final canConfirm = _charCount > 0;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSizes.spacingL),
        Text(
          strings.t('gift_card_recipient_label'),
          style: AppTextStyles.topHeader,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingL),
        TapRegion(
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            textCapitalization:
                isRtl ? TextCapitalization.none : TextCapitalization.words,
            textAlign: TextAlign.center,
            maxLength: _maxLength,
            inputFormatters: [LengthLimitingTextInputFormatter(_maxLength)],
            style: AppTextStyles.title,
            decoration: InputDecoration(
              hintText: strings.t('gift_card_recipient_hint'),
              hintStyle: AppTextStyles.hint,
              counterText: '$_charCount / $_maxLength',
              counterStyle: AppTextStyles.hint,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingL,
                vertical: AppSizes.spacingM,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spacingM),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.viewModel.backToGiftCardQuestion,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.dangerRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingXL,
                    vertical: AppSizes.spacingM,
                  ),
                  side: const BorderSide(
                    color: AppColors.dangerRed,
                    width: AppSizes.testerButtonBorderNormal,
                  ),
                ),
                child: Text(
                  strings.t('back'),
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
                onPressed: canConfirm ? _confirm : null,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.warningAmberDark,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingXL,
                    vertical: AppSizes.spacingM,
                  ),
                  side: BorderSide(
                    color: canConfirm
                        ? AppColors.warningAmberDark
                        : AppColors.border,
                    width: AppSizes.testerButtonBorderNormal,
                  ),
                ),
                child: Text(
                  strings.t('gift_card_confirm'),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
