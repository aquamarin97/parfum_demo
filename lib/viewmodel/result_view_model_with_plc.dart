import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:parfume_app/domain/plc/plc_exceptions.dart';
import 'package:parfume_app/infrastructure/plc/plc_service_manager.dart';
import 'package:parfume_app/viewmodel/result_view_model.dart';

import 'result_flow_state.dart';
import '../ui/screens/result/models/timeline_message.dart';

/// PLC-integrated extension of [ResultViewModel].
///
/// Overrides the flow methods that require hardware communication and adds
/// PLC-specific steps (sending recommendations, watching tester/payment/
/// perfume signals). Falls back to a timed mock flow when the PLC is not
/// connected, so the UI remains functional during development and testing.
class ResultViewModelWithPLC extends ResultViewModel {
  /// Creates a [ResultViewModelWithPLC] and immediately starts the PLC flow.
  ///
  /// [plcService] must be injected from outside; this class never creates or
  /// owns the service manager.
  ResultViewModelWithPLC({
    required super.appViewModel,
    required this.plcService,
  }) {
    _initializePLCFlow();
  }

  /// The PLC service used for all hardware communication.
  final PLCServiceManager plcService;

  StreamSubscription? _plcSubscription;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Starts the result flow, using the PLC when connected or mock timers
  /// otherwise.
  void _initializePLCFlow() {
    if (!plcService.isConnected) {
      debugPrint('[ResultVM] PLC not connected — using mock flow.');
      addMessage(
        '${strings.t('fragrance_recommendations_selected')} (Mock Mode)',
        TimelineMessageStatus.completed,
      );
      Future.delayed(const Duration(seconds: 2), _onTestersPreparing);
      return;
    }

    addMessage(
      strings.t('fragrance_recommendations_selected'),
      TimelineMessageStatus.completed,
    );
    Future.delayed(const Duration(seconds: 2), _sendToPLC);
  }

  // ---------------------------------------------------------------------------
  // Overrides
  // ---------------------------------------------------------------------------

