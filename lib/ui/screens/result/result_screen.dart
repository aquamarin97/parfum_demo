import 'package:flutter/material.dart';
import 'package:parfume_app/ui/screens/loading_indicator.dart';
import 'package:provider/provider.dart';

import '../../../viewmodel/app_view_model.dart';
import '../../../common/widgets/logo_painter_widget.dart';
import 'result_view_model.dart';
import 'models/result_flow_state.dart';
import 'widgets/timeline/timeline_container.dart';
import 'widgets/views/testers_ready_view.dart';
import 'widgets/views/waiting_payment_view.dart';
import 'widgets/views/payment_error_view.dart';
import 'widgets/views/perfume_ready_view.dart';
import 'widgets/views/gift_card_question_view.dart';
import 'widgets/views/thank_you_view.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _logoController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoAnimation;

  static bool _isFirstLoad = true; // ✅ İlk yükleme kontrolü

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Content animasyonu
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Logo animasyonu (sadece ilk yüklemede)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );

    // İlk yüklemede logo animasyonlu başla
    if (_isFirstLoad) {
      _logoController.forward();
      _isFirstLoad = false;
    } else {
      // Sonraki yüklemelerde logo direkt tam
      _logoController.value = 1.0;
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ResultViewModel(appViewModel: widget.viewModel),
      child: Consumer<ResultViewModel>(
        builder: (context, viewModel, _) {
          // Sadece shouldAnimate flag true ise animasyon tetikle
          if (viewModel.shouldAnimate) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _controller.reset();
                _controller.forward().then((_) {
                  if (mounted) {
                    viewModel.clearAnimationFlag();
                  }
                });
              }
            });
          }

          return Stack(
            children: [
              // ✅ Arka planda animasyonlu logo
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: AnimatedLogoPainter(
                        animationValue: _logoAnimation.value,
                      ),
                    );
                  },
                ),
              ),

              // ✅ Üstte içerik
              Padding(
                padding: const EdgeInsets.only(top: 100, left: 100, right: 100),
                child: Column(
                  children: [
                    TimelineContainer(messages: viewModel.messages),
                    const SizedBox(height: 32),
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildContent(viewModel),
                        ),
                      ),
                    ),
                  ],
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
          );
        },
      ),
    );
  }

  Widget _buildContent(ResultViewModel viewModel) {
    Widget content;

    switch (viewModel.currentState) {
      case ResultFlowState.showingRecommendations:
      case ResultFlowState.preparingTesters:
      case ResultFlowState.preparingPerfume:
        content = const SizedBox.shrink();
        break;

      case ResultFlowState.testersReady:
        content = TestersReadyView(viewModel: viewModel);
        break;

      case ResultFlowState.waitingPayment:
        content = WaitingPaymentView(viewModel: viewModel);
        break;

      case ResultFlowState.paymentError:
        content = PaymentErrorView(viewModel: viewModel);
        break;

      case ResultFlowState.perfumeReady:
        content = const PerfumeReadyView();
        break;

      case ResultFlowState.giftCardQuestion:
        content = GiftCardQuestionView(viewModel: viewModel);
        break;

      case ResultFlowState.thankYou:
        content = ThankYouView(viewModel: viewModel); // ✅ viewModel ekle
        break;
    }

    // ✅ Tüm içeriği üstten hizala
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.only(top: 40), child: content),
      ),
    );
  }
}
