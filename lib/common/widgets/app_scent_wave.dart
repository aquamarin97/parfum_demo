import 'package:flutter/material.dart';
import 'package:parfume_app/ui/screens/scent_waves_loader.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';

/// Decorative scent-wave animation shown at the bottom of kiosk screens.
///
/// Encapsulates all [ScentWavesLoader] parameters so that color and size
/// changes are made in one place ([AppColors] and [AppSizes]) rather than
/// scattered across individual screens.
///
/// Conditionally included in the root [Stack] by [AppRoot] based on the
/// active [AppState] — screens that require a clean layout (e.g. KVKK,
/// error screens) suppress this widget.
class AppScentWave extends StatelessWidget {
  const AppScentWave({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomCenter,
      child: ScentWavesLoader(
        size: AppSizes.scentWaveSize,
        primaryColor: AppColors.waveOrange,
        waveGradientType: WaveGradientType.solid,
        waveColor: AppColors.wavePurple,
        sprayConfig: KioskOptimizedConfig.sprayConfig,
        useOptimizedSettings: true,
      ),
    );
  }
}