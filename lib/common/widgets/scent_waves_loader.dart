import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative animated perfume bottle widget with scent-wave and molecule effects.
///
/// Optimised for GPU-less kiosk systems (A83T ARM CPU): blur effects are
/// disabled, wave and particle counts are reduced, and all shader usage is
/// kept minimal.
///
/// Use [KioskOptimizedConfig.sprayConfig] and set [useOptimizedSettings] to
/// `true` for production kiosk deployments.
///
/// Example:
/// ```dart
/// ScentWavesLoader(
///   size: 600,
///   primaryColor: AppColors.waveOrange,
///   waveGradientType: WaveGradientType.solid,
///   sprayConfig: KioskOptimizedConfig.sprayConfig,
///   useOptimizedSettings: true,
/// )
/// ```
class ScentWavesLoader extends StatefulWidget {
  const ScentWavesLoader({
    super.key,
    this.size = 200,
    this.primaryColor,
    this.sprayColor,
    this.waveColor,
    this.moleculeColors,
    this.sprayConfig = const SprayEffectConfig(),
    this.waveGradientType = WaveGradientType.solid,
    this.useOptimizedSettings = true, // Kiosk için true
  });

  final double size;
  final Color? primaryColor;
  final Color? sprayColor;
  final Color? waveColor;
  final List<Color>? moleculeColors;
  final SprayEffectConfig sprayConfig;
  final WaveGradientType waveGradientType;
  final bool useOptimizedSettings;

  @override
  State<ScentWavesLoader> createState() => _ScentWavesLoaderState();
}

class _ScentWavesLoaderState extends State<ScentWavesLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<Color> _moleculeColors;
  final Stopwatch _sw = Stopwatch();

  @override
  void initState() {
    super.initState();
    _sw.start();
    _moleculeColors = _createHarmonicPalette(
      widget.primaryColor ?? Colors.orange,
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void didUpdateWidget(ScentWavesLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryColor != widget.primaryColor) {
      _moleculeColors = _createHarmonicPalette(
        widget.primaryColor ?? Colors.orange,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _sw.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.primaryColor ?? Theme.of(context).colorScheme.primary;

    final sprayColor = widget.sprayColor ?? const Color.fromARGB(255, 70, 190, 34);
    final waveColor = widget.waveColor ?? baseColor;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final tSeconds = _sw.elapsedMicroseconds / 1e6;
          return CustomPaint(
            painter: _ScentWavesPainter(
              t: tSeconds,
              primaryColor: baseColor,
              sprayColor: sprayColor,
              waveColor: waveColor,
              moleculeColors: widget.moleculeColors ?? _moleculeColors,
              size: widget.size,
              sprayConfig: widget.sprayConfig,
              waveGradientType: widget.waveGradientType,
              useOptimized: widget.useOptimizedSettings,
            ),
          );
        },
      ),
    );
  }

  static List<Color> _createHarmonicPalette(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return [
      baseColor,
      hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor(),
      hsl.withHue((hsl.hue + 30) % 360).toColor(),
      hsl.withHue((hsl.hue - 30) % 360).toColor(),
      hsl.withSaturation((hsl.saturation - 0.2).clamp(0.0, 1.0)).toColor(),
      hsl.withHue((hsl.hue + 180) % 360).withSaturation(0.5).toColor(),
    ];
  }
}

class _ScentWavesPainter extends CustomPainter {
  _ScentWavesPainter({
    required this.t,
    required this.primaryColor,
    required this.sprayColor,
    required this.waveColor,
    required this.moleculeColors,
    required this.size,
    required this.sprayConfig,
    required this.waveGradientType,
    required this.useOptimized,
  });

  final double t;
  final Color primaryColor;
  final Color sprayColor;
  final Color waveColor;
  final List<Color> moleculeColors;
  final double size;
  final SprayEffectConfig sprayConfig;
  final WaveGradientType waveGradientType;
  final bool useOptimized;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final c = Offset(canvasSize.width / 2, canvasSize.height / 2);

