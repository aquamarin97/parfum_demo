import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:parfume_app/domain/plc/i_plc_client.dart';
import 'package:parfume_app/domain/plc/plc_exceptions.dart';
import 'package:parfume_app/domain/plc/plc_timings.dart';

import '../../core/logging/app_logger.dart';

/// PLC bağlantı yaşam döngüsünü ve servis operasyonlarını yönetir.
///
/// Register haritası v1.0 komut protokolünü uygular:
///   - [sendTesterCommands] — 3 tester komutu gönderir + ACK bekler
///   - [watchSystemIdle]   — STATUS_SYSTEM=0 olana kadar izler
///   - [startPayment]      — ödeme_başlat komutu
///   - [confirmPayment]    — PAYMENT_CONFIRMED_ACK=1 yazar
///   - [sendSale]          — satış_bas komutu
///   - [watchPaymentStatus] / [watchSaleCompleted] — durum stream'leri
///   - [readRegister] / [writeRegister] — admin paneli için doğrudan erişim
class PLCServiceManager extends ChangeNotifier {
  PLCServiceManager({
    required IPlcClient client,
    AppLogger? logger,
    bool autoConnect = true,
    this.onError,
  })  : _client = client,
        _logger = logger ?? AppLogger() {
    if (autoConnect) initialize();
  }

  final IPlcClient _client;
  final AppLogger _logger;

  final void Function(PLCException)? onError;

  PLCConnectionState _state = PLCConnectionState.disconnected;
  PLCException? _lastError;
  DateTime? _lastConnectedTime;
  int _reconnectAttempts = 0;
  PLCTimings _timings = PLCTimings.defaults;

  static const int maxReconnectAttempts = 5;

  PLCConnectionState get state => _state;
  PLCException? get lastError => _lastError;
  bool get isConnected => _state == PLCConnectionState.connected;
  bool get isConnecting => _state == PLCConnectionState.connecting;
  bool get hasError => _state == PLCConnectionState.error;
  DateTime? get lastConnectedTime => _lastConnectedTime;
  PLCTimings get timings => _timings;

  /// Çalışma zamanında süre parametrelerini günceller.
  ///
  /// Değişiklikler bir sonraki komut/polling döngüsünde geçerli olur.
  void updateTimings(PLCTimings t) => _timings = t;

