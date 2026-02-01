// idle_screen.dart (güncellenmiş)
import 'package:flutter/material.dart';
import 'package:parfume_app/common/widgets/brand_ventuse_widget.dart';
import 'package:parfume_app/common/widgets/logo_painter_widget.dart';
import 'package:parfume_app/ui/screens/loading_indicator.dart';

import '../../viewmodel/app_view_model.dart';
import '../components/primary_button.dart';
import '../theme/app_text_styles.dart';

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
  String _currentLanguageCode = '';

  @override
  void initState() {
    super.initState();
    _currentLanguageCode = widget.viewModel.currentLanguage.code;
    _setupAnimation();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();
  }

  @override
  void didUpdateWidget(IdleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Dil değişti mi kontrol et
    final newLanguageCode = widget.viewModel.currentLanguage.code;
    if (_currentLanguageCode != newLanguageCode) {
      _currentLanguageCode = newLanguageCode;

      // Animasyonu yeniden başlat
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isRtl = widget.viewModel.currentLanguage.isRtl;

    return Scaffold(
      body: Stack(
        children: [
          // Animasyonlu Logo
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: AnimatedLogoPainter(
                    animationValue: _animation.value,
                  ),
                );
              },
            ),
          ),

          // Fade-in animasyonu ile gelen metin
          Positioned(
            left: isRtl ? null : 130,
            right: isRtl ? 130 : null,
            top: 140,
            child: FadeTransition(
              opacity: _animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(_animation),
                child: Column(
                  key: ValueKey(
                    _currentLanguageCode,
                  ), // Dil değişince yeni widget
                  crossAxisAlignment: isRtl
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.viewModel.strings.idleTitle_1,
                      style: AppTextStyles.headline.copyWith(
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: widget.viewModel.strings.idleTitle_2,
                            style: AppTextStyles.headline.copyWith(
                              fontFamily: 'NotoSans',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: VentuseText(
                              text: widget.viewModel.strings.brandName,
                            ),
                          ),
                        ],
                      ),
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Orta kısımdaki buton ve alt bilgi
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 100),
              child: FadeTransition(
                opacity: _animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_animation),
                  child: Column(
                    key: ValueKey('${_currentLanguageCode}_center'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.viewModel.strings.idleSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title.copyWith(
                          fontFamily: 'NotoSans',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 100),
                      PrimaryButton(
                        label: widget.viewModel.strings.start,
                        onPressed: widget.viewModel.startKvkk,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: const ScentWavesLoader(
                size: 600,
                primaryColor: Color(0xFFF18142),
                waveGradientType: WaveGradientType.solid, // En hızlı
                waveColor: Color.fromARGB(255, 60, 15, 119),
                sprayConfig: KioskOptimizedConfig.sprayConfig,
                useOptimizedSettings: true, // ÖNEMLİ!
              ),
            ),
          ),
        ],
      ),
    );
  }
}
