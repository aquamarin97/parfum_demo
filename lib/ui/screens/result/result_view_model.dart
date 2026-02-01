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

  final ValueNotifier<int> timerNotifier = ValueNotifier<int>(300);

  bool _shouldAnimate = false;

  // Getters
  ResultFlowState get currentState => _currentState;
  int? get selectedTester => _selectedTester;
  List<TimelineMessage> get messages => List.unmodifiable(_messages);
  List<int> get topIds => appViewModel.recommendation.topIds;
  bool get shouldAnimate => _shouldAnimate;

  void onTesterSelected(int index) {
    _selectedTester = index;
    // ❌ ANIMASYON TETİKLEME
    _shouldAnimate = false;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(
        "Seçiminiz: No. ${topIds[index]}",
        TimelineMessageStatus.completed,
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        _addMessage("Ödeme bekleniyor", TimelineMessageStatus.active);
        _transitionToState(ResultFlowState.waitingPayment); // ✅ BURADA TETİKLE
        _startTimer(300);
      });
    });
  }

  void onPaymentComplete() {
    _timer?.cancel();
    _updateLastMessage("Ödeme tamamlandı", TimelineMessageStatus.completed);

    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(
        "Size özel kokunuz hazırlanıyor",
        TimelineMessageStatus.active,
      );
      _transitionToState(ResultFlowState.preparingPerfume); // ✅ TETİKLE

      Future.delayed(const Duration(seconds: 8), () {
        _onPerfumeReady();
      });
    });
  }

  void onPaymentError() {
    _timer?.cancel();
    _updateLastMessage("Ödeme başarısız oldu", TimelineMessageStatus.error);
    _transitionToState(ResultFlowState.paymentError); // ✅ TETİKLE
  }

  void retryPayment() {
    bool isPaid = false;

    if (isPaid) {
      onPaymentComplete();
    } else {
      _updateLastMessage("Ödeme bekleniyor", TimelineMessageStatus.active);
      _transitionToState(ResultFlowState.waitingPayment); // ✅ TETİKLE
      _startTimer(300);
    }
  }

  void onGiftCardAnswer(bool wantsCard) {
    if (!wantsCard) {
      _addMessage(
        "Hediye kartı oluşturulmadı",
        TimelineMessageStatus.completed,
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
    _addMessage("Testerlar hazırlanıyor", TimelineMessageStatus.active);
    _transitionToState(ResultFlowState.preparingTesters); // ✅ TETİKLE

    Future.delayed(const Duration(seconds: 5), () {
      _onTestersReady();
    });
  }

  void _onTestersReady() {
    _updateLastMessage("Testerlar hazırlandı", TimelineMessageStatus.completed);
    _transitionToState(ResultFlowState.testersReady); // ✅ TETİKLE
    _startTimer(300);
  }

  void _onPerfumeReady() {
    _updateLastMessage(
      "Size özel kokunuz hazırlandı",
      TimelineMessageStatus.completed,
    );
    _transitionToState(ResultFlowState.perfumeReady); // ✅ TETİKLE

    Future.delayed(const Duration(seconds: 2), () {
      _transitionToState(ResultFlowState.giftCardQuestion); // ✅ TETİKLE
    });
  }

  void _showThankYou() {
    _transitionToState(ResultFlowState.thankYou); // ✅ TETİKLE

    Future.delayed(const Duration(seconds: 4), () {
      appViewModel.resetToIdle();
    });
  }

  void _transitionToState(ResultFlowState newState) {
    _currentState = newState;
    _shouldAnimate = true; // ✅ SADECE BURADA TRUE
    notifyListeners();
  }

  void _addMessage(String text, TimelineMessageStatus status) {
    _messages.add(TimelineMessage(text: text, status: status));
    // ❌ ANIMASYON TETİKLEME
    _shouldAnimate = false;
    notifyListeners();
  }

  void _updateLastMessage(String text, TimelineMessageStatus status) {
    if (_messages.isEmpty) return;

    final lastIndex = _messages.length - 1;
    _messages[lastIndex] = _messages[lastIndex].copyWith(
      text: text,
      status: status,
    );
    // ❌ ANIMASYON TETİKLEME
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
