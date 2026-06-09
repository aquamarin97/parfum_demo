import 'package:flutter/material.dart';
import 'package:parfume_app/ui/components/buttons/primary_button.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

/// Centred subtitle, start button, and bottom spacing for the idle screen.
///
/// Slides in from below with a fade transition driven by [animation].
/// A [ValueKey] keyed on [languageCode] is applied to the inner [Column] so
/// that a language change triggers a full subtree rebuild, preventing stale
/// layout state from carrying over between locales.
class IdleCenterContent extends StatelessWidget {
  const IdleCenterContent({
    super.key,
    required this.animation,
    required this.languageCode,
    required this.subtitle,
    required this.startLabel,
    required this.onStart,
  });

  /// Drives the fade and slide entry transitions (0.0 → 1.0).
  final Animation<double> animation;

  /// BCP 47 code of the active language; used as part of the [ValueKey] for
  /// the inner [Column].
  final String languageCode;

  /// Localised subtitle displayed above the start button.
  final String subtitle;

  /// Localised label for the start button.
  final String startLabel;

  /// Called when the user taps the start button.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: Column(
              key: ValueKey('${languageCode}_center'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(
                    fontFamily: 'NotoSans',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXXL),
                PrimaryButton(label: startLabel, onPressed: onStart),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}