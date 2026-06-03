import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';

/// [CustomPainter] that draws the two-stroke animated logo.
///
/// The animation is split into two phases:
/// - Phase 1 (0.0 → 0.5): draws the lower stroke.
/// - Phase 2 (0.5 → 1.0): draws the upper stroke.
///
/// Pass `animationValue: 1.0` for the fully drawn static state.
class AppLogoPainter extends CustomPainter {
  const AppLogoPainter({required this.animationValue});

  /// Current animation progress in the range 0.0–1.0.
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = AppColors.logoPrimary
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = AppColors.logoSecondary
      ..style = PaintingStyle.fill;

    // Phase 1 — lower stroke (animationValue 0.0 → 0.5).
    if (animationValue > 0) {
      final progress1 = (animationValue * 2).clamp(0.0, 1.0);
      final path1 = Path()
        ..moveTo(0, size.height * 0.90)
        ..lineTo(size.width * 0.55 * progress1,
            size.height * (0.90 - 0.22 * progress1))
        ..lineTo(size.width * 0.55 * progress1,
            size.height * (0.90 - 0.32 * progress1))
        ..lineTo(0, size.height * 0.80)
        ..close();
      canvas.drawPath(path1, paint1);
    }

    // Phase 2 — upper stroke (animationValue 0.5 → 1.0).
    if (animationValue > 0.5) {
      final progress2 = ((animationValue - 0.5) * 2).clamp(0.0, 1.0);
      final path2 = Path()
        ..moveTo(0, size.height * 0.50)
        ..lineTo(size.width * 0.55 * progress2,
            size.height * (0.50 + 0.18 * progress2))
        ..lineTo(size.width * 0.55 * progress2,
            size.height * (0.50 + 0.08 * progress2))
        ..lineTo(0, size.height * 0.40)
        ..close();
      canvas.drawPath(path2, paint2);
    }
  }

  @override
  bool shouldRepaint(AppLogoPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}