  /// Handles tester selection, sends the choice to the PLC, then waits for
  /// payment.
  ///
  /// PLC send errors are non-fatal: the flow continues even if the write
  /// fails, because the tester selection is also visible on the UI.
  @override
  void onTesterSelected(int index) {
    selectedTester = index;
    shouldAnimate = false;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () async {
      addMessage(
        "${strings.t('customer_choice')}${topIds[index]}",
        TimelineMessageStatus.completed,
      );

      if (plcService.isConnected) {
        try {
          await plcService.sendSelectedTester(index + 1);
          debugPrint('[ResultVM] Tester selection sent to PLC.');
        } on PLCException catch (e) {
          // Non-fatal: log and continue so the flow is not blocked.
          debugPrint('[ResultVM] Non-fatal PLC error on tester send: ${e.message}');
        }
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        addMessage(strings.t('payment_waiting'), TimelineMessageStatus.active);
        transitionToState(ResultFlowState.waitingPayment);
        startTimer(300);
        _watchPaymentStatus();
      });
    });
  }

  /// Handles payment confirmation and waits for the perfume dispenser.
  @override
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
      _watchPerfumeReady();
    });
  }

  /// Restarts payment watching after a failed payment attempt.
  @override
  void retryPayment() {
    updateLastMessage(
      strings.t('payment_waiting'),
      TimelineMessageStatus.active,
    );
    transitionToState(ResultFlowState.waitingPayment);
    startTimer(300);
    _watchPaymentStatus();
  }

  // ---------------------------------------------------------------------------
  // PLC-specific private methods
  // ---------------------------------------------------------------------------

  /// Sends the top recommendation IDs to the PLC.
  ///
  /// Falls back to the mock flow if the PLC disconnects before the write
  /// completes.
  Future<void> _sendToPLC() async {
    if (!plcService.isConnected) {
      debugPrint('[ResultVM] PLC disconnected before send — falling back to mock.');
      Future.delayed(const Duration(seconds: 1), _onTestersPreparing);
      return;
    }

    try {
      await plcService.sendRecommendations(topIds);
      debugPrint('[ResultVM] Recommendations sent to PLC.');
      Future.delayed(const Duration(seconds: 1), _onTestersPreparing);
    } on PLCException catch (e) {
      _handlePLCError(e);
    }
  }

  /// Transitions to the tester-preparing step and starts watching for the
  /// ready signal.
  void _onTestersPreparing() {
    addMessage(strings.t('testers_preparing'), TimelineMessageStatus.active);
    transitionToState(ResultFlowState.preparingTesters);
    _watchTestersReady();
  }

  /// Listens for the PLC tester-ready signal, or uses a mock delay when
  /// disconnected.
  void _watchTestersReady() {
    if (!plcService.isConnected) {
      debugPrint('[ResultVM] Mock: testers ready in 5 s.');
      Future.delayed(const Duration(seconds: 5), _onTestersReady);
      return;
    }

    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchTestersReady().listen(
      (ready) { if (ready) _onTestersReady(); },
      onError: (Object error) {
        if (error is PLCException) _handlePLCError(error);
      },
    );
  }

  /// Called when the PLC confirms all testers are physically ready.
  void _onTestersReady() {
    _plcSubscription?.cancel();
    updateLastMessage(
      strings.t('testers_prepared'),
      TimelineMessageStatus.completed,
    );
    transitionToState(ResultFlowState.testersReady);
    startTimer(300);
  }

  /// Listens for the PLC payment-status register, or waits for manual test
  /// input when disconnected.
  void _watchPaymentStatus() {
    if (!plcService.isConnected) {
      debugPrint('[ResultVM] Mock: awaiting manual payment button.');
      return;
    }

    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchPaymentStatus().listen(
      (status) {
        if (status == 1) onPaymentComplete();
        if (status == 2) onPaymentError();
      },
      onError: (Object error) {
        if (error is PLCException) _handlePLCError(error);
      },
    );
  }

  /// Listens for the PLC perfume-ready signal, or uses a mock delay when
  /// disconnected.
  void _watchPerfumeReady() {
    if (!plcService.isConnected) {
      debugPrint('[ResultVM] Mock: perfume ready in 8 s.');
      Future.delayed(const Duration(seconds: 8), _onPerfumeReady);
      return;
    }

    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchPerfumeReady().listen(
      (ready) { if (ready) _onPerfumeReady(); },
      onError: (Object error) {
        if (error is PLCException) _handlePLCError(error);
      },
    );
  }

  /// Called when the PLC confirms the perfume dispenser has finished.
  void _onPerfumeReady() {
    _plcSubscription?.cancel();
    updateLastMessage(
      strings.t('fragrance_prepared'),
      TimelineMessageStatus.completed,
    );
    transitionToState(ResultFlowState.perfumeReady);
    Future.delayed(const Duration(seconds: 2), () {
      transitionToState(ResultFlowState.giftCardQuestion);
    });
  }

  /// Handles a [PLCException] from any watcher or send operation.
  ///
  /// Connection-level faults (lost / failed) are escalated to the app-level
  /// idle reset so the kiosk recovers gracefully. All other faults append a
  /// warning message to the timeline and allow the flow to continue with mock
  /// behaviour.
  void _handlePLCError(PLCException error) {
    debugPrint('[ResultVM] PLC error ${error.errorCode}: ${error.message}');

    if (error.errorCode == PLCErrorCodes.connectionLost ||
        error.errorCode == PLCErrorCodes.connectionFailed) {
      debugPrint('[ResultVM] Critical fault — resetting to idle.');
      appViewModel.resetToIdle();
      return;
    }

    // Non-critical: show a warning in the timeline and continue.
    addMessage('⚠ ${error.message}', TimelineMessageStatus.error);
    debugPrint('[ResultVM] Non-critical fault — continuing with mock flow.');
  }

  @override
  void dispose() {
    _plcSubscription?.cancel();
    super.dispose();
  }
}