// question_screen.dart (güncellenmiş)
import 'package:flutter/material.dart';
import 'package:parfume_app/common/widgets/logo_painter_widget.dart';
import 'package:parfume_app/ui/components/top_nav_bar.dart';
import 'package:parfume_app/ui/screens/loading_indicator.dart';

import '../../viewmodel/app_view_model.dart';
import '../components/radio_option_list.dart';
import '../theme/app_text_styles.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen>
    with TickerProviderStateMixin {
  late AnimationController _questionController;
  late AnimationController _logoController;
  late Animation<double> _questionAnimation;
  late Animation<Offset> _questionSlideAnimation;
  static bool _isFirstLoad = true;
  String _currentQuestionText = '';

  @override
  void initState() {
    super.initState();
    _currentQuestionText = widget.viewModel.currentQuestion.text;
    _setupAnimations();
  }

  void _setupAnimations() {
    // Logo animasyonu (sadece ilk yüklemede)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Soru animasyonu (her soru değişiminde)
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _questionAnimation = CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeOut,
    );

    _questionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(_questionAnimation);

    if (_isFirstLoad) {
      _logoController.forward();
    }
    _questionController.forward();
  }

  @override
  void didUpdateWidget(QuestionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Soru metni değişti mi kontrol et
    final newQuestionText = widget.viewModel.currentQuestion.text;
    if (_currentQuestionText != newQuestionText) {
      _currentQuestionText = newQuestionText;

      // Animasyonu sıfırla ve tekrar başlat
      _questionController.reset();
      _questionController.forward();
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.viewModel.currentQuestion;
    final selection = widget.viewModel.currentSelectionIndex;
    final strings = widget.viewModel.strings;

    return Stack(
      children: [
        // 🎨 Logo sadece ilk yüklemede animate olur
        if (_isFirstLoad)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                // İlk yükleme tamamlandığında flag'i kapat
                if (_logoController.isCompleted) {
                  Future.delayed(Duration.zero, () {
                    if (mounted) {
                      setState(() {
                        _isFirstLoad = false;
                      });
                    }
                  });
                }
                return CustomPaint(
                  painter: AnimatedLogoPainter(
                    animationValue: _logoController.value,
                  ),
                );
              },
            ),
          )
        else
          // Sonraki sorularda statik logo
          Positioned.fill(
            child: CustomPaint(
              painter: AnimatedLogoPainter(animationValue: 1.0),
            ),
          ),

        // 📄 İçerik
        Column(
          children: [
            TopNavBar(
              title: widget.viewModel.progressLabel,
              backLabel: strings.t('back'),
              cancelLabel: strings.t('cancel'),
              onBack: widget.viewModel.goBackQuestion,
              onCancel: widget.viewModel.cancelToIdle,
              backEnabled: widget.viewModel.canGoBack,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 100,
                  vertical: 25,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Soru animasyonu - yukarıdan aşağı (her soru için)
                      FadeTransition(
                        opacity: _questionAnimation,
                        child: SlideTransition(
                          position: _questionSlideAnimation,
                          child: Text(
                            question.text,
                            key: ValueKey(question.text),
                            style: AppTextStyles.title,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Şıklar animasyonlu
                      RadioOptionList(
                        key: ValueKey(question.text),
                        options: question.options,
                        selectedIndex: selection,
                        onSelect: widget.viewModel.answerCurrentQuestion,
                        isRtl: widget.viewModel.language.isRtl,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 0),
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
      ],
    );
  }
}
