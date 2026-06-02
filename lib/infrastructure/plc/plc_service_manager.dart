import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:parfume_app/domain/plc/i_plc_client.dart';
import 'package:parfume_app/domain/plc/plc_exceptions.dart';

/// PLC bağlantısını yöneten ve hata yönetimi yapan servis.
/// Concrete client dışarıdan enjekte edilir (DIP).
class PLCServiceManager extends ChangeNotifier {
  PLCServiceManager({
    required IPlcClient client,
    bool autoConnect = true,
    this.onError,
  }) : _client = client {
    if (autoConnect) initialize();
  }

  final IPlcClient _client;
  final void Function(PLCException)? onError;

  PLCConnectionState _state = PLCConnectionState.disconnected;
  PLCException? _lastError;
  DateTime? _lastConnectedTime;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  PLCConnectionState get state => _state;
  PLCException? get lastError => _lastError;
  bool get isConnected => _state == PLCConnectionState.connected;
  bool get isConnecting => _state == PLCConnectionState.connecting;
  bool get hasError => _state == PLCConnectionState.error;
  DateTime? get lastConnectedTime => _lastConnectedTime;

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
      debugPrint('[PLCService] ✗ Bağlantı hatası: ${e.errorCode} - ${e.message}');
      _handleError(e);
    } catch (e) {
      debugPrint('[PLCService] ✗ Beklenmeyen hata: $e');
      _handleError(PLCException(
        errorCode: PLCErrorCodes.unknownError,
        message: 'Beklenmeyen bir hata oluştu',
        technicalDetail: e.toString(),
      ));
    }
  }

  Future<void> disconnect() async {
    try {
      await _client.disconnect();
      _updateState(PLCConnectionState.disconnected);
      debugPrint('[PLCService] Bağlantı kapatıldı');
    } catch (e) {
      debugPrint('[PLCService] Bağlantı kapatma hatası: $e');
    }
  }

  Future<void> reconnect() async {
    _reconnectAttempts++;

    if (_reconnectAttempts > maxReconnectAttempts) {
      _handleError(PLCException(
        errorCode: PLCErrorCodes.connectionFailed,
        message: 'Maksimum yeniden bağlanma denemesi aşıldı',
        technicalDetail: 'Deneme sayısı: $_reconnectAttempts',
      ));
      return;
    }

    debugPrint('[PLCService] Yeniden bağlanma denemesi: $_reconnectAttempts');
    await disconnect();
    await Future.delayed(const Duration(seconds: 2));
    await initialize();
  }

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

  Stream<bool> watchTestersReady() async* {
    _ensureConnected();
    try {
      yield* _client.watchTestersReady();
    } on PLCException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<void> sendSelectedTester(int testerNumber) async {
    _ensureConnected();
    try {
      debugPrint('[PLCService] Seçilen tester gönderiliyor: $testerNumber');
      await _client.sendSelectedTester(testerNumber);
      debugPrint('[PLCService] ✓ Tester seçimi gönderildi');
    } on PLCException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Stream<int> watchPaymentStatus() async* {
    _ensureConnected();
    try {
      yield* _client.watchPaymentStatus();
    } on PLCException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Stream<bool> watchPerfumeReady() async* {
    _ensureConnected();
    try {
      yield* _client.watchPerfumeReady();
    } on PLCException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<bool> checkHealth() async {
    if (!isConnected) return false;
    try {
      return await _client.healthCheck();
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

enum PLCConnectionState { disconnected, connecting, connected, error }
