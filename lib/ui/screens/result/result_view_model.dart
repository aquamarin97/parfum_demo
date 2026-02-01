import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../viewmodel/app_view_model.dart';
import 'models/result_flow_state.dart';
import 'models/timeline_message.dart';

class ResultViewModel extends ChangeNotifier {
  ResultViewModel({required this.appViewModel}) {
    _startFlow();
  }

  final AppViewModel appViewModel;

  ResultFlowState _currentState = ResultFlowState.showingRecommendations;
  int? _selectedTester;
  Timer? _timer;
  final List<TimelineMessage> _messages = [];
  
  // Timer için ayrı ValueNotifier
  final ValueNotifier<int> timerNotifier = ValueNotifier<int>(300);
  
  // Animasyon tetikleyici - SADECE state değişiminde true olur
  bool _shouldAnimate = false;

  // Getters
  ResultFlowState get currentState => _currentState;
  int? get selectedTester => _selectedTester;
  List<TimelineMessage> get messages => List.unmodifiable(_messages);
  List<int> get topIds => appViewModel.recommendation.topIds;
  bool get shouldAnimate => _shouldAnimate;

  // Public methods
  void onTesterSelected(int index) {
    _selectedTester = index;
    _notifyWithoutAnimation(); // Seçim animasyon tetiklemesin

    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(
        "Seçiminiz: No. ${topIds[index]}",
        TimelineMessageStatus.completed,
        animate: false, // Mesaj ekleme animasyon tetiklemesin
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        _addMessage(
          "Ödeme bekleniyor",
          TimelineMessageStatus.active,
          animate: false,
        );
        _transitionToState(ResultFlowState.waitingPayment); // BU animasyon tetikler
        _startTimer(300);
      });
    });
  }

  void onPaymentComplete() {
    _timer?.cancel();
    _updateLastMessage(
      "Ödeme tamamlandı",
      TimelineMessageStatus.completed,
      animate: false,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(
        "Size özel kokunuz hazırlanıyor",
        TimelineMessageStatus.active,
        animate: false,
      );
      _transitionToState(ResultFlowState.preparingPerfume);

      Future.delayed(const Duration(seconds: 8), () {
        _onPerfumeReady();
      });
    });
  }

  void onPaymentError() {
    _timer?.cancel();
    _updateLastMessage(
      "Ödeme başarısız oldu",
      TimelineMessageStatus.error,
      animate: false,
    );
    _transitionToState(ResultFlowState.paymentError);
  }

  void retryPayment() {
    bool isPaid = false;

    if (isPaid) {
      onPaymentComplete();
    } else {
      _updateLastMessage(
        "Ödeme bekleniyor",
        TimelineMessageStatus.active,
        animate: false,
      );
      _transitionToState(ResultFlowState.waitingPayment);
      _startTimer(300);
    }
  }

  void onGiftCardAnswer(bool wantsCard) {
    if (!wantsCard) {
      _addMessage(
        "Hediye kartı oluşturulmadı",
        TimelineMessageStatus.completed,
        animate: false,
      );
    }
    _showThankYou();
  }

  void cancelToIdle() {
    appViewModel.resetToIdle();
  }

  void clearAnimationFlag() {
    _shouldAnimate = false;
  }

  // Private methods
  void _startFlow() {
    _addMessage(
      "Size özel üç koku önerisi belirlendi",
      TimelineMessageStatus.completed,
      animate: false, // İlk mesaj animasyon tetiklemesin
    );

    Future.delayed(const Duration(seconds: 2), () {
      _sendToPLC();
    });
  }

  void _sendToPLC() {
    Future.delayed(const Duration(seconds: 3), () {
      _onTestersPreparing();
    });
  }

  void _onTestersPreparing() {
    _addMessage(
      "Testerlar hazırlanıyor",
      TimelineMessageStatus.active,
      animate: false,
    );
    _transitionToState(ResultFlowState.preparingTesters);

    Future.delayed(const Duration(seconds: 5), () {
      _onTestersReady();
    });
  }

  void _onTestersReady() {
    _updateLastMessage(
      "Testerlar hazırlandı",
      TimelineMessageStatus.completed,
      animate: false,
    );
    _transitionToState(ResultFlowState.testersReady);
    _startTimer(300);
  }

  void _onPerfumeReady() {
    _updateLastMessage(
      "Size özel kokunuz hazırlandı",
      TimelineMessageStatus.completed,
      animate: false,
    );
    _transitionToState(ResultFlowState.perfumeReady);

    Future.delayed(const Duration(seconds: 2), () {
      _transitionToState(ResultFlowState.giftCardQuestion);
    });
  }

  void _showThankYou() {
    _transitionToState(ResultFlowState.thankYou);

    Future.delayed(const Duration(seconds: 4), () {
      appViewModel.resetToIdle();
    });
  }

  void _transitionToState(ResultFlowState newState) {
    _currentState = newState;
    _shouldAnimate = true; // SADECE state değişiminde true
    notifyListeners();
  }

  void _addMessage(
    String text,
    TimelineMessageStatus status, {
    bool animate = false,
  }) {
    _messages.add(TimelineMessage(text: text, status: status));
    if (animate) {
      _shouldAnimate = true;
    }
    notifyListeners();
  }

  void _updateLastMessage(
    String text,
    TimelineMessageStatus status, {
    bool animate = false,
  }) {
    if (_messages.isEmpty) return;

    final lastIndex = _messages.length - 1;
    _messages[lastIndex] = _messages[lastIndex].copyWith(
      text: text,
      status: status,
    );
    if (animate) {
      _shouldAnimate = true;
    }
    notifyListeners();
  }

  void _notifyWithoutAnimation() {
    _shouldAnimate = false;
    notifyListeners();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    timerNotifier.value = seconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timerNotifier.value--;

      if (timerNotifier.value <= 0) {
        timer.cancel();
        appViewModel.resetToIdle();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    timerNotifier.dispose();
    super.dispose();
  }
}