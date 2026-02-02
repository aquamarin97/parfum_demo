// result_view_model_with_plc.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:parfume_app/plc/error/plc_error_codes.dart';
import 'package:parfume_app/plc/plc_service_manager.dart';

import 'package:parfume_app/ui/screens/result/models/result_flow_state.dart';
import 'package:parfume_app/ui/screens/result/models/timeline_message.dart';
import 'package:parfume_app/ui/screens/result/result_view_model.dart';
import 'package:parfume_app/viewmodel/app_view_model.dart';

class ResultViewModelWithPLC extends ResultViewModel {
  final PLCServiceManager plcService;

  ResultViewModelWithPLC({
    required super.appViewModel, // ✅ ResultViewModel alanına geçirir
    required this.plcService,
  }) {
    _startFlow();
  }

  ResultFlowState _currentState = ResultFlowState.showingRecommendations;
  int? _selectedTester;
  Timer? _timer;
  final List<TimelineMessage> _messages = [];
  StreamSubscription? _plcSubscription;

  final ValueNotifier<int> timerNotifier = ValueNotifier<int>(300);
  bool _shouldAnimate = false;

  // Getters
  ResultFlowState get currentState => _currentState;
  int? get selectedTester => _selectedTester;
  List<TimelineMessage> get messages => List.unmodifiable(_messages);
  List<int> get topIds => appViewModel.recommendation.topIds;
  bool get shouldAnimate => _shouldAnimate;
  AppStrings get strings => appViewModel.strings;

  void onTesterSelected(int index) {
    _selectedTester = index;
    _shouldAnimate = false;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () async {
      _addMessage(
        "${strings.customerChoice}${topIds[index]}",
        TimelineMessageStatus.completed,
      );

      try {
        await plcService.sendSelectedTester(index + 1); // 1-based
        Future.delayed(const Duration(milliseconds: 300), () {
          _addMessage(strings.paymentWaiting, TimelineMessageStatus.active);
          _transitionToState(ResultFlowState.waitingPayment);
          _startTimer(300);
          _watchPaymentStatus();
        });
      } on PLCException catch (e) {
        _handlePLCError(e);
      }
    });
  }

  void onPaymentComplete() {
    _timer?.cancel();
    _updateLastMessage(strings.paymentCompleted, TimelineMessageStatus.completed);

    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(strings.fragrancePreparing, TimelineMessageStatus.active);
      _transitionToState(ResultFlowState.preparingPerfume);
      _watchPerfumeReady();
    });
  }

  void onPaymentError() {
    _timer?.cancel();
    _updateLastMessage(strings.paymentFailed, TimelineMessageStatus.error);
    _transitionToState(ResultFlowState.paymentError);
  }

  void retryPayment() {
    _updateLastMessage(strings.paymentWaiting, TimelineMessageStatus.active);
    _transitionToState(ResultFlowState.waitingPayment);
    _startTimer(300);
    _watchPaymentStatus();
  }

  void onGiftCardAnswer(bool wantsCard) {
    if (!wantsCard) {
      _addMessage(strings.giftCardNotCreated, TimelineMessageStatus.completed);
    }
    _showThankYou();
  }

  void cancelToIdle() {
    appViewModel.resetToIdle();
  }

  void clearAnimationFlag() {
    _shouldAnimate = false;
  }

  // --- Flow ---
  void _startFlow() {
    if (!plcService.isConnected) {
      _handlePLCError(
        PLCException(
          errorCode: PLCErrorCodes.connectionLost,
          message: 'PLC bağlantısı yok',
        ),
      );
      return;
    }

    _addMessage(
      strings.fragranceRecommendationsSelected,
      TimelineMessageStatus.completed,
    );

    Future.delayed(const Duration(seconds: 2), _sendToPLC);
  }

  Future<void> _sendToPLC() async {
    try {
      await plcService.sendRecommendations(topIds);
      Future.delayed(const Duration(seconds: 1), _onTestersPreparing);
    } on PLCException catch (e) {
      _handlePLCError(e);
    }
  }

  void _onTestersPreparing() {
    _addMessage(strings.testersPreparing, TimelineMessageStatus.active);
    _transitionToState(ResultFlowState.preparingTesters);
    _watchTestersReady();
  }

  void _watchTestersReady() {
    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchTestersReady().listen(
      (ready) {
        if (ready) _onTestersReady();
      },
      onError: (error) {
        if (error is PLCException) _handlePLCError(error);
      },
    );
  }

  void _onTestersReady() {
    _plcSubscription?.cancel();
    _updateLastMessage(strings.testersPrepared, TimelineMessageStatus.completed);
    _transitionToState(ResultFlowState.testersReady);
    _startTimer(300);
  }

  void _watchPaymentStatus() {
    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchPaymentStatus().listen(
      (status) {
        if (status == 1) onPaymentComplete();
        if (status == 2) onPaymentError();
      },
      onError: (error) {
        if (error is PLCException) _handlePLCError(error);
      },
    );
  }

  void _watchPerfumeReady() {
    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchPerfumeReady().listen(
      (ready) {
        if (ready) _onPerfumeReady();
      },
      onError: (error) {
        if (error is PLCException) _handlePLCError(error);
      },
    );
  }

  void _onPerfumeReady() {
    _plcSubscription?.cancel();
    _updateLastMessage(strings.fragrancePrepared, TimelineMessageStatus.completed);
    _transitionToState(ResultFlowState.perfumeReady);

    Future.delayed(const Duration(seconds: 2), () {
      _transitionToState(ResultFlowState.giftCardQuestion);
    });
  }

  void _showThankYou() {
    _transitionToState(ResultFlowState.thankYou);
    Future.delayed(const Duration(seconds: 10), () {
      appViewModel.resetToIdle();
    });
  }

  void _handlePLCError(PLCException error) {
    debugPrint('[ResultVM] PLC Hatası: ${error.errorCode} - ${error.message}');

    _addMessage(
      error.getUserMessage(appViewModel.language.code),
      TimelineMessageStatus.error,
    );

    // Burada geçici bırakmışsın; idealde ayrı bir error flow state olur.
    _transitionToState(ResultFlowState.paymentError);
  }

  void _transitionToState(ResultFlowState newState) {
    _currentState = newState;
    _shouldAnimate = true;
    notifyListeners();
  }

  void _addMessage(String text, TimelineMessageStatus status) {
    _messages.add(TimelineMessage(text: text, status: status));
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
    _plcSubscription?.cancel();
    timerNotifier.dispose();
    super.dispose();
  }
}
