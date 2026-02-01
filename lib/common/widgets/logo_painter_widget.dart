import 'package:flutter/material.dart';

class AnimatedLogoPainter extends CustomPainter {
  final double animationValue;

  AnimatedLogoPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 🎨 path1 rengi
    final paint1 = Paint()
      ..color = const Color(0xFFF18142)
      ..style = PaintingStyle.fill;

    // 🎨 path2 rengi
    final paint2 = Paint()
      ..color = const Color(0xFFEE741E)
      ..style = PaintingStyle.fill;

    // Animasyon değerine göre path'leri çiz
    if (animationValue > 0) {
      // 1️⃣ İlk şekil (0.0 - 0.5 arası)
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

    if (animationValue > 0.5) {
      // 2️⃣ İkinci şekil (0.5 - 1.0 arası)
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
  bool shouldRepaint(AnimatedLogoPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}