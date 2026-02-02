import 'package:flutter/material.dart';
import 'package:parfume_app/ui/screens/result/widgets/components/countdown_timer.dart';
import 'package:parfume_app/ui/screens/result/widgets/components/tester_button.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../result_view_model_refactored.dart';

class TestersReadyView extends StatelessWidget {
  const TestersReadyView({super.key, required this.viewModel});

  final ResultViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = viewModel.strings; // ✅
    
    // Eğer topIds boşsa, placeholder mock data kullan
    final topIds = viewModel.topIds.isEmpty 
        ? [101, 202, 303]
        : viewModel.topIds;

    final displayCount = topIds.length > 3 ? 3 : topIds.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        
        Text(
          strings.pleaseSelect, // ✅
          style: AppTextStyles.title.copyWith(
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        Text(
          strings.noPriceDifference, // ✅
          style: AppTextStyles.body.copyWith(
            fontFamily: 'NotoSans',
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),

        CountdownTimer(timerNotifier: viewModel.timerNotifier),

        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(displayCount, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TesterButton(
                index: index,
                label: (index + 1).toString(),
                perfumeId: topIds[index],
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