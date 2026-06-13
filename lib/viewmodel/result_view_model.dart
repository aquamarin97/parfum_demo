import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/strings/app_strings.dart';
import 'i_result_context.dart';
import 'result_flow_state.dart';
import '../ui/screens/result/models/timeline_message.dart';

class ResultViewModel extends ChangeNotifier {
  ResultViewModel({required this.appViewModel});

  final IResultContext appViewModel;

  ResultFlowState _currentState = ResultFlowState.showingRecommendations;
  int? _selectedTester;
  Timer? _timer;
  final List<TimelineMessage> _messages = [];

  final ValueNotifier<int> timerNotifier = ValueNotifier<int>(300);
  bool _shouldAnimate = false;

  ResultFlowState get currentState => _currentState;
  int? get selectedTester => _selectedTester;
  List<TimelineMessage> get messages => List.unmodifiable(_messages);
  List<int> get topIds => appViewModel.topIds;
  bool get shouldAnimate => _shouldAnimate;
  AppStrings get strings => appViewModel.strings;
  String get priceLabel => appViewModel.priceLabel;

  @protected
  set selectedTester(int? value) => _selectedTester = value;

  @protected
  set shouldAnimate(bool value) => _shouldAnimate = value;

  // --- Public methods (PLC subclass gerektiğinde override eder) ---

  void onTesterSelected(int index) {
    selectedTester = index;
    shouldAnimate = false;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      addMessage(
        "${strings.t('customer_choice')}${topIds[index]}",
        TimelineMessageStatus.completed,
      );
      Future.delayed(const Duration(milliseconds: 300), () {
        addMessage(strings.t('payment_waiting'), TimelineMessageStatus.active);
        transitionToState(ResultFlowState.waitingPayment);
        startTimer(300);
      });
    });
  }

  void onPaymentComplete() {
    cancelTimer();
    updateLastMessage(
      strings.t('payment_completed'),
      TimelineMessageStatus.completed,
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      addMessage(
        strings.t('fragrance_preparing'),
        TimelineMessageStatus.active,
      );
      transitionToState(ResultFlowState.preparingPerfume);
      Future.delayed(const Duration(seconds: 3), _onPerfumeReady);
    });
  }

  void backToTesterSelection() {
    if (topIds.isEmpty) {
      cancelToIdle();
      return;
    }
    cancelTimer();
    clearMessagesAfterFirst();
    _selectedTester = null;
    transitionToState(ResultFlowState.testersReady);
    startTimer(timerNotifier.value);
  }

  void onPaymentError() {
    cancelTimer();
    updateLastMessage(strings.t('payment_failed'), TimelineMessageStatus.error);
    transitionToState(ResultFlowState.paymentError);
  }

  /// Returns to tester selection, cancelling the current payment attempt.
  ///
  /// Guards against the race where [AppViewModel.resetToIdle] clears
  /// [topIds] before the widget tree has had a chance to leave the result
  /// screen (e.g. inactivity timeout fires while the user is still touching
  /// the UI).  In that case the session is already torn down, so the correct
  /// recovery is to complete the idle transition rather than trying to show
  /// [TestersReadyView] with an empty recommendation list.

  void retryPayment() {
    updateLastMessage(
      strings.t('payment_waiting'),
      TimelineMessageStatus.active,
    );
    transitionToState(ResultFlowState.waitingPayment);
    startTimer(300);
  }

  void onGiftCardAnswer(bool wantsCard) {
    if (wantsCard) {
      transitionToStateNoAnim(ResultFlowState.giftCardInput);
    } else {
      transitionToState(ResultFlowState.thankYou);
    }
  }

  void submitGiftCardName(String recipientName) {
    // todo: persist recipientName for gift-card fulfilment flow
    transitionToState(ResultFlowState.thankYou);
  }

  void backToGiftCardQuestion() {
    transitionToStateNoAnim(ResultFlowState.giftCardQuestion);
  }

  void cancelToIdle() {
    appViewModel.cancelToIdle();
  }

  void clearAnimationFlag() {
    _shouldAnimate = false;
    // notifyListeners çağrılmaz — sadece flag sıfırlanır, yeni render tetiklenmez.
  }

  // --- Protected helpers ---

  @protected
  void clearMessagesAfterFirst() {
    while (_messages.length > 1) {
      _messages.removeLast();
    }
  }

  @protected
  void transitionToState(ResultFlowState newState) {
    _currentState = newState;
    _shouldAnimate = true;
    notifyListeners();
  }

  @protected
  void transitionToStateNoAnim(ResultFlowState newState) {
    _currentState = newState;
    _shouldAnimate = false;
    notifyListeners();
  }

  @protected
  void addMessage(String text, TimelineMessageStatus status) {
    _messages.add(TimelineMessage.now(text: text, status: status));
    _shouldAnimate = false;
    notifyListeners();
  }

  @protected
  void addKeyedMessage(String key, TimelineMessageStatus status, {String? arg}) {
    _messages.add(TimelineMessage.now(key: key, arg: arg, status: status));
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
  void updateLastKeyedMessage(String key, TimelineMessageStatus status, {String? arg}) {
    if (_messages.isEmpty) return;
    final lastIndex = _messages.length - 1;
    _messages[lastIndex] = _messages[lastIndex].copyWith(
      key: key,
      arg: arg,
      text: null,
      status: status,
    );
    _shouldAnimate = false;
    notifyListeners();
  }

  /// [fromKey] ile eşleşen son mesajı [toKey] + [status] olarak günceller.
  ///
  /// Mesajlar arasına başka mesajlar girmiş olsa bile doğru mesajı bulur.
  @protected
  void updateKeyedMessageBy(
    String fromKey,
    String toKey,
    TimelineMessageStatus status,
  ) {
    final idx = _messages.lastIndexWhere((m) => m.key == fromKey);
    if (idx == -1) return;
    _messages[idx] = _messages[idx].copyWith(key: toKey, text: null, status: status);
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

  void _onPerfumeReady() {
    updateLastMessage(
      strings.t('fragrance_prepared'),
      TimelineMessageStatus.completed,
    );
    transitionToState(ResultFlowState.perfumeReady);
    Future.delayed(const Duration(seconds: 2), () {
      transitionToState(ResultFlowState.giftCardQuestion);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    timerNotifier.dispose();
    super.dispose();
  }
}
