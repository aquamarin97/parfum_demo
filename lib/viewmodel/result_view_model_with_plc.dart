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

  StreamSubscription? _plcSubscription;

  int? _selectedSlot;
  int _paymentAmountTL = 0;

  // -------------------------------------------------------------------------
  // Başlatma
  // -------------------------------------------------------------------------

  void _initializePLCFlow() {
    addKeyedMessage(
      'fragrance_recommendations_selected',
      TimelineMessageStatus.completed,
    );

    final names = topIds.map((id) => '${PerfumeCatalogue.nameOf(id)} (slot $id)').join(', ');
    debugPrint('[ResultVM] Önerilen testerlar: $names');

    Future.delayed(const Duration(seconds: 2), _sendTesterCommandsToPLC);
  }

  // -------------------------------------------------------------------------
  // Adım 1: Tester komutlarını gönder
  // -------------------------------------------------------------------------

  Future<void> _sendTesterCommandsToPLC() async {
    try {
      await plcService.sendTesterCommands(topIds);
      debugPrint('[ResultVM] Tester komutları ACK ✓');
      _onTestersPreparing();
    } on PLCException catch (e) {
      _handlePLCError(e);
    }
  }

  void _onTestersPreparing() {
    addKeyedMessage('testers_preparing', TimelineMessageStatus.active);
    transitionToState(ResultFlowState.preparingTesters);
    _watchSystemIdle();
  }

  // -------------------------------------------------------------------------
  // Adım 2: Testerlar fiziksel olarak hazır olana kadar bekle
  // -------------------------------------------------------------------------

  void _watchSystemIdle() {
    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchSystemIdle().listen(
      (idle) {
        if (idle) _onTestersReady();
      },
      onError: (Object e) {
        if (e is PLCException) _handlePLCError(e);
      },
    );
  }

  void _onTestersReady() {
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
    selectedTester = index;
    shouldAnimate = false;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () async {
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
        debugPrint('[ResultVM] Ödeme başlatma ACK ✓');
      } on PLCException catch (e) {
        _handlePLCError(e);
        return;
      }

      Future.delayed(const Duration(milliseconds: 300), () {
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
    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchPaymentStatus().listen(
      (status) {
        switch (status) {
          case 1:
            onPaymentComplete();
          case 2:
          case 3:
            onPaymentError();
        }
      },
      onError: (Object e) {
        if (e is PLCException) _handlePLCError(e);
      },
    );
  }

  // -------------------------------------------------------------------------
  // Adım 5: Ödeme onayı → satış komutu
  // -------------------------------------------------------------------------

  @override
  void onPaymentComplete() {
    cancelTimer();
    _plcSubscription?.cancel();
    updateLastKeyedMessage('payment_completed', TimelineMessageStatus.completed);
    addKeyedMessage('fragrance_preparing', TimelineMessageStatus.active);
    transitionToState(ResultFlowState.preparingPerfume);

    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        await plcService.confirmPayment();
        debugPrint('[ResultVM] Ödeme onayı yazıldı.');
        final saleSlot = topIds[selectedTester!];
        debugPrint('[ResultVM] Satış → ${PerfumeCatalogue.nameOf(saleSlot)} (slot $saleSlot)');
        await plcService.sendSale(saleSlot);
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
        addMessage('⚠ ${e.message}', TimelineMessageStatus.error);
      }

      _watchSaleCompleted();
    });
  }

  // -------------------------------------------------------------------------
  // Adım 6: Satış tamamlanmasını izle
  // -------------------------------------------------------------------------

  void _watchSaleCompleted() {
    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchSaleCompleted().listen(
      (completed) {
        if (completed) _onPerfumeReady();
      },
      onError: (Object e) {
        if (e is PLCException) _handlePLCError(e);
      },
    );
  }

  void _onPerfumeReady() {
    _plcSubscription?.cancel();
    appViewModel.clearSession();
    updateKeyedMessageBy(
      'fragrance_preparing',
      'fragrance_prepared',
      TimelineMessageStatus.completed,
    );
    transitionToState(ResultFlowState.perfumeReady);
    Future.delayed(const Duration(seconds: 2), () {
      transitionToState(ResultFlowState.giftCardQuestion);
    });
  }

  // -------------------------------------------------------------------------
  // Override: geri gitme / tekrar dene / iptal
  // -------------------------------------------------------------------------

  @override
  void backToTesterSelection() {
    _plcSubscription?.cancel();
    plcService.abortSession();
    super.backToTesterSelection();
  }

  @override
  void retryPayment() {
    updateLastKeyedMessage('payment_waiting', TimelineMessageStatus.active);
    transitionToState(ResultFlowState.waitingPayment);
    startTimer(300);

    final slot = _selectedSlot;
    if (slot == null) return;

    plcService.startPayment(slot, amountMinorUnits: _paymentAmountTL)
        .then((_) => _watchPaymentStatus())
        .catchError((Object e) {
      if (e is PLCException) _handlePLCError(e);
    });
  }

  // -------------------------------------------------------------------------
  // Hata yönetimi
  // -------------------------------------------------------------------------

  void _handlePLCError(PLCException error) {
    debugPrint('[ResultVM] PLC hatası ${error.errorCode}: ${error.message}');

    if (error.errorCode == PLCErrorCodes.connectionLost ||
        error.errorCode == PLCErrorCodes.connectionFailed ||
        error.errorCode == PLCErrorCodes.connectionTimeout) {
      return;
    }

    addMessage('⚠ ${error.message}', TimelineMessageStatus.error);
  }

  @override
  void dispose() {
    _plcSubscription?.cancel();
    super.dispose();
  }
}
