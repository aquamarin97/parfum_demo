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
/// Register haritası v1.0 komut protokolünü kullanır:
///   1. sendTesterCommands(topIds) — tester_bas x3, ACK bekle
///   2. watchSystemIdle()          — STATUS_SYSTEM=0 bekle → testerlar hazır
///   3. startPayment(slot)         — ödeme_başlat, ACK bekle
///   4. watchPaymentStatus()       — PAYMENT_STATUS izle
///   5. confirmPayment()           — PAYMENT_CONFIRMED_ACK=1 yaz
///   6. sendSale(slot)             — satış_bas, ACK bekle
///   7. watchSaleCompleted()       — SALE_COMPLETED=1 bekle
///
/// PLC bağlı değilse mock zamanlayıcılarla akış devam eder.
class ResultViewModelWithPLC extends ResultViewModel {
  ResultViewModelWithPLC({
    required super.appViewModel,
    required this.plcService,
  }) {
    _initializePLCFlow();
  }

  final PLCServiceManager plcService;

  StreamSubscription? _plcSubscription;

  // -------------------------------------------------------------------------
  // Başlatma
  // -------------------------------------------------------------------------

  void _initializePLCFlow() {
    addKeyedMessage(
      'fragrance_recommendations_selected',
      TimelineMessageStatus.completed,
      arg: plcService.isConnected ? null : ' (Mock)',
    );

    final names = topIds.map((id) => '${PerfumeCatalogue.nameOf(id)} (slot $id)').join(', ');
    debugPrint('[ResultVM] Önerilen testerlar: $names');

    if (!plcService.isConnected) {
      debugPrint('[ResultVM] PLC bağlı değil — mock akışı.');
      Future.delayed(const Duration(seconds: 2), _onTestersPreparing);
      return;
    }

    Future.delayed(const Duration(seconds: 2), _sendTesterCommandsToPLC);
  }

  // -------------------------------------------------------------------------
  // Adım 1: Tester komutlarını gönder
  // -------------------------------------------------------------------------

  Future<void> _sendTesterCommandsToPLC() async {
    if (!plcService.isConnected) {
      _onTestersPreparing();
      return;
    }
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
    if (!plcService.isConnected) {
      debugPrint('[ResultVM] Mock: testerlar 5 sn sonra hazır.');
      Future.delayed(const Duration(seconds: 5), _onTestersReady);
      return;
    }

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
      addKeyedMessage(
        'customer_choice',
        TimelineMessageStatus.completed,
        arg: '${topIds[index]}',
      );

      if (plcService.isConnected) {
        try {
          final slotId = topIds[index];
          debugPrint('[ResultVM] Seçilen tester → ${PerfumeCatalogue.nameOf(slotId)} (slot $slotId)');
          // Slot bazlı fiyat; tanımlı değilse global fiyat kullanılır.
          final amountMinorUnits = appViewModel.priceForSlot(slotId) * 100;
          await plcService.startPayment(
            slotId,
            amountMinorUnits: amountMinorUnits,
          );
          debugPrint('[ResultVM] Ödeme başlatma ACK ✓');
        } on PLCException catch (e) {
          _handlePLCError(e);
          return;
        }
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
    if (!plcService.isConnected) {
      debugPrint('[ResultVM] Mock: manuel ödeme butonu bekleniyor.');
      return;
    }

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
    // Ödeme onaylandı — butonları hemen kaldır, satış hazırlama ekranına geç.
    addKeyedMessage('fragrance_preparing', TimelineMessageStatus.active);
    transitionToState(ResultFlowState.preparingPerfume);

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (plcService.isConnected) {
        try {
          await plcService.confirmPayment();
          debugPrint('[ResultVM] Ödeme onayı yazıldı.');
          final saleSlot = topIds[selectedTester!];
          debugPrint('[ResultVM] Satış → ${PerfumeCatalogue.nameOf(saleSlot)} (slot $saleSlot)');
          await plcService.sendSale(saleSlot);
          debugPrint('[ResultVM] Satış komutu ACK ✓');
        } on PLCException catch (e) {
          // Bağlantı kopmuşsa akışı durdur — AppViewModel zaten hata ekranına geçer.
          if (e.errorCode == PLCErrorCodes.connectionLost ||
              e.errorCode == PLCErrorCodes.connectionFailed) {
            _handlePLCError(e);
            return;
          }
          // ACK timeout veya diğer geçici hatalar: PLC komutu almış olabilir.
          // Uyarı göster ama SALE_COMPLETED izlemeye devam et.
          debugPrint('[ResultVM] Satış ACK alınamadı, izlemeye devam ediliyor: ${e.message}');
          addMessage('⚠ ${e.message}', TimelineMessageStatus.error);
        }
      }

      _watchSaleCompleted();
    });
  }

  // -------------------------------------------------------------------------
  // Adım 6: Satış tamamlanmasını izle
  // -------------------------------------------------------------------------

  void _watchSaleCompleted() {
    if (!plcService.isConnected) {
      debugPrint('[ResultVM] Mock: parfüm 8 sn sonra hazır.');
      Future.delayed(const Duration(seconds: 8), _onPerfumeReady);
      return;
    }

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
    // Satış başarıyla tamamlandı — oturumu temizle, kurtarma gerekmez.
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
  // Override: geri gitme → subscription iptal et
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
    _watchPaymentStatus();
  }

  // -------------------------------------------------------------------------
  // Hata yönetimi
  // -------------------------------------------------------------------------

  void _handlePLCError(PLCException error) {
    debugPrint('[ResultVM] PLC hatası ${error.errorCode}: ${error.message}');

    if (error.errorCode == PLCErrorCodes.connectionLost ||
        error.errorCode == PLCErrorCodes.connectionFailed) {
      // PLCServiceManager bağlantı hatasını zaten AppViewModel dinleyicisine
      // iletir → _onPLCStateChanged() → PLCErrorState geçişi.
      // resetToIdle() çağrılmaz — kullanıcı doğrudan hizmet dışı ekranına gider.
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
