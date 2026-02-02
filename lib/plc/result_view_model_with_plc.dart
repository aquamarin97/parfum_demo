// result_view_model_with_plc.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:parfume_app/plc/error/plc_error_codes.dart';
import 'package:parfume_app/plc/plc_service_manager.dart';
import 'package:parfume_app/ui/screens/result/result_view_model_refactored.dart';

import '../viewmodel/app_view_model.dart';

import '../ui/screens/result/models/result_flow_state.dart';
import '../ui/screens/result/models/timeline_message.dart';

/// PLC-entegre ResultViewModel
/// ResultViewModel'i extend eder, böylece tüm view'lar ile uyumludur
class ResultViewModelWithPLC extends ResultViewModel {
  ResultViewModelWithPLC({
    required AppViewModel appViewModel,
    required this.plcService,
  }) : super(appViewModel: appViewModel) {
    // Parent constructor çağrıldıktan sonra PLC flow'u başlat
    _initializePLCFlow();
  }

  final PLCServiceManager plcService;
  StreamSubscription? _plcSubscription;

  /// PLC flow'unu başlat (parent'ın _startFlow yerine)
  void _initializePLCFlow() {
    // PLC bağlantısını kontrol et
    if (!plcService.isConnected) {
      _handlePLCError(
        PLCException(
          errorCode: PLCErrorCodes.connectionLost,
          message: 'PLC bağlantısı yok',
        ),
      );
      return;
    }

    addMessage(
      strings.fragranceRecommendationsSelected,
      TimelineMessageStatus.completed,
    );

    Future.delayed(const Duration(seconds: 2), () {
      _sendToPLC();
    });
  }

  @override
  void onTesterSelected(int index) {
    selectedTester = index;
    shouldAnimate = false;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () async {
      addMessage(
        "${strings.customerChoice}${topIds[index]}",
        TimelineMessageStatus.completed,
      );

      // ✅ PLC'ye seçimi gönder
      try {
        await plcService.sendSelectedTester(index + 1); // 1-based index
        
        Future.delayed(const Duration(milliseconds: 300), () {
          addMessage(strings.paymentWaiting, TimelineMessageStatus.active);
          transitionToState(ResultFlowState.waitingPayment);
          startTimer(300);
          _watchPaymentStatus();
        });
      } on PLCException catch (e) {
        _handlePLCError(e);
      }
    });
  }

  @override
  void onPaymentComplete() {
    cancelTimer();
    updateLastMessage(strings.paymentCompleted, TimelineMessageStatus.completed);

    Future.delayed(const Duration(milliseconds: 500), () {
      addMessage(strings.fragrancePreparing, TimelineMessageStatus.active);
      transitionToState(ResultFlowState.preparingPerfume);
      _watchPerfumeReady();
    });
  }

  @override
  void retryPayment() {
    updateLastMessage(strings.paymentWaiting, TimelineMessageStatus.active);
    transitionToState(ResultFlowState.waitingPayment);
    startTimer(300);
    _watchPaymentStatus();
  }

  // ===== PLC-Specific Methods =====

  void _sendToPLC() async {
    try {
      // Önerileri PLC'ye gönder
      await plcService.sendRecommendations(topIds);
      
      Future.delayed(const Duration(seconds: 1), () {
        _onTestersPreparing();
      });
    } on PLCException catch (e) {
      _handlePLCError(e);
    }
  }

  void _onTestersPreparing() {
    addMessage(strings.testersPreparing, TimelineMessageStatus.active);
    transitionToState(ResultFlowState.preparingTesters);

    // PLC'den tester hazır sinyali bekle
    _watchTestersReady();
  }

  void _watchTestersReady() {
    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchTestersReady().listen(
      (ready) {
        if (ready) {
          _onTestersReady();
        }
      },
      onError: (error) {
        if (error is PLCException) {
          _handlePLCError(error);
        }
      },
    );
  }

  void _onTestersReady() {
    _plcSubscription?.cancel();
    updateLastMessage(strings.testersPrepared, TimelineMessageStatus.completed);
    transitionToState(ResultFlowState.testersReady);
    startTimer(300);
  }

  void _watchPaymentStatus() {
    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchPaymentStatus().listen(
      (status) {
        if (status == 1) {
          // Ödeme başarılı
          onPaymentComplete();
        } else if (status == 2) {
          // Ödeme hatası
          onPaymentError();
        }
        // status == 0: Bekliyor, hiçbir şey yapma
      },
      onError: (error) {
        if (error is PLCException) {
          _handlePLCError(error);
        }
      },
    );
  }

  void _watchPerfumeReady() {
    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchPerfumeReady().listen(
      (ready) {
        if (ready) {
          _onPerfumeReady();
        }
      },
      onError: (error) {
        if (error is PLCException) {
          _handlePLCError(error);
        }
      },
    );
  }

  void _onPerfumeReady() {
    _plcSubscription?.cancel();
    updateLastMessage(strings.fragrancePrepared, TimelineMessageStatus.completed);
    transitionToState(ResultFlowState.perfumeReady);

    Future.delayed(const Duration(seconds: 2), () {
      transitionToState(ResultFlowState.giftCardQuestion);
    });
  }

  void _handlePLCError(PLCException error) {
    debugPrint('[ResultVM] PLC Hatası: ${error.errorCode} - ${error.message}');
    
    // Timeline'a hata mesajı ekle
    addMessage(
      error.getUserMessage(appViewModel.language.code),
      TimelineMessageStatus.error,
    );

    // Error durumunda ne yapılacak?
    // Seçenek 1: Retry modu
    // Seçenek 2: Error state
    // Seçenek 3: Idle'a dön
    
    // Şimdilik error mesajı gösterip devam ediyoruz
    debugPrint('[ResultVM] PLC hatası yakalandı ama flow devam ediyor');
  }

  @override
  void dispose() {
    _plcSubscription?.cancel();
    super.dispose();
  }
}