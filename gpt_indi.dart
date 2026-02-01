import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class ScentWavesLoader extends StatefulWidget {
  const ScentWavesLoader({
    super.key,
    this.size = 200,
    this.primaryColor,
    this.sprayColor,
    this.waveColor,
    this.moleculeColors,
    this.sprayConfig = const SprayEffectConfig(),
  });

  final double size;
  final Color? primaryColor; // Şişe rengi
  final Color? sprayColor; // Sprey rengi (varsayılan: beyaz)
  final Color? waveColor; // Dalga rengi (varsayılan: primaryColor)
  final List<Color>? moleculeColors; // Molekül renkleri
  final SprayEffectConfig sprayConfig; // <-- dışarıdan ayarlanabilir

  @override
  State<ScentWavesLoader> createState() => _ScentWavesLoaderState();
}

class _ScentWavesLoaderState extends State<ScentWavesLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final Stopwatch _sw = Stopwatch();

  @override
  void initState() {
    super.initState();
    _sw.start();

    // sadece repaint tetiklemek için
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    _sw.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.primaryColor ?? Theme.of(context).colorScheme.primary;

    final sprayColor = widget.sprayColor ?? Colors.white;
    final waveColor = widget.waveColor ?? baseColor;
    final moleculeColors =
        widget.moleculeColors ?? _createHarmonicPalette(baseColor);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final tSeconds = _sw.elapsedMicroseconds / 1e6; // <-- sürekli akan zaman
          return CustomPaint(
            painter: _ScentWavesPainter(
              t: tSeconds,
              primaryColor: baseColor,
              sprayColor: sprayColor,
              waveColor: waveColor,
              moleculeColors: moleculeColors,
              size: widget.size,
              sprayConfig: widget.sprayConfig,
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
  });

  final double t; // seconds, continuous
  final Color primaryColor;
  final Color sprayColor;
  final Color waveColor;
  final List<Color> moleculeColors;
  final double size;
  final SprayEffectConfig sprayConfig;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final c = Offset(canvasSize.width / 2, canvasSize.height / 2);

    // Dış glow efekti
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.2)
      ..color = waveColor.withOpacity(0.12);

    canvas.drawCircle(c, size * 0.3, glowPaint);

    // Koku dalgaları - çift yönlü
    _drawFragranceWaves(canvas, c, clockwise: true);
    _drawFragranceWaves(canvas, c, clockwise: false);

    // Uçuşan koku molekülleri (renkli)
    _drawFragranceMolecules(canvas, c);

    // Merkezdeki parfüm şişesi + sprey
    _drawPerfumeBottle(canvas, c);
  }

  void _drawFragranceWaves(Canvas canvas, Offset center, {required bool clockwise}) {
    final waveCount = clockwise ? 3 : 2;

    for (int i = 0; i < waveCount; i++) {
      final offset = clockwise ? i * 0.33 : i * 0.5;

      // t saniye olduğu için burada 0..1'e sarıyoruz (bu dalga için sorun değil)
      final phase = _fract(t * 0.18 + offset);
      final smoothPhase = _smoothStep(phase);

      final radius = (size * 0.12) + smoothPhase * (size * 0.38);
      final rawOpacity = 1.0 - smoothPhase;
      final opacity = _smoothStep(rawOpacity) * 0.5;
      final strokeWidth = (size * 0.014) * (1.3 - smoothPhase * 0.5);

      final path = Path();
      const segments = 80;

      final rotationSpeed = clockwise ? 1.0 : -0.7;
      final rotation = t * math.pi * 2 * rotationSpeed;

      for (int j = 0; j <= segments; j++) {
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
        ..color = waveColor.withOpacity(opacity)
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, paint);
    }
  }

  void _drawFragranceMolecules(Canvas canvas, Offset center) {
    const particleCount = 25;

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

      final x = center.dx +
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

      final path = Path();
      const sides = 6;
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
        ..color = particleColor.withOpacity(opacity * 0.7);

      canvas.drawPath(path, paint);

      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particleSize * 2.5)
        ..color = particleColor.withOpacity(opacity * 0.4);

      canvas.drawCircle(Offset(x, y), particleSize * 0.6, glowPaint);
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
    final bottomRight = Offset(
      center.dx + baseWidth / 2,
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

    canvas.drawShadow(
      bottlePath,
      Colors.black.withOpacity(0.3),
      size * 0.05,
      true,
    );

    final bottlePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          primaryColor.withOpacity(0.7),
          primaryColor.withOpacity(0.95),
          primaryColor.withOpacity(0.7),
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
      ..color = primaryColor.withOpacity(0.4);

    canvas.drawPath(bottlePath, outlinePaint);

    // Sıvı seviyesi
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
      ..color = primaryColor.withOpacity(0.85);

    canvas.drawPath(liquidPath, liquidPaint);

    // Sprey efekti (yeni, performanslı, simetri kırık)
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
        oldDelegate.sprayConfig != sprayConfig ||
        oldDelegate.moleculeColors != moleculeColors;
  }
}

