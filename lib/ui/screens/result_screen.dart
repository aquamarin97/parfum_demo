// result_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../../viewmodel/app_view_model.dart';
import '../components/primary_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum ResultFlowState {
  showingRecommendations,
  preparingTesters,
  testersReady,
  waitingPayment,
  paymentError,
  preparingPerfume,
  perfumeReady,
  giftCardQuestion,
  thankYou,
}

// Timeline mesaj modeli
class TimelineMessage {
  final String text;
  final TimelineMessageStatus status;
  final DateTime timestamp;

  TimelineMessage({
    required this.text,
    this.status = TimelineMessageStatus.pending,
  }) : timestamp = DateTime.now();

  TimelineMessage copyWith({String? text, TimelineMessageStatus? status}) {
    return TimelineMessage(
      text: text ?? this.text,
      status: status ?? this.status,
    );
  }
}

enum TimelineMessageStatus {
  pending, // Bekliyor (gri)
  active, // Aktif (primary renk)
  completed, // Tamamlandı (yeşil)
  error, // Hata (kırmızı)
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  ResultFlowState _currentState = ResultFlowState.showingRecommendations;
  int? _selectedTester;
  Timer? _timer;
  int _remainingSeconds = 300;
  bool _isProcessing = false;

  // Timeline mesajları
  final List<TimelineMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startFlow();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  void _startFlow() {
    _addMessage(
      "Size özel üç koku önerisi belirlendi",
      TimelineMessageStatus.completed,
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _sendToPLC();
    });
  }

  void _sendToPLC() {
    setState(() {
      _isProcessing = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _onPLCTestersPreparing();
    });
  }

  void _onPLCTestersPreparing() {
    _addMessage("Testerlar hazırlanıyor", TimelineMessageStatus.active);
    _transitionToState(ResultFlowState.preparingTesters);

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      _onPLCTestersReady();
    });
  }

  void _onPLCTestersReady() {
    _updateLastMessage("Testerlar hazırlandı", TimelineMessageStatus.completed);
    _transitionToState(ResultFlowState.testersReady);
    _startTimer(300);
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = seconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onTimeout();
      }
    });
  }

  void _onTimeout() {
    widget.viewModel.resetToIdle();
  }

  void _onTesterSelected(int index) {
    setState(() {
      _selectedTester = index;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final topIds = widget.viewModel.recommendation.topIds;
      _addMessage(
        "Seçiminiz: No. ${topIds[index]}",
        TimelineMessageStatus.completed,
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _addMessage("Ödeme bekleniyor", TimelineMessageStatus.active);
        _transitionToState(ResultFlowState.waitingPayment);
        _startTimer(300);
      });
    });
  }

  void _onPLCPaymentComplete() {
    _timer?.cancel();
    _updateLastMessage("Ödeme tamamlandı", TimelineMessageStatus.completed);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _addMessage(
        "Size özel kokunuz hazırlanıyor",
        TimelineMessageStatus.active,
      );
      _transitionToState(ResultFlowState.preparingPerfume);

      Future.delayed(const Duration(seconds: 8), () {
        if (!mounted) return;
        _onPLCPerfumeReady();
      });
    });
  }

  void _onPLCPerfumeReady() {
    _updateLastMessage(
      "Size özel kokunuz hazırlandı",
      TimelineMessageStatus.completed,
    );
    _transitionToState(ResultFlowState.perfumeReady);

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _transitionToState(ResultFlowState.giftCardQuestion);
    });
  }

  void _onPaymentError() {
    _timer?.cancel();
    _updateLastMessage("Ödeme başarısız oldu", TimelineMessageStatus.error);
    _transitionToState(ResultFlowState.paymentError);
  }

  void _retryPayment() {
    bool isPaid = false;

    if (isPaid) {
      _onPLCPaymentComplete();
    } else {
      _updateLastMessage("Ödeme bekleniyor", TimelineMessageStatus.active);
      _transitionToState(ResultFlowState.waitingPayment);
      _startTimer(300);
    }
  }

  void _onGiftCardAnswer(bool wantsCard) {
    if (wantsCard) {
      _showThankYou();
    } else {
      _addMessage(
        "Hediye kartı oluşturulmadı",
        TimelineMessageStatus.completed,
      );
      _showThankYou();
    }
  }

  void _showThankYou() {
    _transitionToState(ResultFlowState.thankYou);

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      widget.viewModel.resetToIdle();
    });
  }

  void _transitionToState(ResultFlowState newState) {
    _fadeController.reverse().then((_) {
      if (!mounted) return;

      setState(() {
        _currentState = newState;
        _isProcessing = false;
      });

      _fadeController.forward();
      _slideController.reset();
      _slideController.forward();
    });
  }

  // Timeline mesaj yönetimi
  void _addMessage(String text, TimelineMessageStatus status) {
    setState(() {
      _messages.add(TimelineMessage(text: text, status: status));
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _updateLastMessage(String text, TimelineMessageStatus status) {
    if (_messages.isEmpty) return;

    setState(() {
      final lastIndex = _messages.length - 1;
      _messages[lastIndex] = _messages[lastIndex].copyWith(
        text: text,
        status: status,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100, left: 100, right: 100),
      child: Column(
        children: [
          // Timeline üstte
          _buildTimeline(),

          const SizedBox(height: 32),

          // Ana içerik ortada
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildCurrentStateContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_messages.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          return _buildTimelineItem(_messages[index], index);
        },
      ),
    );
  }

  Widget _buildTimelineItem(TimelineMessage message, int index) {
    Color statusColor;
    IconData statusIcon;

    switch (message.status) {
      case TimelineMessageStatus.pending:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.radio_button_unchecked;
        break;
      case TimelineMessageStatus.active:
        statusColor = AppColors.primary;
        statusIcon = Icons.sync;
        break;
      case TimelineMessageStatus.completed:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case TimelineMessageStatus.error:
        statusColor = AppColors.error;
        statusIcon = Icons.error;
        break;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // İkon
                  message.status == TimelineMessageStatus.active
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: statusColor,
                          ),
                        )
                      : Icon(statusIcon, color: statusColor, size: 24),

                  const SizedBox(width: 12),

                  // Mesaj
                  Expanded(
                    child: Text(
                      message.text,
                      style: AppTextStyles.body.copyWith(
                        fontFamily: 'NotoSans',
                        fontWeight:
                            message.status == TimelineMessageStatus.active
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: statusColor,
                      ),
                    ),
                  ),

                  // Zaman damgası
                  Text(
                    _formatTime(message.timestamp),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildCurrentStateContent() {
    switch (_currentState) {
      case ResultFlowState.showingRecommendations:
      case ResultFlowState.preparingTesters:
        return const SizedBox.shrink(); // Timeline'da gösteriliyor

      case ResultFlowState.testersReady:
        return _buildTestersReady();

      case ResultFlowState.waitingPayment:
        return _buildWaitingPayment();

      case ResultFlowState.paymentError:
        return _buildPaymentError();

      case ResultFlowState.preparingPerfume:
        return const SizedBox.shrink(); // Timeline'da gösteriliyor

      case ResultFlowState.perfumeReady:
        return _buildPerfumeReady();

      case ResultFlowState.giftCardQuestion:
        return _buildGiftCardQuestion();

      case ResultFlowState.thankYou:
        return _buildThankYou();
    }
  }

  Widget _buildTestersReady() {
    final topIds = widget.viewModel.recommendation.topIds;

    if (topIds.isEmpty) {
      return Center(
        child: Text("Öneri bulunamadı", style: AppTextStyles.title),
      );
    }

    final displayCount = topIds.length > 3 ? 3 : topIds.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Lütfen seçiminizi belirtin",
          style: AppTextStyles.title.copyWith(
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Seçimler arasında fiyat farkı yoktur",
          style: AppTextStyles.body.copyWith(
            fontFamily: 'NotoSans',
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        _buildTimer(),

        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(displayCount, (index) {
            final isSelected = _selectedTester == index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildTesterButton(
                index: index,
                label: (index + 1).toString(),
                perfumeId: topIds[index],
                isSelected: isSelected,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTesterButton({
    required int index,
    required String label,
    required int perfumeId,
    required bool isSelected,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: InkWell(
            onTap: () => _onTesterSelected(index),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.headline.copyWith(
                      fontFamily: 'NotoSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No. $perfumeId",
                    style: AppTextStyles.body.copyWith(
                      fontFamily: 'NotoSans',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaitingPayment() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Fiyat: 490 TL",
          style: AppTextStyles.headline.copyWith(
            fontFamily: 'NotoSans',
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        _buildTimer(),

        const SizedBox(height: 48),

        // Test butonları
        if (true)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _onPLCPaymentComplete,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text("TEST: Ödeme Tamam"),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _onPaymentError,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text("TEST: Ödeme Hata"),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPaymentError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 80, color: AppColors.error),
        const SizedBox(height: 32),
        Text(
          "Lütfen tekrar deneyin veya iptal edin",
          style: AppTextStyles.title.copyWith(
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrimaryButton(label: "Tekrar Deneyin", onPressed: _retryPayment),
            const SizedBox(width: 24),
            OutlinedButton(
              onPressed: widget.viewModel.resetToIdle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 24,
                ),
                side: const BorderSide(color: AppColors.border, width: 2),
              ),
              child: Text(
                "İptal Et",
                style: AppTextStyles.body.copyWith(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerfumeReady() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: const Icon(
                Icons.check_circle_outline,
                size: 120,
                color: AppColors.success,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGiftCardQuestion() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Hediye kartı oluşturmak ister misiniz?",
          style: AppTextStyles.title.copyWith(
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrimaryButton(
              label: "Evet",
              onPressed: () => _onGiftCardAnswer(true),
            ),
            const SizedBox(width: 24),
            OutlinedButton(
              onPressed: () => _onGiftCardAnswer(false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 24,
                ),
                side: const BorderSide(color: AppColors.border, width: 2),
              ),
              child: Text(
                "Hayır",
                style: AppTextStyles.body.copyWith(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThankYou() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Column(
                  children: [
                    Text(
                      "Güzel günlerde kullanın",
                      style: AppTextStyles.title.copyWith(
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "İyi günler dileriz...",
                      style: AppTextStyles.body.copyWith(
                        fontFamily: 'NotoSans',
                        fontSize: 20,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _remainingSeconds < 60
            ? AppColors.error.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _remainingSeconds < 60 ? AppColors.error : AppColors.border,
          width: 2,
        ),
      ),
      child: Text(
        "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
        style: AppTextStyles.headline.copyWith(
          fontFamily: 'NotoSans',
          fontWeight: FontWeight.bold,
          fontSize: 28,
          color: _remainingSeconds < 60 ? AppColors.error : AppColors.primary,
        ),
      ),
    );
  }
}