  // -------------------------------------------------------------------------
  // Bağlantı yaşam döngüsü
  // -------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_state == PLCConnectionState.connecting) {
      _logger.warning('initialize() çalışıyor, atlanıyor.');
      return;
    }
    _updateState(PLCConnectionState.connecting);
    _lastError = null;
    try {
      _logger.info('PLC bağlantısı başlatılıyor...');
      await _client.connect();
      _lastConnectedTime = DateTime.now();
      _reconnectAttempts = 0;
      _updateState(PLCConnectionState.connected);
      _logger.info('PLC bağlantısı kuruldu.');
    } on PLCException catch (e) {
      _logger.error('Bağlantı hatası ${e.errorCode}: ${e.message}');
      _handleError(e);
    } catch (e) {
      _logger.error('Beklenmeyen bağlantı hatası: $e');
      _handleError(PLCException(
        errorCode: PLCErrorCodes.unknownError,
        message: 'Beklenmeyen hata',
        technicalDetail: e.toString(),
      ));
    }
  }

  Future<void> disconnect() async {
    try {
      await _client.disconnect();
      _updateState(PLCConnectionState.disconnected);
      _logger.info('PLC bağlantısı kapatıldı.');
    } catch (e) {
      _logger.warning('Bağlantı kapatma hatası: $e');
    }
  }

  Future<void> reconnect() async {
    _reconnectAttempts++;
    if (_reconnectAttempts > maxReconnectAttempts) {
      _logger.error('Maksimum yeniden bağlanma denemesi aşıldı.');
      _handleError(PLCException(
        errorCode: PLCErrorCodes.connectionFailed,
        message: 'Maksimum bağlanma denemesi aşıldı',
        technicalDetail: 'Deneme: $_reconnectAttempts',
      ));
      return;
    }
    final delay = Duration(seconds: 1 << _reconnectAttempts);
    _logger.info('Yeniden bağlanma $_reconnectAttempts/$maxReconnectAttempts (${delay.inSeconds}s bekleniyor)...');
    await disconnect();
    await Future.delayed(delay);
    await initialize();
  }

  Future<bool> checkHealth() async {
    if (!isConnected) return false;
    try {
      return await _client.healthCheck();
    } catch (e) {
      _logger.warning('Health check hatası: $e');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Tester hazırlama — Blok 1/2
  // -------------------------------------------------------------------------

  /// Her slot için CMD_ACTION=1 (tester_bas) gönderir ve ACK bekler.
  ///
  /// Tüm ACK'lar alındıktan sonra döner; fiziksel hazırlık için
  /// [watchSystemIdle] kullanılmalıdır.
  Future<void> sendTesterCommands(List<int> slotIds) async {
    _ensureConnected();
    try {
      for (final slotId in slotIds) {
        _logger.debug('Tester komutu → slot=$slotId');
        final seqId = await _client.sendCommand(PLCCommandAction.testerPress, slotId);
        final ok = await _client.waitForCommandAck(
          seqId,
          timeout: Duration(seconds: _timings.commandAckTimeoutSec),
        );
        if (!ok) {
          throw PLCException(
            errorCode: PLCErrorCodes.commandRejected,
            message: 'Tester komutu reddedildi',
            technicalDetail: 'slot=$slotId seqId=$seqId',
          );
        }
        _logger.debug('Tester ACK ✓ slot=$slotId');
      }
    } on PLCException catch (e) {
      _logger.error('Tester komutları başarısız: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  /// STATUS_SYSTEM (R200) = 0 (boşta) olana kadar her 500 ms'de bir okur.
  ///
  /// Testerlar fiziksel olarak hazır olduğunda `true` emit eder.
  Stream<bool> watchSystemIdle() async* {
    _ensureConnected();
    try {
      // PLC'nin STATUS_SYSTEM'i 1'e çekmesi için kısa bekleme
      await Future.delayed(Duration(milliseconds: _timings.systemIdlePollMs));
      while (true) {
        final status = await _client.readSystemStatus();
        if (status == 2) {
          throw PLCException(
            errorCode: PLCErrorCodes.systemFault,
            message: 'PLC sistem hatası',
            technicalDetail: 'STATUS_SYSTEM=2',
          );
        }
        final idle = status == 0;
        yield idle;
        if (idle) break;
        await Future.delayed(Duration(milliseconds: _timings.systemIdlePollMs));
      }
    } on PLCException catch (e) {
      _logger.error('watchSystemIdle hatası: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // Ödeme — Blok 3
  // -------------------------------------------------------------------------

  /// PAYMENT_AMOUNT (R301) yazar, ardından CMD_ACTION=3 gönderir ve ACK bekler.
  ///
  /// [amountMinorUnits]: ödeme tutarı TL cinsinden tam sayı
  /// (örn. 690 TL → 690). 0 geçilirse yazma atlanır.
  Future<void> startPayment(int slot, {int amountMinorUnits = 0}) async {
    _ensureConnected();
    try {
      // Önceki ödeme sonucunu temizle: PAY_CONFIRMED_ACK = 0
      await _client.writeRegister(302, 0);
      if (amountMinorUnits > 0) {
        await _client.writePaymentAmount(amountMinorUnits);
        _logger.debug('PAYMENT_AMOUNT=$amountMinorUnits yazıldı');
      }
      _logger.debug('Ödeme başlatılıyor → slot=$slot');
      final seqId = await _client.sendCommand(PLCCommandAction.startPayment, slot);
      final ok = await _client.waitForCommandAck(
        seqId,
        timeout: Duration(seconds: _timings.commandAckTimeoutSec),
      );
      if (!ok) {
        throw PLCException(
          errorCode: PLCErrorCodes.commandRejected,
          message: 'Ödeme başlatma komutu reddedildi',
        );
      }
      _logger.debug('Ödeme başlatma ACK ✓');
    } on PLCException catch (e) {
      _logger.error('startPayment hatası: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  /// PAYMENT_CONFIRMED_ACK (R302) = 1 yazar; PLC sıfırlar.
  Future<void> confirmPayment() async {
    _ensureConnected();
    try {
      await _client.writePaymentConfirmedAck();
      _logger.debug('Ödeme onayı yazıldı (R302=1)');
    } on PLCException catch (e) {
      _logger.error('confirmPayment hatası: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  /// CMD_ACTION=2 (satış_bas) gönderir ve ACK bekler.
  Future<void> sendSale(int slot) async {
    _ensureConnected();
    try {
      _logger.debug('Satış komutu → slot=$slot');
      final seqId = await _client.sendCommand(PLCCommandAction.salePress, slot);
      final ok = await _client.waitForCommandAck(
        seqId,
        timeout: Duration(seconds: _timings.commandAckTimeoutSec),
      );
      if (!ok) {
        throw PLCException(
          errorCode: PLCErrorCodes.commandRejected,
          message: 'Satış komutu reddedildi',
          technicalDetail: 'slot=$slot',
        );
      }
      _logger.debug('Satış ACK ✓ slot=$slot');
    } on PLCException catch (e) {
      _logger.error('sendSale hatası: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  /// PAYMENT_STATUS (R300) stream'i — 0=bekliyor, 1=onay, 2=ret, 3=timeout.
  Stream<int> watchPaymentStatus() async* {
    _ensureConnected();
    try {
      yield* _client.watchPaymentStatus(
        pollInterval: Duration(milliseconds: _timings.paymentStatusPollMs),
      );
    } on PLCException catch (e) {
      _logger.error('watchPaymentStatus hatası: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  /// SALE_COMPLETED (R303) stream'i — `true` emit edilince satış tamamdır.
  Stream<bool> watchSaleCompleted() async* {
    _ensureConnected();
    try {
      yield* _client.watchSaleCompleted(
        pollInterval: Duration(milliseconds: _timings.saleCompletedPollMs),
      );
    } on PLCException catch (e) {
      _logger.error('watchSaleCompleted hatası: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // Sensörler — Blok 4
  // -------------------------------------------------------------------------

  /// SENSOR_STOCK_1..24 (R401–R424) batch okur.
  ///
  /// Index 0 = slot-1, index 23 = slot-24. 0=boş, 1=dolu.
  Future<List<int>> readStockSensors() async {
    _ensureConnected();
    try {
      return await _client.readStockSensors();
    } on PLCException catch (e) {
      _logger.error('readStockSensors hatası: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // Hata — Blok 5
  // -------------------------------------------------------------------------

  /// İki hata slotunu okur: birincil (R500/R501) + ikincil (R502/R503).
  Future<({int code, int slot, int code2, int slot2})> readErrors() async {
    _ensureConnected();
    try {
      return await _client.readErrors();
    } on PLCException catch (e) {
      _logger.error('readErrors hatası: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // Admin: doğrudan register erişimi
  // -------------------------------------------------------------------------

  /// Herhangi bir holding register'ı okur (admin paneli için).
  Future<int> readRegister(int address) async {
    _ensureConnected();
    try {
      return await _client.readRegister(address);
    } on PLCException catch (e) {
      _logger.error('readRegister($address) hatası: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  /// Herhangi bir holding register'a yazar (admin paneli için).
  Future<void> writeRegister(int address, int value) async {
    _ensureConnected();
    try {
      await _client.writeRegister(address, value);
    } on PLCException catch (e) {
      _logger.error('writeRegister($address, $value) hatası: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // Sistem sıfırlama
  // -------------------------------------------------------------------------

  /// CMD_ACTION=5 (oturumu_iptal_et) gönderir.
  ///
  /// Tester basımı veya ödeme akışı sırasında kullanıcı geri dönerse
  /// PLC'ye güvenli durma sinyali verir. ACK beklenmez.
  Future<void> abortSession() async {
    if (!isConnected) return;
    try {
      _logger.debug('Oturum iptal ediliyor...');
      await _client.sendCommand(PLCCommandAction.abortSession, 0);
      _logger.debug('Abort komutu gönderildi');
    } on PLCException catch (e) {
      _logger.warning('abortSession hatası (görmezden geliniyor): ${e.message}');
    }
  }

  /// ERROR_ACK (R504) = 1 yazar; PLC hata registerlarını temizler.
  Future<void> acknowledgeError() async {
    if (!isConnected) return;
    try {
      await _client.writeErrorAck();
      _logger.debug('ERROR_ACK=1 yazıldı');
    } on PLCException catch (e) {
      _logger.warning('acknowledgeError hatası: ${e.message}');
    }
  }

  /// CMD_ACTION=4 (sistem_sıfırla) gönderir.
  Future<void> resetSystem() async {
    _ensureConnected();
    try {
      _logger.info('Sistem sıfırlanıyor...');
      final seqId = await _client.sendCommand(PLCCommandAction.systemReset, 0);
      await _client.waitForCommandAck(
        seqId,
        timeout: Duration(seconds: _timings.commandAckTimeoutSec),
      );
      _logger.info('Sistem sıfırlama ACK ✓');
    } on PLCException catch (e) {
      _logger.error('resetSystem hatası: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  void _ensureConnected() {
    if (!isConnected) {
      throw PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'PLC bağlı değil',
      );
    }
  }

  /// Bağlantı kopukluğu hatası mı? (401–405)
  ///
  /// Komut hatası (414 timeout, 432 rejected, 433 systemFault) bağlantıyı
  /// error state'e çevirmemeli; PLC TCP bağlantısı hâlâ sağlıklı olabilir.
  bool _isConnectionError(PLCException e) {
    const connectionCodes = {
      PLCErrorCodes.connectionFailed,
      PLCErrorCodes.connectionTimeout,
      PLCErrorCodes.connectionLost,
      PLCErrorCodes.invalidHost,
      PLCErrorCodes.portNotAvailable,
    };
    return connectionCodes.contains(e.errorCode);
  }

  void _handleError(PLCException error) {
    _lastError = error;
    if (_isConnectionError(error)) {
      _updateState(PLCConnectionState.error);
    }
    onError?.call(error);
  }

  void _updateState(PLCConnectionState newState) {
    if (_state == newState) return;
    _logger.debug('PLCConnectionState: ${_state.name} → ${newState.name}');
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.disconnect().ignore();
    super.dispose();
  }
}

enum PLCConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}