    // Outer glow — disabled (too slow without GPU)
    if (!useOptimized) {
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.2)
        ..color = waveColor.withValues(alpha: 0.12);
      canvas.drawCircle(c, size * 0.3, glowPaint);
    }

    // Fragrance waves
    _drawFragranceWaves(canvas, c, clockwise: true);
    _drawFragranceWaves(canvas, c, clockwise: false);

    // Molecules
    _drawFragranceMolecules(canvas, c);

    // Bottle + spray
    _drawPerfumeBottle(canvas, c);
  }

  void _drawFragranceWaves(
    Canvas canvas,
    Offset center, {
    required bool clockwise,
  }) {
    final waveCount = useOptimized
        ? (clockwise ? 2 : 1) // 3+2 → 2+1 waves (kiosk optimisation)
        : (clockwise ? 3 : 2);

    final segments = useOptimized ? 48 : 60; // 60 → 48 (faster on kiosk)

    for (int i = 0; i < waveCount; i++) {
      final offset = clockwise ? i * 0.33 : i * 0.5;
      final phase = _fract(t * 0.18 + offset);
      final smoothPhase = _smoothStep(phase);

      final radius = (size * 0.12) + smoothPhase * (size * 0.38);
      final rawOpacity = 1.0 - smoothPhase;
      final baseOpacity = _smoothStep(rawOpacity) * 0.5;
      final strokeWidth = (size * 0.014) * (1.3 - smoothPhase * 0.5);

      final rotationSpeed = clockwise ? 1.0 : -0.7;
      final rotation = t * math.pi * 2 * rotationSpeed;

      // Draw based on gradient type
      switch (waveGradientType) {
        case WaveGradientType.solid:
          _drawSolidWave(
            canvas,
            center,
            radius,
            rotation,
            phase,
            segments,
            strokeWidth,
            baseOpacity,
          );
          break;

        case WaveGradientType.sweepMultiColor:
          _drawGradientWave(
            canvas,
            center,
            radius,
            rotation,
            phase,
            segments,
            strokeWidth,
            baseOpacity,
          );
          break;
      }
    }
  }

  void _drawSolidWave(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    double phase,
    int segments,
    double strokeWidth,
    double baseOpacity,
  ) {
    final path = Path();

    for (int j = 0; j <= segments; j++) {
      final progress = j / segments;
      final angle = progress * 2 * math.pi;
      final finalAngle = angle + rotation;

      final wave1 =
          math.sin(finalAngle * 3 + phase * math.pi * 2) * (size * 0.012);
      final wave2 = math.sin(finalAngle * 5 - phase * math.pi) * (size * 0.008);
      final wave3 =
          math.sin(finalAngle * 7 + phase * math.pi * 3) * (size * 0.005);

      final r = radius + wave1 + wave2 + wave3;
      final x = center.dx + r * math.cos(finalAngle);
      final y = center.dy + r * math.sin(finalAngle);

      if (j == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = waveColor.withValues(alpha: baseOpacity)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  void _drawGradientWave(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    double phase,
    int segments,
    double strokeWidth,
    double baseOpacity,
  ) {
    // CPU-friendly gradient: split path into segments
    const gradientSegments = 8; // 12 → 8 segments (kiosk)
    final pathSegmentsPerGradient = segments ~/ gradientSegments;

    final hsl = HSLColor.fromColor(waveColor);

    for (int g = 0; g < gradientSegments; g++) {
      final gradProgress = g / gradientSegments;
      final colorPhase =
          (gradProgress + rotation / (math.pi * 2) + phase) % 1.0;
      final colorFactor = (math.sin(colorPhase * math.pi * 2) + 1.0) / 2.0;

      final segmentColor = Color.lerp(
        waveColor.withValues(alpha: baseOpacity * 1.1),
        hsl
            .withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0))
            .toColor()
            .withValues(alpha: baseOpacity * 0.6),
        colorFactor,
      )!;

      final path = Path();
      final startSegment = g * pathSegmentsPerGradient;
      final endSegment = (g + 1) * pathSegmentsPerGradient + 1;

      for (int j = startSegment; j < endSegment && j <= segments; j++) {
        final progress = j / segments;
        final angle = progress * 2 * math.pi;
        final finalAngle = angle + rotation;

        final wave1 =
            math.sin(finalAngle * 3 + phase * math.pi * 2) * (size * 0.012);
        final wave2 =
            math.sin(finalAngle * 5 - phase * math.pi) * (size * 0.008);
        final wave3 =
            math.sin(finalAngle * 7 + phase * math.pi * 3) * (size * 0.005);

        final r = radius + wave1 + wave2 + wave3;
        final x = center.dx + r * math.cos(finalAngle);
        final y = center.dy + r * math.sin(finalAngle);

        if (j == startSegment) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = segmentColor
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, paint);
    }
  }

  void _drawFragranceMolecules(Canvas canvas, Offset center) {
    final particleCount = useOptimized ? 15 : 25; // 25 → 15 particles (kiosk)
    final sides = useOptimized ? 4 : 6; // 6 → 4 sides (squares render faster)

    for (int i = 0; i < particleCount; i++) {
      final seed = i * 137.508;
      final baseAngle = (seed % 360) * math.pi / 180;

      final lifeProgress = _fract(t * 0.22 + (i / particleCount));
      final smoothLife = _smoothStep(lifeProgress);

      final distance = size * 0.15 + smoothLife * (size * 0.35);
      final rotationSpeed = 0.5 + (i % 3) * 0.3;
      final spiralRotation = t * math.pi * 2 * rotationSpeed;
      final angle = baseAngle + spiralRotation + smoothLife * math.pi * 2;

      final horizontalWave = math.sin(t * math.pi * 2 + seed) * size * 0.08;

      final x =
          center.dx +
          math.cos(angle) * distance * (0.6 + smoothLife * 0.4) +
          horizontalWave;
      final y = center.dy - distance * 0.85 + math.sin(angle) * distance * 0.25;

      final fadeIn = math.min(smoothLife * 3, 1.0);
      final fadeOut = math.min((1.0 - smoothLife) * 3, 1.0);
      final opacity = math.min(fadeIn, fadeOut);

      final pulse = 1.0 + 0.15 * math.sin(t * math.pi * 4 + seed);
      final baseSize = size * 0.009 * (0.7 + (i % 5) * 0.15);
      final particleSize = baseSize * (1.5 - smoothLife * 0.3) * pulse;

      final colorCycle = (t * 0.7 + i * 0.3) % moleculeColors.length;
      final colorIndex1 = colorCycle.floor() % moleculeColors.length;
      final colorIndex2 = (colorIndex1 + 1) % moleculeColors.length;
      final colorBlend = colorCycle - colorIndex1;

      final color1 = moleculeColors[colorIndex1];
      final color2 = moleculeColors[colorIndex2];
      final particleColor = Color.lerp(color1, color2, colorBlend)!;

      // Molecule shape
      final path = Path();
      for (int j = 0; j < sides; j++) {
        final a = (j / sides) * 2 * math.pi + t * math.pi;
        final px = x + math.cos(a) * particleSize;
        final py = y + math.sin(a) * particleSize;
        if (j == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = particleColor.withValues(alpha: opacity * 0.7);

      canvas.drawPath(path, paint);

      // Glow — disabled for kiosk
      if (!useOptimized) {
        final glowPaint = Paint()
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, particleSize * 2.5)
          ..color = particleColor.withValues(alpha: opacity * 0.4);

        canvas.drawCircle(Offset(x, y), particleSize * 0.6, glowPaint);
      }
    }
  }

  void _drawPerfumeBottle(Canvas canvas, Offset center) {
    final pulse = 1.0 + 0.06 * math.sin(t * 2 * math.pi);
    final bottleWidth = size * 0.16 * pulse;
    final bottleHeight = size * 0.24 * pulse;

    final bottlePath = Path();
    final baseWidth = bottleWidth;
    final baseHeight = bottleHeight * 0.7;

    final bottomLeft = Offset(
      center.dx - baseWidth / 2,
      center.dy + baseHeight / 2,
    );

    bottlePath.moveTo(bottomLeft.dx, bottomLeft.dy);
    bottlePath.lineTo(center.dx - baseWidth / 2, center.dy);

    bottlePath.quadraticBezierTo(
      center.dx - baseWidth / 2,
      center.dy - baseHeight / 4,
      center.dx - baseWidth / 2.5,
      center.dy - baseHeight / 3,
    );

    final neckWidth = bottleWidth * 0.4;
    bottlePath.lineTo(center.dx - neckWidth / 2, center.dy - baseHeight / 2);
    bottlePath.lineTo(center.dx - neckWidth / 2, center.dy - baseHeight / 1.5);

    final capWidth = neckWidth * 1.5;
    final capHeight = bottleHeight * 0.25;
    bottlePath.lineTo(center.dx - capWidth / 2, center.dy - baseHeight / 1.5);
    bottlePath.lineTo(
      center.dx - capWidth / 2,
      center.dy - baseHeight / 1.5 - capHeight,
    );

    bottlePath.quadraticBezierTo(
      center.dx,
      center.dy - baseHeight / 1.5 - capHeight * 1.2,
      center.dx + capWidth / 2,
      center.dy - baseHeight / 1.5 - capHeight,
    );

    bottlePath.lineTo(center.dx + capWidth / 2, center.dy - baseHeight / 1.5);
    bottlePath.lineTo(center.dx + neckWidth / 2, center.dy - baseHeight / 1.5);
    bottlePath.lineTo(center.dx + neckWidth / 2, center.dy - baseHeight / 2);
    bottlePath.lineTo(center.dx + baseWidth / 2.5, center.dy - baseHeight / 3);

    bottlePath.quadraticBezierTo(
      center.dx + baseWidth / 2,
      center.dy - baseHeight / 4,
      center.dx + baseWidth / 2,
      center.dy,
    );

    bottlePath.lineTo(center.dx + baseWidth / 2, center.dy + baseHeight / 2);

    bottlePath.quadraticBezierTo(
      center.dx,
      center.dy + baseHeight / 2 + size * 0.015,
      bottomLeft.dx,
      bottomLeft.dy,
    );

    bottlePath.close();

    // Shadow — disabled for kiosk
    if (!useOptimized) {
      canvas.drawShadow(
        bottlePath,
        Colors.black.withValues(alpha: 0.3),
        size * 0.05,
        true,
      );
    }

    // Bottle body
    final bottlePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader =
          LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              primaryColor.withValues(alpha: 0.7),
              primaryColor.withValues(alpha: 0.95),
              primaryColor.withValues(alpha: 0.7),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(
            Rect.fromCenter(
              center: center,
              width: bottleWidth,
              height: bottleHeight,
            ),
          );

    canvas.drawPath(bottlePath, bottlePaint);

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.006
      ..color = primaryColor.withValues(alpha: 0.4);

    canvas.drawPath(bottlePath, outlinePaint);

    // Glass highlight
    final highlightPath = Path();
    highlightPath.moveTo(
      center.dx - baseWidth / 2.8,
      center.dy - baseHeight / 4,
    );
    highlightPath.lineTo(
      center.dx - baseWidth / 3.5,
      center.dy - baseHeight / 6,
    );
    highlightPath.lineTo(
      center.dx - baseWidth / 3.5,
      center.dy + baseHeight / 3,
    );
    highlightPath.lineTo(
      center.dx - baseWidth / 2.8,
      center.dy + baseHeight / 3.5,
    );
    highlightPath.close();

    final highlightPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.5),
              Colors.white.withValues(alpha: 0.1),
            ],
          ).createShader(
            Rect.fromCenter(
              center: Offset(center.dx - baseWidth / 3, center.dy),
              width: baseWidth * 0.2,
              height: baseHeight * 0.6,
            ),
          );

    canvas.drawPath(highlightPath, highlightPaint);

    // Liquid level (75% full)
    final liquidLevel = center.dy + baseHeight * 0.25;
    final liquidPath = Path()..moveTo(center.dx - baseWidth / 2, liquidLevel);

    const waveSegments = 30;
    for (int i = 0; i <= waveSegments; i++) {
      final progress = i / waveSegments;
      final x = center.dx - baseWidth / 2 + baseWidth * progress;
      final wave =
          math.sin(progress * math.pi * 6 + t * math.pi * 2) * (size * 0.006);
      final y = liquidLevel + wave;
      liquidPath.lineTo(x, y);
    }

    liquidPath.lineTo(center.dx + baseWidth / 2, center.dy + baseHeight / 2);
    liquidPath.quadraticBezierTo(
      center.dx,
      center.dy + baseHeight / 2 + size * 0.015,
      center.dx - baseWidth / 2,
      center.dy + baseHeight / 2,
    );
    liquidPath.close();

    final liquidPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = primaryColor.withValues(alpha: 0.85);

    canvas.drawPath(liquidPath, liquidPaint);

    // Liquid highlight
    final liquidHighlight = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.15);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          center.dx - baseWidth / 4,
          liquidLevel + baseHeight * 0.08,
        ),
        width: baseWidth * 0.15,
        height: baseHeight * 0.06,
      ),
      liquidHighlight,
    );

    // Spray effect
    drawSprayEffect(
      canvas: canvas,
      origin: Offset(center.dx, center.dy - baseHeight / 1.5 - capHeight),
      t: t,
      size: size,
      sprayColor: sprayColor,
      config: sprayConfig,
    );
  }

  @override
  bool shouldRepaint(covariant _ScentWavesPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.sprayColor != sprayColor ||
        oldDelegate.waveColor != waveColor ||
        oldDelegate.size != size ||
        oldDelegate.waveGradientType != waveGradientType ||
        oldDelegate.sprayConfig != sprayConfig ||
        oldDelegate.moleculeColors != moleculeColors;
  }
}