/* ===================== Spray (Smoky + Natural + Cached Blur) ===================== */

class SprayEffectConfig {
  final int particles;

  /// Akış hızı (seconds -> life)
  final double speed;

  /// Fan açısı
  final double fanAngle;

  /// Yön
  final double baseAngle;

  /// Menzil (size çarpanı)
  final double range;

  /// Parçacık yarıçapı (size çarpanı)
  final double particleSize;

  /// Maks opaklık
  final double maxOpacity;

  /// Fade eğrileri
  final double fadeInGain;
  final double fadeOutGain;

  /// Hafif salınım
  final double wobbleAmp;
  final double wobbleFreq;

  /// Simetri kırma
  final double angleJitter;
  final double distJitter;
  final double opacityJitter;

  /// DUMAN hissi için en kritik parametreler:
  /// Blur sigma = radius * blurMultiplier
  final double blurMultiplier;

  /// Ek mist/halo katmanı
  final double mistMultiplier;      // halo radius çarpanı
  final double mistOpacityFactor;   // halo opacity çarpanı

  /// Merkez/halka (istersen kapatabilirsin)
  final bool drawCore;
  final bool drawRing;
  final double coreRadiusFactor;
  final double ringRadiusFactor;
  final double ringStrokeFactor;

  /// Blur cache hassasiyeti (seviye sayısı)
  final int blurLevels;

  const SprayEffectConfig({
    this.particles = 18,
    this.speed = 1.35,
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

    // 🔥 Dumanı geri getiren ana ayar
    this.blurMultiplier = 1.9,

    // Ek mist halo (çok yumuşak duman)
    this.mistMultiplier = 1.9,
    this.mistOpacityFactor = 0.35,

    // Core/ring
    this.drawCore = true,
    this.drawRing = true,
    this.coreRadiusFactor = 0.40,
    this.ringRadiusFactor = 0.80,
    this.ringStrokeFactor = 0.003,

    // cache
    this.blurLevels = 14,
  });
}

/// Blur cache: sigma quantized
final Map<int, List<MaskFilter>> _sprayBlurCache = {};

List<MaskFilter> _getSprayBlurCache({
  required int levels,
  required double sigmaMin,
  required double sigmaMax,
}) {
  final int lv = math.max(1, levels);
  final int key = (lv * 1000000) ^ (sigmaMin * 100).round() ^ (sigmaMax * 100).round();

  return _sprayBlurCache.putIfAbsent(key, () {
    if (lv == 1) {
      return [MaskFilter.blur(BlurStyle.normal, (sigmaMin + sigmaMax) * 0.5)];
    }
    return List<MaskFilter>.generate(lv, (i) {
      final double k = i / (lv - 1);
      // sigma aralığı: mist için geniş
      final double sigma = sigmaMin + (sigmaMax - sigmaMin) * k;
      return MaskFilter.blur(BlurStyle.normal, sigma);
    }, growable: false);
  });
}

