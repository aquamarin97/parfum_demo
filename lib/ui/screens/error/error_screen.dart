import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';

import '../../../viewmodel/app_view_model.dart';
import '../../theme/app_text_styles.dart';

/// Shown when a non-recoverable application error occurs.
///
/// Displays a localised error title and body. The inactivity timeout
/// will automatically return to idle — no manual button is shown.
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = viewModel.strings;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(strings.t('error_title'), style: AppTextStyles.title),
            const SizedBox(height: AppSizes.spacingS),
            Text(strings.t('error_body'), style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