/* ──────────────────── Configuration ──────────────────── */

/// Rendering style for the fragrance wave strokes.
enum WaveGradientType {
  /// Single-colour strokes — fastest; recommended for kiosk.
  solid,

  /// CPU-friendly multi-colour gradient achieved by splitting the path
  /// into segments.
  sweepMultiColor,
}

/// Spray and wave configuration optimised for the A83T ARM CPU.
///
/// Disables blur and mist effects, reduces particle count from 18 to 10,
/// and disables the ring layer to stay within CPU budget on low-end hardware.
class KioskOptimizedConfig {
  static const sprayConfig = SprayEffectConfig(
    particles: 10, // 18 → 10
    blurMultiplier: 0.0, // Blur disabled
    mistMultiplier: 0.0, // Mist disabled
    drawCore: true,
    drawRing: false,
    blurLevels: 1,
  );
}

/// Configuration for the spray particle effect emitted from the bottle nozzle.
///
/// Default values target a visually rich desktop experience. For kiosk
/// deployments use [KioskOptimizedConfig.sprayConfig].
class SprayEffectConfig {
  final int particles;
  final double speed;
  final double fanAngle;
  final double baseAngle;
  final double range;
  final double particleSize;
  final double maxOpacity;
  final double fadeInGain;
  final double fadeOutGain;
  final double wobbleAmp;
  final double wobbleFreq;
  final double angleJitter;
  final double distJitter;
  final double opacityJitter;
  final double blurMultiplier;
  final double mistMultiplier;
  final double mistOpacityFactor;
  final bool drawCore;
  final bool drawRing;
  final double coreRadiusFactor;
  final double ringRadiusFactor;
  final double ringStrokeFactor;
  final int blurLevels;

