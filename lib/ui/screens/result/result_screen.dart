import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodel/app_view_model.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    // İlk animasyon başlasın
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
                _fadeController.reverse().then((_) {
                  if (mounted) {
                    _fadeController.forward();
                    // Animasyon bittikten sonra flag'i temizle
                    viewModel.clearAnimationFlag();
                  }
                });
              }
            });
          }

          return Padding(
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
          );
        },
      ),
    );
  }

  Widget _buildContent(ResultViewModel viewModel) {
    switch (viewModel.currentState) {
      case ResultFlowState.showingRecommendations:
      case ResultFlowState.preparingTesters:
      case ResultFlowState.preparingPerfume:
        return const SizedBox.shrink();

      case ResultFlowState.testersReady:
        return TestersReadyView(viewModel: viewModel);

      case ResultFlowState.waitingPayment:
        return WaitingPaymentView(viewModel: viewModel);

      case ResultFlowState.paymentError:
        return PaymentErrorView(viewModel: viewModel);

      case ResultFlowState.perfumeReady:
        return const PerfumeReadyView();

      case ResultFlowState.giftCardQuestion:
        return GiftCardQuestionView(viewModel: viewModel);

      case ResultFlowState.thankYou:
        return const ThankYouView();
    }
  }
}