import 'package:flutter/material.dart';
import 'package:parfume_app/common/widgets/app_logo_painter.dart';

/// Full-screen animated logo background used across app screens.
///
/// Renders the [AppLogoPainter] canvas, driven by [animation].
/// Intended to be placed as the bottom-most layer in a [Stack].
class AppLogoBackground extends StatelessWidget {
  const AppLogoBackground({super.key, required this.animation});

  /// The animation that drives the logo paint progress (0.0 → 1.0).
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => CustomPaint(
          painter: AppLogoPainter(animationValue: animation.value),
        ),
      ),
    );
  }
}