  const SprayEffectConfig({
    this.particles = 18,
    this.speed = 0.25,
    this.fanAngle = math.pi * 0.7,
    this.baseAngle = -math.pi / 2,
    this.range = 0.28,
    this.particleSize = 0.015,
    this.maxOpacity = 0.6,
    this.fadeInGain = 5.0,
    this.fadeOutGain = 3.0,
    this.wobbleAmp = 0.12,
    this.wobbleFreq = 2.5,
    this.angleJitter = 0.10,
    this.distJitter = 0.22,
    this.opacityJitter = 0.35,
    this.blurMultiplier = 1.9,
    this.mistMultiplier = 1.9,
    this.mistOpacityFactor = 0.35,
    this.drawCore = true,
    this.drawRing = true,
    this.coreRadiusFactor = 0.40,
    this.ringRadiusFactor = 0.80,
    this.ringStrokeFactor = 0.003,
    this.blurLevels = 14,
  });
}

/* ──────────────────── Spray Effect ───────────────────── */

void drawSprayEffect({
  required Canvas canvas,
  required Offset origin,
  required double t,
  required double size,
  required Color sprayColor,
  SprayEffectConfig config = const SprayEffectConfig(),
}) {
  final int n = math.max(1, config.particles);
  final double invN = 1.0 / n;
  final Paint bodyPaint = Paint()..style = PaintingStyle.fill;

  for (int i = 0; i < n; i++) {
    final double phaseOffset = i * invN;
    final double seed = _hash01(i + 1337);
    final double seed2 = _hash01(i + 7331);
    final double seed3 = _hash01(i + 9001);

    final double life = _fract(t * config.speed + phaseOffset);
    final double smoothLife = _smoothStep(_smoothStep(_smoothStep(life)));

    final double spread = (phaseOffset - 0.5) * config.fanAngle;
    final double jitterA = (seed - 0.5) * 2.0 * config.angleJitter;
    final double baseAngle = config.baseAngle + spread + jitterA;

    final double wobble =
        math.sin(t * math.pi * config.wobbleFreq + seed2 * math.pi * 2.0) *
        config.wobbleAmp;

    final double angle = baseAngle + wobble;
    final double distJ = 1.0 + (seed2 - 0.5) * 2.0 * config.distJitter;
    final double distance = smoothLife * size * config.range * distJ;

    final double drift = (seed3 - 0.5) * size * 0.01;
    final double x = origin.dx + math.cos(angle) * distance + drift;
    final double y =
        origin.dy + math.sin(angle) * distance - smoothLife * size * 0.015;

    final double fadeIn = _smoothStep(
      math.min(smoothLife * config.fadeInGain, 1.0),
    );
    final double fadeOut = _smoothStep(
      math.min((1.0 - smoothLife) * config.fadeOutGain, 1.0),
    );

    double opacity = math.min(fadeIn, fadeOut) * config.maxOpacity;
    final double opJ = 1.0 + (seed3 - 0.5) * 2.0 * config.opacityJitter;
    opacity = (opacity * opJ).clamp(0.0, 1.0);

    final double r = size * config.particleSize * (1.2 - smoothLife * 0.6);

    // Ana parçacık (blur yok)
    bodyPaint.color = sprayColor.withValues(alpha: opacity);
    final Offset p = Offset(x, y);
    canvas.drawCircle(p, r, bodyPaint);

    // Parlak merkez
    if (config.drawCore) {
      bodyPaint.color = Colors.white.withValues(alpha: opacity * 0.4);
      canvas.drawCircle(p, r * config.coreRadiusFactor, bodyPaint);
    }
  }
}

/* ──────────────────── Helpers ─────────────────────────── */

double _fract(double x) => x - x.floorToDouble();

double _smoothStep(double x) {
  x = x.clamp(0.0, 1.0);
  return x * x * (3.0 - 2.0 * x);
}

double _hash01(int x) {
  int h = x;
  h = (h ^ 61) ^ (h >> 16);
  h = h + (h << 3);
  h = h ^ (h >> 4);
  h = h * 0x27d4eb2d;
  h = h ^ (h >> 15);
  return (h & 0x7fffffff) / 0x7fffffff;
}
