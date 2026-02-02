// loading_screen.dart
import 'package:flutter/material.dart';

import '../../viewmodel/app_view_model.dart';
import '../theme/app_text_styles.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // const ScentWavesLoader(
            //   size: 1000,
            //   primaryColor: Color(0xFFF18142),
            //   waveGradientType: WaveGradientType.solid, // En hızlı
            //   sprayConfig: KioskOptimizedConfig.sprayConfig,
            //   waveColor: Color.fromARGB(255, 60, 15, 119),

            //   useOptimizedSettings: true, // ÖNEMLİ!
            // ),
            const SizedBox(height: 28),
            Text(
              viewModel.strings.loading,
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
