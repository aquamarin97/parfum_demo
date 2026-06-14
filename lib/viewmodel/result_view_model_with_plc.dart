import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:parfume_app/core/catalogue/perfume_catalogue.dart';
import 'package:parfume_app/domain/plc/plc_exceptions.dart';
import 'package:parfume_app/infrastructure/plc/plc_service_manager.dart';
import 'package:parfume_app/viewmodel/result_view_model.dart';

import 'result_flow_state.dart';
import '../ui/screens/result/models/timeline_message.dart';

/// PLC entegrasyonlu [ResultViewModel].
///
/// Register haritası v1.1 komut protokolünü kullanır:
///   1. sendTesterCommands(topIds) — tester_bas x3, ACK bekle
///   2. watchSystemIdle()          — STATUS_SYSTEM=0 bekle → testerlar hazır
///   3. startPayment(slot)         — ödeme_başlat, ACK bekle
///   4. watchPaymentStatus()       — PAYMENT_STATUS izle
///   5. confirmPayment()           — PAYMENT_CONFIRMED_ACK=1 yaz
///   6. sendSale(slot)             — satış_bas, ACK bekle
///   7. watchSaleCompleted()       — SALE_COMPLETED=1 bekle
class ResultViewModelWithPLC extends ResultViewModel {
  ResultViewModelWithPLC({
    required super.appViewModel,
    required this.plcService,
  }) {
    _initializePLCFlow();
  }

  final PLCServiceManager plcService;

  static const Duration _testerReadyTimeout = Duration(seconds: 90);
  static const Duration _saleCompletedTimeout = Duration(seconds: 180);

  StreamSubscription? _plcSubscription;
  Timer? _flowTimer;
  Timer? _testerReadyTimeoutTimer;
  Timer? _saleCompletedTimeoutTimer;

  int? _selectedSlot;
  int _paymentAmountTL = 0;
  bool _disposed = false;
  bool _saleCommandStarted = false;
  bool _flowCompleted = false;

  bool get _isActive => !_disposed;

  // -------------------------------------------------------------------------
  // Başlatma
  // -------------------------------------------------------------------------

  void _initializePLCFlow() {
    if (!_isActive) return;
    addKeyedMessage(
      'fragrance_recommendations_selected',
      TimelineMessageStatus.completed,
    );

    final names = topIds.map((id) => '${PerfumeCatalogue.nameOf(id)} (slot $id)').join(', ');
    debugPrint('[ResultVM] Önerilen testerlar: $names');

    Future.delayed(const Duration(seconds: 2), () {
      if (_isActive) _sendTesterCommandsToPLC();
    });
  }

  // -------------------------------------------------------------------------
  // Adım 1: Tester komutlarını gönder
  // -------------------------------------------------------------------------

  Future<void> _sendTesterCommandsToPLC() async {
    if (!_isActive || topIds.isEmpty) return;
    try {
      await plcService.sendTesterCommands(topIds);
      if (!_isActive) return;
      debugPrint('[ResultVM] Tester komutları ACK ✓');
      _onTestersPreparing();
    } on PLCException catch (e) {
      plcService.reportFault(e);
    }
  }

  void _onTestersPreparing() {
    if (!_isActive) return;
    addKeyedMessage('testers_preparing', TimelineMessageStatus.active);
    transitionToState(ResultFlowState.preparingTesters);
    _watchSystemIdle();
  }

  // -------------------------------------------------------------------------
  // Adım 2: Testerlar fiziksel olarak hazır olana kadar bekle
  // -------------------------------------------------------------------------

  void _watchSystemIdle() {
    if (!_isActive) return;
    _plcSubscription?.cancel();
    _startTesterReadyTimeout();
    _plcSubscription = plcService.watchSystemIdle().listen(
      (idle) {
        if (_isActive && idle) _onTestersReady();
      },
      onError: (Object e) {
        if (_isActive && e is PLCException) plcService.reportFault(e);
      },
    );
  }

  void _onTestersReady() {
    if (!_isActive) return;
    _testerReadyTimeoutTimer?.cancel();
    _plcSubscription?.cancel();
    updateLastKeyedMessage('testers_prepared', TimelineMessageStatus.completed);
    transitionToState(ResultFlowState.testersReady);
    startTimer(300);
  }

  // -------------------------------------------------------------------------
  // Adım 3: Tester seçimi → ödeme başlat
  // -------------------------------------------------------------------------

  @override
  void onTesterSelected(int index) {
    if (!_isActive || index < 0 || index >= topIds.length) return;
    selectedTester = index;
    shouldAnimate = false;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!_isActive || index < 0 || index >= topIds.length) return;
      final slotId = topIds[index];
      addKeyedMessage(
        'customer_choice',
        TimelineMessageStatus.completed,
        arg: '$slotId',
      );

