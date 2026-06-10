import 'package:flutter/material.dart';
import 'package:parfume_app/core/constants/app_constants.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';
import 'package:parfume_app/viewmodel/result_view_model_with_plc.dart';
import 'package:provider/provider.dart';

import '../../../viewmodel/app_view_model.dart';
import '../../../viewmodel/result_flow_state.dart';
import 'widgets/timeline/timeline_container.dart';
import 'widgets/views/gift_card_input_view.dart';
import 'widgets/views/gift_card_question_view.dart';
import 'widgets/views/payment_error_view.dart';
import 'widgets/views/perfume_ready_view.dart';
import 'widgets/views/testers_ready_view.dart';
import 'widgets/views/thank_you_view.dart';
import 'widgets/views/waiting_payment_view.dart';

/// Displays the result workflow while root-level decorative layers remain fixed.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late ResultViewModelWithPLC _resultViewModel;
  bool _thankYouTimerStarted = false;

  @override
  void initState() {
    super.initState();
    _resultViewModel = ResultViewModelWithPLC(
      appViewModel: widget.viewModel,
      plcService: widget.viewModel.plcService,
    );
    _setupAnimations();
    _resultViewModel.addListener(_onViewModelChanged);
  }

  /// Replays the result content transition when the flow asks for animation.
  /// Starts the auto-return countdown when the thank-you state is reached.
  void _onViewModelChanged() {
    if (!mounted) return;
    if (_resultViewModel.shouldAnimate) {
      _controller.reset();
      _controller.forward().then((_) {
        if (mounted) _resultViewModel.clearAnimationFlag();
      });
    }
    if (_resultViewModel.currentState == ResultFlowState.thankYou &&
        !_thankYouTimerStarted) {
      _thankYouTimerStarted = true;
      Future.delayed(AppConstants.thankYouAutoReturn, () {
        if (mounted) widget.viewModel.resetToIdle();
      });
    }
  }

  /// Initialises the result content transition animation.
  void _setupAnimations() {
    _controller = AnimationController(
      duration: AppConstants.resultTransitionDuration,
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

    _controller.forward();
  }

  @override
  void dispose() {
    _resultViewModel.removeListener(_onViewModelChanged);
    _resultViewModel.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _resultViewModel,
      child: Consumer<ResultViewModelWithPLC>(
        builder: (context, viewModel, _) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSizes.screenPaddingTop,
                  left: AppSizes.screenPaddingH,
                  right: AppSizes.screenPaddingH,
                ),
                child: Column(
                  children: [
                    TimelineContainer(
                      messages: viewModel.messages,
                      strings: viewModel.strings,
                    ),
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
              Positioned(
                left: 30,
                bottom: 30,
                child: _ResultCancelButton(
                  label: viewModel.strings.t('cancel'),
                  onPressed: _canCancel(viewModel.currentState)
                      ? viewModel.cancelToIdle
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _canCancel(ResultFlowState state) => switch (state) {
    ResultFlowState.showingRecommendations ||
    ResultFlowState.preparingTesters ||
    ResultFlowState.testersReady ||
    ResultFlowState.waitingPayment ||
    ResultFlowState.paymentError => true,
    ResultFlowState.preparingPerfume ||
    ResultFlowState.perfumeReady ||
    ResultFlowState.giftCardQuestion ||
    ResultFlowState.giftCardInput ||
    ResultFlowState.thankYou => false,
  };

  /// Maps the current [ResultFlowState] to the appropriate content widget.
  Widget _buildContent(ResultViewModelWithPLC viewModel) {
    final content = switch (viewModel.currentState) {
      ResultFlowState.showingRecommendations ||
      ResultFlowState.preparingTesters ||
      ResultFlowState.preparingPerfume    => const SizedBox.shrink(),
      ResultFlowState.testersReady        => TestersReadyView(viewModel: viewModel),
      ResultFlowState.waitingPayment      => WaitingPaymentView(viewModel: viewModel),
      ResultFlowState.paymentError        => PaymentErrorView(viewModel: viewModel),
      ResultFlowState.perfumeReady        => const PerfumeReadyView(),
      ResultFlowState.giftCardQuestion    => GiftCardQuestionView(viewModel: viewModel),
      ResultFlowState.giftCardInput       => GiftCardInputView(viewModel: viewModel),
      ResultFlowState.thankYou            => ThankYouView(viewModel: viewModel),
    };

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: content
      ),
    );
  }
}

class _ResultCancelButton extends StatelessWidget {
  const _ResultCancelButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(
          color: enabled ? AppColors.dangerRed : AppColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowExtraLight,
            blurRadius: AppSizes.languageSwitcherShadowBlur,
            offset: Offset(0, AppSizes.languageSwitcherShadowOffsetY),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor:
              enabled ? AppColors.dangerRed : AppColors.textSecondary,
          disabledForegroundColor: AppColors.textSecondary.withValues(
            alpha: 0.45,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.actionButtonPaddingH,
            vertical: AppSizes.radioOptionPadding,
          ),
          textStyle: AppTextStyles.topBarAction.copyWith(
            fontSize: AppSizes.actionButtonFontSize,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
