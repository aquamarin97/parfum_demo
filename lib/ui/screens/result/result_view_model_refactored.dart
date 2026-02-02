// result_view_model.dart
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
  AppStrings get strings => appViewModel.strings;

  // ✅ Protected setters (child class'lar için)
  @protected
  set selectedTester(int? value) => _selectedTester = value;
  
  @protected
  set shouldAnimate(bool value) => _shouldAnimate = value;

  // Public methods...
  void onTesterSelected(int index) { /* mevcut kod */ }
  void onPaymentComplete() { /* mevcut kod */ }
  void onPaymentError() { /* mevcut kod */ }
  void retryPayment() { /* mevcut kod */ }
  void onGiftCardAnswer(bool wantsCard) { /* mevcut kod */ }
  void cancelToIdle() { /* mevcut kod */ }
  void clearAnimationFlag() { /* mevcut kod */ }

  // ✅ Protected methods (child class'lar override edebilir)
  @protected
  void transitionToState(ResultFlowState newState) {
    _currentState = newState;
    _shouldAnimate = true;
    notifyListeners();
  }

  @protected
  void addMessage(String text, TimelineMessageStatus status) {
    _messages.add(TimelineMessage(text: text, status: status));
    _shouldAnimate = false;
    notifyListeners();
  }

  @protected
  void updateLastMessage(String text, TimelineMessageStatus status) {
    if (_messages.isEmpty) return;
    final lastIndex = _messages.length - 1;
    _messages[lastIndex] = _messages[lastIndex].copyWith(
      text: text,
      status: status,
    );
    _shouldAnimate = false;
    notifyListeners();
  }

  @protected
  void startTimer(int seconds) {
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

  @protected
  void cancelTimer() {
    _timer?.cancel();
  }

  // Private methods (child class'lar erişemez)
  void _startFlow() { /* mevcut kod */ }
  void _sendToPLC() { /* mevcut kod */ }
  void _onTestersPreparing() { /* mevcut kod */ }
  void _onTestersReady() { /* mevcut kod */ }
  void _onPerfumeReady() { /* mevcut kod */ }
  void _showThankYou() { /* mevcut kod */ }

  @override
  void dispose() {
    _timer?.cancel();
    timerNotifier.dispose();
    super.dispose();
  }
}