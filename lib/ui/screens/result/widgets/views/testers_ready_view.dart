import 'package:flutter/material.dart';
import 'package:parfume_app/ui/screens/result/widgets/shared/countdown_timer.dart';
import 'package:parfume_app/ui/screens/result/widgets/shared/tester_button.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../../../../viewmodel/result_view_model.dart';

/// Shown when testers are physically ready for the customer to choose from.
///
/// Displays a selection prompt, a countdown timer, and one [TesterButton]
/// per recommendation (up to three).
class TestersReadyView extends StatelessWidget {
  const TestersReadyView({super.key, required this.viewModel});

  final ResultViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = viewModel.strings;
    final topIds = viewModel.topIds;

    assert(
      topIds.isNotEmpty,
      'TestersReadyView requires at least one recommendation ID.',
    );

    final displayCount = topIds.length.clamp(0, 3);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.spacingXXL),
        Text(
          strings.t('please_select'),
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingS),
        Text(
          strings.t('no_price_difference'),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacingL),
        CountdownTimer(timerNotifier: viewModel.timerNotifier),
        const SizedBox(height: AppSizes.spacingL),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(displayCount, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingM,
              ),
              child: TesterButton(
                index: index,
                label: (index + 1).toString(),
                isSelected: viewModel.selectedTester == index,
                onTap: () => viewModel.onTesterSelected(index),
              ),
            );
          }),
        ),
      ],
    );
  }
}
