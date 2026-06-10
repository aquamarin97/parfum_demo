import 'package:flutter/material.dart';
import 'package:parfume_app/ui/components/buttons/primary_outlined_button.dart';
import 'package:parfume_app/ui/components/buttons/primary_button.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';

import '../../../viewmodel/app_view_model.dart';
import '../../theme/app_text_styles.dart';

/// KVKK (data-privacy consent) screen.
///
/// The user must check the approval checkbox before the confirm button
/// becomes active. Cancelling returns to the idle screen.
class KvkkScreen extends StatefulWidget {
  const KvkkScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<KvkkScreen> createState() => _KvkkScreenState();
}

class _KvkkScreenState extends State<KvkkScreen> {
  /// Whether the user has ticked the approval checkbox.
  bool _approved = false;

  @override
  Widget build(BuildContext context) {
    final kvkk = widget.viewModel.kvkkText;
    final strings = widget.viewModel.strings;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.screenPaddingH,
        vertical: MediaQuery.of(context).size.height * 0.05,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kvkk.title, style: AppTextStyles.topHeader),
          const SizedBox(height: AppSizes.spacingS),
          Expanded(
            child: SingleChildScrollView(
              child: Text(kvkk.body, style: AppTextStyles.body),
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            
            children: [
              Transform.scale(
                scale: AppSizes.checkboxScale,
                child: Checkbox(
                  value: _approved,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() => _approved = value ?? false);
                  },
                ),
              ),
              const SizedBox(width: AppSizes.spacingM),
              Expanded(
                child: Text(
                  kvkk.approvalLabel,
                  style: AppTextStyles.body.copyWith(
                    fontSize: AppSizes.fontBodyLarge,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingS),
          Row(
            children: [
              Expanded(
                child: PrimaryOutlinedButton(
                  label: strings.t('cancel'),
                  onPressed: widget.viewModel.cancelToIdle,
                  fontSize: AppSizes.fontButtonText,
                  paddingHorizontal: AppSizes.buttonPaddingHSmall,
                ),
              ),
              const SizedBox(width: AppSizes.spacingS),
              Expanded(
                child: PrimaryButton(
                  label: kvkk.buttonLabel,
                  enabled: _approved,
                  onPressed: _approved ? widget.viewModel.startQuestions : null,
                  fontSize: AppSizes.fontButtonText,
                  paddingHorizontal: AppSizes.buttonPaddingHSmall,
                ),
              ),
            ],
          ),
          SizedBox(height: 30)
        ],
      ),
    );
  }
}