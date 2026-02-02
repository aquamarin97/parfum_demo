// plc_service_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:parfume_app/plc/error/plc_error_codes.dart';

import '../plc/modbus_plc_client.dart';
import '../plc/plc_client.dart';

/// PLC bağlantısını yöneten ve hata yönetimi yapan servis
class PLCServiceManager extends ChangeNotifier {
  PLCServiceManager({PlcClient? client, bool autoConnect = true, this.onError})
    : _client = client ?? ModbusPLCClient() {
    if (autoConnect) {
      initialize();
    }
  }

  final PlcClient _client;
  final void Function(PLCException)? onError;

  PLCConnectionState _state = PLCConnectionState.disconnected;
  PLCException? _lastError;
  DateTime? _lastConnectedTime;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  // Getters
  PLCConnectionState get state => _state;
  PLCException? get lastError => _lastError;
  bool get isConnected => _state == PLCConnectionState.connected;
  bool get isConnecting => _state == PLCConnectionState.connecting;
  bool get hasError => _state == PLCConnectionState.error;
  DateTime? get lastConnectedTime => _lastConnectedTime;

  /// PLC bağlantısını başlat
  Future<void> initialize() async {
    if (_state == PLCConnectionState.connecting) {
      debugPrint('[PLCService] Zaten bağlantı kuruluyor...');
      return;
    }

    _updateState(PLCConnectionState.connecting);
    _lastError = null;

    try {
      debugPrint('[PLCService] PLC bağlantısı başlatılıyor...');
      await _client.connect();

      _lastConnectedTime = DateTime.now();
      _reconnectAttempts = 0;
      _updateState(PLCConnectionState.connected);

      debugPrint('[PLCService] ✓ PLC bağlantısı başarılı');
    } on PLCException catch (e) {
      debugPrint(
        '[PLCService] ✗ Bağlantı hatası: ${e.errorCode} - ${e.message}',
      );
      _handleError(e);
    } catch (e) {
      debugPrint('[PLCService] ✗ Beklenmeyen hata: $e');
      final plcError = PLCException(
        errorCode: PLCErrorCodes.unknownError,
        message: 'Beklenmeyen bir hata oluştu',
        technicalDetail: e.toString(),
      );
      _handleError(plcError);
    }
  }

  /// Bağlantıyı kapat
  Future<void> disconnect() async {
    try {
      await _client.disconnect();
      _updateState(PLCConnectionState.disconnected);
      debugPrint('[PLCService] Bağlantı kapatıldı');
    } catch (e) {
      debugPrint('[PLCService] Bağlantı kapatma hatası: $e');
    }
  }

  /// Bağlantıyı yeniden kur
  Future<void> reconnect() async {
    _reconnectAttempts++;

    if (_reconnectAttempts > maxReconnectAttempts) {
      final error = PLCException(
        errorCode: PLCErrorCodes.connectionFailed,
        message: 'Maksimum yeniden bağlanma denemesi aşıldı',
        technicalDetail: 'Deneme sayısı: $_reconnectAttempts',
      );
      _handleError(error);
      return;
    }

    debugPrint('[PLCService] Yeniden bağlanma denemesi: $_reconnectAttempts');

    await disconnect();
    await Future.delayed(const Duration(seconds: 2));
    await initialize();
  }

  /// Önerileri PLC'ye gönder
  Future<void> sendRecommendations(List<int> perfumeIds) async {
    _ensureConnected();

    try {
      debugPrint('[PLCService] Öneriler gönderiliyor: $perfumeIds');
      await _client.sendRecommendation(perfumeIds);
      debugPrint('[PLCService] ✓ Öneriler başarıyla gönderildi');
    } on PLCException catch (e) {
      debugPrint('[PLCService] ✗ Gönderim hatası: ${e.errorCode}');
      _handleError(e);
      rethrow;
    }
  }

  /// Testerların hazır olmasını bekle
  Stream<bool> watchTestersReady() async* {
    _ensureConnected();

    try {
      if (_client is ModbusPLCClient) {
        yield* _client.watchTestersReady();
      } else {
        // Mock client için fallback
        await Future.delayed(const Duration(seconds: 3));
        yield true;
      }
    } on PLCException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Seçilen tester'ı PLC'ye gönder
  Future<void> sendSelectedTester(int testerNumber) async {
    _ensureConnected();
    try {
      debugPrint('[PLCService] Seçilen tester gönderiliyor: $testerNumber');

      // ✅ Direkt interface'den çağır (cast yok)
      await _client.sendSelectedTester(testerNumber);

      debugPrint('[PLCService] ✓ Tester seçimi gönderildi');
    } on PLCException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Ödeme durumunu izle
  Stream<int> watchPaymentStatus() async* {
    _ensureConnected();

    try {
      if (_client is ModbusPLCClient) {
        yield* _client.watchPaymentStatus();
      } else {
        // Mock client
        await Future.delayed(const Duration(seconds: 5));
        yield 1; // Payment complete
      }
    } on PLCException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Parfümün hazır olmasını bekle
  Stream<bool> watchPerfumeReady() async* {
    _ensureConnected();

    try {
      if (_client is ModbusPLCClient) {
        yield* _client.watchPerfumeReady();
      } else {
        await Future.delayed(const Duration(seconds: 8));
        yield true;
      }
    } on PLCException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Bağlantı sağlık kontrolü
  Future<bool> checkHealth() async {
    if (!isConnected) return false;

    try {
      if (_client is ModbusPLCClient) {
        return await _client.healthCheck();
      }
      return true;
    } catch (e) {
      debugPrint('[PLCService] Health check başarısız: $e');
      return false;
    }
  }

  void _ensureConnected() {
    if (!isConnected) {
      throw PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'PLC bağlantısı yok',
      );
    }
  }

  void _handleError(PLCException error) {
    _lastError = error;
    _updateState(PLCConnectionState.error);
    onError?.call(error);
  }

  void _updateState(PLCConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// PLC bağlantı durumu
enum PLCConnectionState { disconnected, connecting, connected, error }
