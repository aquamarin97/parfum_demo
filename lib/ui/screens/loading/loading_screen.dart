import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';

import '../../../viewmodel/app_view_model.dart';
import '../../theme/app_text_styles.dart';

/// Shown while the recommendation engine computes results.
///
/// Displays a localised loading message while root-level decorative layers
/// keep the kiosk visually active during the brief wait.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenPaddingH,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              viewModel.strings.t('loading'),
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.spacingMax)
          ],
        ),
      ),
    );
  }
}