      debugPrint('[ResultVM] Seçilen tester → ${PerfumeCatalogue.nameOf(slotId)} (slot $slotId)');
      _selectedSlot = slotId;
      _paymentAmountTL = appViewModel.priceForSlot(slotId);

      try {
        await plcService.startPayment(slotId, amountMinorUnits: _paymentAmountTL);
        if (!_isActive) return;
        debugPrint('[ResultVM] Ödeme başlatma ACK ✓');
      } on PLCException catch (e) {
        if (e.errorCode == PLCErrorCodes.connectionLost ||
            e.errorCode == PLCErrorCodes.connectionFailed ||
            e.errorCode == PLCErrorCodes.connectionTimeout) {
          _handlePLCError(e);
        } else {
          onPaymentError();
        }
        return;
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_isActive) return;
        addKeyedMessage('payment_waiting', TimelineMessageStatus.active);
        transitionToState(ResultFlowState.waitingPayment);
        startTimer(300);
        _watchPaymentStatus();
      });
    });
  }

  // -------------------------------------------------------------------------
  // Adım 4: Ödeme durumunu izle
  // -------------------------------------------------------------------------

  void _watchPaymentStatus() {
    if (!_isActive) return;
    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchPaymentStatus().listen(
      (status) {
        if (!_isActive) return;
        switch (status) {
          case 1:
            onPaymentComplete();
          case 2:
          case 3:
            onPaymentError();
        }
      },
      onError: (Object e) {
        if (!_isActive || e is! PLCException) return;
        if (e.errorCode == PLCErrorCodes.connectionLost ||
            e.errorCode == PLCErrorCodes.connectionFailed ||
            e.errorCode == PLCErrorCodes.connectionTimeout) {
          _handlePLCError(e);
        } else {
          onPaymentError();
        }
      },
    );
  }

  // -------------------------------------------------------------------------
  // Adım 5: Ödeme onayı → satış komutu
  // -------------------------------------------------------------------------

  @override
  void onPaymentComplete() {
    if (!_isActive) return;
    cancelTimer();
    _plcSubscription?.cancel();
    updateLastKeyedMessage('payment_completed', TimelineMessageStatus.completed);
    addKeyedMessage('fragrance_preparing', TimelineMessageStatus.active);
    transitionToState(ResultFlowState.preparingPerfume);

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!_isActive) return;
      try {
        await plcService.confirmPayment();
        if (!_isActive) return;
        debugPrint('[ResultVM] Ödeme onayı yazıldı.');
        final saleSlot = _selectedSlot;
        if (saleSlot == null) {
          _handlePLCError(PLCException(
            errorCode: PLCErrorCodes.unknownError,
            message: 'Satış için seçili slot bulunamadı',
          ));
          return;
        }
        debugPrint('[ResultVM] Satış → ${PerfumeCatalogue.nameOf(saleSlot)} (slot $saleSlot)');
        _saleCommandStarted = true;
        await plcService.sendSale(saleSlot);
        if (!_isActive) return;
        debugPrint('[ResultVM] Satış komutu ACK ✓');
      } on PLCException catch (e) {
        if (e.errorCode == PLCErrorCodes.connectionLost ||
            e.errorCode == PLCErrorCodes.connectionFailed ||
            e.errorCode == PLCErrorCodes.connectionTimeout) {
          _handlePLCError(e);
          return;
        }
        // ACK timeout veya geçici hata: PLC komutu almış olabilir, izlemeye devam et.
        debugPrint('[ResultVM] Satış ACK alınamadı, izlemeye devam: ${e.message}');
        if (!_isActive) return;
        addMessage('⚠ ${e.message}', TimelineMessageStatus.error);
      }

      if (!_isActive) return;
      _watchSaleCompleted();
    });
  }

  // -------------------------------------------------------------------------
  // Adım 6: Satış tamamlanmasını izle
  // -------------------------------------------------------------------------

  void _watchSaleCompleted() {
    if (!_isActive) return;
    _plcSubscription?.cancel();
    _startSaleCompletedTimeout();
    _plcSubscription = plcService.watchSaleCompleted().listen(
      (completed) {
        if (_isActive && completed) _onPerfumeReady();
      },
      onError: (Object e) {
        if (_isActive && e is PLCException) plcService.reportFault(e);
      },
    );
  }

  void _onPerfumeReady() {
    if (!_isActive) return;
    _saleCompletedTimeoutTimer?.cancel();
    _plcSubscription?.cancel();
    appViewModel.clearSession();
    _flowCompleted = true;
    updateKeyedMessageBy(
      'fragrance_preparing',
      'fragrance_prepared',
      TimelineMessageStatus.completed,
    );
    transitionToState(ResultFlowState.perfumeReady);
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isActive) return;
      transitionToState(ResultFlowState.giftCardQuestion);
    });
  }

  // -------------------------------------------------------------------------
  // Override: geri gitme / tekrar dene / iptal
  // -------------------------------------------------------------------------

  @override
  void backToTesterSelection() {
    _plcSubscription?.cancel();
    _cancelOperationTimeouts();
    _abortSessionIfSafe();
    super.backToTesterSelection();
  }

  @override
  void retryPayment() {
    if (!_isActive) return;
    _plcSubscription?.cancel();
    updateLastKeyedMessage('payment_waiting', TimelineMessageStatus.active);
    transitionToState(ResultFlowState.waitingPayment);
    startTimer(300);

    final slot = _selectedSlot;
    if (slot == null) {
      onPaymentError();
      return;
    }

    plcService.startPayment(slot, amountMinorUnits: _paymentAmountTL)
        .then((_) {
      if (_isActive) _watchPaymentStatus();
    })
        .catchError((Object e) {
      if (_isActive && e is PLCException) _handlePLCError(e);
    });
  }

  @override
  void cancelToIdle() {
    _plcSubscription?.cancel();
    cancelTimer();
    _cancelOperationTimeouts();
    _abortSessionIfSafe();
    super.cancelToIdle();
  }

  @override
  void startTimer(int seconds) {
    _flowTimer?.cancel();
    timerNotifier.value = seconds;
    _flowTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isActive) {
        timer.cancel();
        return;
      }

      timerNotifier.value--;
      if (timerNotifier.value > 0) return;

      timer.cancel();
      _plcSubscription?.cancel();
      _cancelOperationTimeouts();
      _abortSessionIfSafe();
      appViewModel.resetToIdle();
    });
  }

  @override
  void cancelTimer() {
    _flowTimer?.cancel();
    _flowTimer = null;
  }

  // -------------------------------------------------------------------------
  // Hata yönetimi
  // -------------------------------------------------------------------------

  void _handlePLCError(PLCException error) {
    if (!_isActive) return;
    debugPrint('[ResultVM] PLC hatası ${error.errorCode}: ${error.message}');

    if (error.errorCode == PLCErrorCodes.connectionLost ||
        error.errorCode == PLCErrorCodes.connectionFailed ||
        error.errorCode == PLCErrorCodes.connectionTimeout) {
      return;
    }

    addMessage('⚠ ${error.message}', TimelineMessageStatus.error);
  }

  void _startTesterReadyTimeout() {
    _testerReadyTimeoutTimer?.cancel();
    _testerReadyTimeoutTimer = Timer(_testerReadyTimeout, () {
      if (!_isActive) return;
      _plcSubscription?.cancel();
      _abortSessionIfSafe();
      plcService.reportFault(PLCException(
        errorCode: PLCErrorCodes.responseTimeout,
        message: 'Tester hazırlama zaman aşımı',
        technicalDetail:
            'STATUS_SYSTEM=0 ${_testerReadyTimeout.inSeconds}s içinde gelmedi.',
      ));
    });
  }

  void _startSaleCompletedTimeout() {
    _saleCompletedTimeoutTimer?.cancel();
    _saleCompletedTimeoutTimer = Timer(_saleCompletedTimeout, () {
      if (!_isActive) return;
      _plcSubscription?.cancel();
      plcService.reportFault(PLCException(
        errorCode: PLCErrorCodes.systemFault,
        message: 'Satış tamamlanma zaman aşımı',
        technicalDetail:
            'SALE_COMPLETED=1 ${_saleCompletedTimeout.inSeconds}s içinde gelmedi. '
            'slot=$_selectedSlot amount=$_paymentAmountTL',
      ));
    });
  }

  void _cancelOperationTimeouts() {
    _testerReadyTimeoutTimer?.cancel();
    _testerReadyTimeoutTimer = null;
    _saleCompletedTimeoutTimer?.cancel();
    _saleCompletedTimeoutTimer = null;
  }

  bool get _canAbortPLCSession {
    if (_flowCompleted || _saleCommandStarted) return false;
    return switch (currentState) {
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
  }

  void _abortSessionIfSafe() {
    if (!_canAbortPLCSession) return;
    plcService.abortSession();
  }

  @override
  void dispose() {
    if (_canAbortPLCSession) {
      plcService.abortSession();
    }
    _disposed = true;
    cancelTimer();
    _cancelOperationTimeouts();
    _plcSubscription?.cancel();
    super.dispose();
  }
}
