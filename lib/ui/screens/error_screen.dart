// error_screen.dart file
import 'package:flutter/material.dart';

import '../../viewmodel/app_view_model.dart';
import '../components/primary_button.dart';
import '../theme/app_text_styles.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = viewModel.strings;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(strings.errorTitle, style: AppTextStyles.title),
            const SizedBox(height: 16),
            Text(strings.errorBody, style: AppTextStyles.body),
            const SizedBox(height: 24),
            PrimaryButton(
              label: strings.backToStart,
              onPressed: viewModel.resetToIdle,
            ),
          ],
        ),
      ),
    );
  }
}