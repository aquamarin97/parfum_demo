import 'package:flutter/material.dart';
import 'package:parfume_app/core/constants/app_constants.dart';
import 'package:parfume_app/ui/screens/idle/widgets/idle_center_content.dart';
import 'package:parfume_app/ui/screens/idle/widgets/idle_greeting_text.dart';

import '../../../viewmodel/app_view_model.dart';

/// Kiosk home screen shown while the app is waiting for user interaction.
///
/// Owns the shared [AnimationController] that drives the greeting and center
/// content entry animations.
/// Re-runs the entry animation whenever the active language changes.
class IdleScreen extends StatefulWidget {
  const IdleScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<IdleScreen> createState() => _IdleScreenState();
}

class _IdleScreenState extends State<IdleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  /// Tracks the active language code so [didUpdateWidget] can detect changes.
  String _currentLanguageCode = '';

  @override
  void initState() {
    super.initState();
    _currentLanguageCode = widget.viewModel.currentLanguage.code;
    _setupAnimation();
  }

  /// Creates the animation controller and starts the entry animation.
  void _setupAnimation() {
    _controller = AnimationController(
      duration: AppConstants.logoAnimationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(IdleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLanguageCode = widget.viewModel.currentLanguage.code;
    if (_currentLanguageCode != newLanguageCode) {
      _currentLanguageCode = newLanguageCode;
      // Re-run the entry animation so the RTL/LTR layout change feels
      // intentional rather than an abrupt jump.
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.viewModel.currentLanguage.isRtl;
    final strings = widget.viewModel.strings;

    return Stack(
      children: [
        IdleGreetingText(
          animation: _animation,
          languageCode: _currentLanguageCode,
          isRtl: isRtl,
          title1: strings.t('idle_title_1'),
          title2: strings.t('idle_title_2'),
          brandName: strings.t('brand_name'),
        ),
        IdleCenterContent(
          animation: _animation,
          languageCode: _currentLanguageCode,
          subtitle: strings.t('idle_subtitle'),
          startLabel: strings.t('start'),
          onStart: widget.viewModel.startKvkk,
        ),
      ],
    );
  }
}