void drawSprayEffect({
  required Canvas canvas,
  required Offset origin,
  required double t, // seconds, continuous
  required double size,
  required Color sprayColor,
  SprayEffectConfig config = const SprayEffectConfig(),
}) {
  final int n = math.max(1, config.particles);
  final double invN = 1.0 / n;

  // Paints loop dışı
  final Paint bodyPaint = Paint()
    ..style = PaintingStyle.fill;

  final Paint mistPaint = Paint()
    ..style = PaintingStyle.fill;

  final Paint corePaint = Paint()
    ..style = PaintingStyle.fill;

  final Paint ringPaint = Paint()
    ..style = PaintingStyle.stroke;

  // Blur sigma aralığını "boyuta göre" dinamik seçiyoruz.
  // Böylece küçük widget’ta da büyük widget’ta da duman aynı hissi verir.
  final double baseR = size * config.particleSize; // tipik radius ölçeği
  final double sigmaMin = (baseR * 0.8 * config.blurMultiplier).clamp(0.6, 12.0);
  final double sigmaMax = (baseR * 2.8 * config.blurMultiplier).clamp(2.0, 30.0);

  final blurCache = _getSprayBlurCache(
    levels: config.blurLevels,
    sigmaMin: sigmaMin,
    sigmaMax: sigmaMax,
  );

  for (int i = 0; i < n; i++) {
    final double phaseOffset = i * invN;

    // deterministic seeds
    final double seed = _hash01(i + 1337);
    final double seed2 = _hash01(i + 7331);
    final double seed3 = _hash01(i + 9001);

    // life 0..1
    final double life = _fract(t * config.speed + phaseOffset);

    // triple smoothstep (eski hissiyat)
    final double smoothLife = _smoothStep(_smoothStep(_smoothStep(life)));

    // açı
    final double spread = (phaseOffset - 0.5) * config.fanAngle;
    final double jitterA = (seed - 0.5) * 2.0 * config.angleJitter;
    final double baseAngle = config.baseAngle + spread + jitterA;

    final double wobble =
        math.sin(t * math.pi * config.wobbleFreq + seed2 * math.pi * 2.0) *
        config.wobbleAmp;

    final double angle = baseAngle + wobble;

    // mesafe
    final double distJ = 1.0 + (seed2 - 0.5) * 2.0 * config.distJitter;
    final double distance = smoothLife * size * config.range * distJ;

    // “duman” için hafif yukarı sürüklenme (çok küçük)
    final double drift = (seed3 - 0.5) * size * 0.01;
    final double x = origin.dx + math.cos(angle) * distance + drift;
    final double y = origin.dy + math.sin(angle) * distance - smoothLife * size * 0.015;

    // opaklık
    final double fadeIn =
        _smoothStep(math.min(smoothLife * config.fadeInGain, 1.0));
    final double fadeOut =
        _smoothStep(math.min((1.0 - smoothLife) * config.fadeOutGain, 1.0));

    double opacity = math.min(fadeIn, fadeOut) * config.maxOpacity;

    // opacity jitter (dumanı dalgalandırır)
    final double opJ = 1.0 + (seed3 - 0.5) * 2.0 * config.opacityJitter;
    opacity = (opacity * opJ).clamp(0.0, 1.0);

    // radius (eski gibi)
    final double r = size * config.particleSize * (1.2 - smoothLife * 0.6);

    // sigma = r * blurMultiplier (dumanın ana kaynağı)
    final double sigma = (r * config.blurMultiplier).clamp(sigmaMin, sigmaMax);
    final int blurIdx = _quantize01(
      (sigma - sigmaMin) / (sigmaMax - sigmaMin + 1e-6),
      config.blurLevels,
    );

    // 1) Duman gövdesi (soft blob)
    bodyPaint
      ..maskFilter = blurCache[blurIdx]
      ..color = sprayColor.withOpacity(opacity);

    // 2) Ek mist halo (daha büyük, daha düşük alpha) -> “duman” hissi
    final double mistR = r * config.mistMultiplier;
    final double mistSigma = (mistR * config.blurMultiplier).clamp(sigmaMin, sigmaMax);
    final int mistIdx = _quantize01(
      (mistSigma - sigmaMin) / (sigmaMax - sigmaMin + 1e-6),
      config.blurLevels,
    );

    mistPaint
      ..maskFilter = blurCache[mistIdx]
      ..color = sprayColor.withOpacity(opacity * config.mistOpacityFactor);

    final Offset p = Offset(x, y);

    // çizim sırası önemli: önce halo, sonra gövde
    canvas.drawCircle(p, mistR, mistPaint);
    canvas.drawCircle(p, r, bodyPaint);

    // 3) Parlak merkez (istersen kapat)
    if (config.drawCore) {
      corePaint.color = Colors.white.withOpacity(opacity * 0.35);
      canvas.drawCircle(p, r * config.coreRadiusFactor, corePaint);
    }

    // 4) İnce halka (istersen kapat)
    if (config.drawRing) {
      ringPaint
        ..strokeWidth = size * config.ringStrokeFactor
        ..color = sprayColor.withOpacity(opacity * 0.18);
      canvas.drawCircle(p, r * config.ringRadiusFactor, ringPaint);
    }
  }
}


/* ===================== Helpers ===================== */

double _fract(double x) => x - x.floorToDouble();

double _smoothStep(double x) {
  x = x.clamp(0.0, 1.0);
  return x * x * (3.0 - 2.0 * x);
}

int _quantize01(double x, int levels) {
  if (levels <= 1) return 0;
  final double clamped = x.clamp(0.0, 1.0);
  final int idx = (clamped * (levels - 1)).round();
  return idx.clamp(0, levels - 1);
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
