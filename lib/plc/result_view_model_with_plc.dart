// result_view_model_with_plc.dart - IMPROVED ERROR HANDLING
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:parfume_app/plc/error/plc_error_codes.dart';
import 'package:parfume_app/plc/plc_service_manager.dart';
import 'package:parfume_app/ui/screens/result/result_view_model_refactored.dart';

import '../viewmodel/app_view_model.dart';

import '../ui/screens/result/models/result_flow_state.dart';
import '../ui/screens/result/models/timeline_message.dart';

/// PLC-entegre ResultViewModel
class ResultViewModelWithPLC extends ResultViewModel {
  ResultViewModelWithPLC({
    required AppViewModel appViewModel,
    required this.plcService,
  }) : super(appViewModel: appViewModel) {
    _initializePLCFlow();
  }

  final PLCServiceManager plcService;
  StreamSubscription? _plcSubscription;

  /// PLC flow'unu başlat
  void _initializePLCFlow() {
    // ✅ PLC bağlantısını kontrol et
    if (!plcService.isConnected) {
      debugPrint('[ResultVM] ⚠ PLC bağlı değil, mock flow kullanılıyor');
      
      // Mock flow (PLC olmadan test için)
      addMessage(
        '${strings.fragranceRecommendationsSelected} (Mock Mode)',
        TimelineMessageStatus.completed,
      );

      Future.delayed(const Duration(seconds: 2), () {
        _onTestersPreparing();
      });
      return;
    }

    // Normal PLC flow
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

      // ✅ PLC'ye seçimi gönder (sadece bağlıysa)
      if (plcService.isConnected) {
        try {
          await plcService.sendSelectedTester(index + 1);
          debugPrint('[ResultVM] ✓ Tester seçimi PLC\'ye gönderildi');
        } on PLCException catch (e) {
          debugPrint('[ResultVM] ⚠ PLC hatası: ${e.message}');
          // Hata olsa bile flow devam etsin (fallback)
        }
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        addMessage(strings.paymentWaiting, TimelineMessageStatus.active);
        transitionToState(ResultFlowState.waitingPayment);
        startTimer(300);
        _watchPaymentStatus();
      });
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
    if (!plcService.isConnected) {
      debugPrint('[ResultVM] PLC bağlı değil, mock flow devam ediyor');
      Future.delayed(const Duration(seconds: 1), _onTestersPreparing);
      return;
    }

    try {
      await plcService.sendRecommendations(topIds);
      debugPrint('[ResultVM] ✓ Öneriler PLC\'ye gönderildi');
      
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

    // PLC'den tester hazır sinyali bekle (veya mock)
    _watchTestersReady();
  }

  void _watchTestersReady() {
    if (!plcService.isConnected) {
      // Mock: 5 saniye sonra hazır
      debugPrint('[ResultVM] Mock: Testerlar 5 saniye sonra hazır olacak');
      Future.delayed(const Duration(seconds: 5), _onTestersReady);
      return;
    }

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
    if (!plcService.isConnected) {
      // Mock: Manuel test butonları ile kontrol
      debugPrint('[ResultVM] Mock: Manuel ödeme kontrolü (TEST butonları)');
      return;
    }

    _plcSubscription?.cancel();
    _plcSubscription = plcService.watchPaymentStatus().listen(
      (status) {
        if (status == 1) {
          onPaymentComplete();
        } else if (status == 2) {
          onPaymentError();
        }
      },
      onError: (error) {
        if (error is PLCException) {
          _handlePLCError(error);
        }
      },
    );
  }

  void _watchPerfumeReady() {
    if (!plcService.isConnected) {
      // Mock: 8 saniye sonra hazır
      debugPrint('[ResultVM] Mock: Parfüm 8 saniye sonra hazır olacak');
      Future.delayed(const Duration(seconds: 8), _onPerfumeReady);
      return;
    }

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
    
    // ✅ Critical error'larda app-level error state'e geç
    if (error.errorCode == PLCErrorCodes.connectionLost ||
        error.errorCode == PLCErrorCodes.connectionFailed) {
      
      debugPrint('[ResultVM] Critical PLC hatası, ana hata ekranına yönlendiriliyor');
      appViewModel.resetToIdle(); // veya PLCErrorState'e geç
      return;
    }

    // ✅ Minor error'larda timeline'a ekle ama devam et
    addMessage(
      '⚠ ${error.getUserMessage(appViewModel.language.code)}',
      TimelineMessageStatus.error,
    );

    // Mock flow'a geç
    debugPrint('[ResultVM] PLC hatası, mock flow\'a geçiliyor');
  }

  @override
  void dispose() {
    _plcSubscription?.cancel();
    super.dispose();
  }
}