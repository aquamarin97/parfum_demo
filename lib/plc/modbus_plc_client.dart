// modbus_plc_client.dart - COMPLETE FIXED VERSION
import 'dart:async';
import 'dart:io';
import 'package:modbus/modbus.dart' as modbus;
import 'package:parfume_app/plc/error/plc_error_codes.dart';
import 'plc_client.dart';

/// Modbus TCP üzerinden PLC ile iletişim kuran servis
class ModbusPLCClient implements PlcClient {
  ModbusPLCClient({
    this.host = '127.0.0.1',
    this.port = 502,
    this.connectionTimeout = const Duration(seconds: 3),
    this.responseTimeout = const Duration(seconds: 2),
    this.reconnectAttempts = 3,
    this.reconnectDelay = const Duration(seconds: 2),
  });

  final String host;
  final int port;
  final Duration connectionTimeout;
  final Duration responseTimeout;
  final int reconnectAttempts;
  final Duration reconnectDelay;

  modbus.ModbusClient? _client;
  bool _isConnected = false;
  Timer? _healthCheckTimer;

  // Register adresleri
  static const int regRecommendation1 = 0;
  static const int regRecommendation2 = 1;
  static const int regRecommendation3 = 2;
  static const int regTesterReady = 10;
  static const int regSelectedTester = 11;
  static const int regPaymentStatus = 20;
  static const int regPerfumeReady = 30;
  static const int regHeartbeat = 100;

  @override
  Future<void> connect() async {
    try {
      _log('Bağlantı kuruluyor: $host:$port');

      // ✅ Bağlantıyı kur
      await _connectWithTimeout();

      _isConnected = true;
      _log('✓ Bağlantı başarılı');

      _startHealthCheck();
    } on SocketException catch (e) {
      _client = null;
      _log('✗ Socket hatası: ${e.message}');
      throw PLCException(
        errorCode: PLCErrorCodes.connectionFailed,
        message: 'PLC bağlantısı kurulamadı',
        technicalDetail: 'SocketException: ${e.message}\nHost: $host:$port',
      );
    } on TimeoutException {
      _client = null;
      _log('✗ Bağlantı timeout');
      throw PLCException(
        errorCode: PLCErrorCodes.connectionTimeout,
        message: 'Bağlantı zaman aşımına uğradı',
      );
    } catch (e) {
      _client = null;
      _log('✗ Beklenmeyen hata: $e');
      throw PLCException(
        errorCode: PLCErrorCodes.unknownError,
        message: 'Bağlantı hatası',
        technicalDetail: e.toString(),
      );
    }
  }

  Future<void> _connectWithTimeout() async {
    try {
      // ✅ 1. Client'ı oluştur
      final client = modbus.createTcpClient(host, port: port);

      // ✅ 2. Null check
      if (client == null) {
        throw PLCException(
          errorCode: PLCErrorCodes.connectionFailed,
          message: 'Modbus client oluşturulamadı',
          technicalDetail: 'createTcpClient returned null for $host:$port',
        );
      }

      // ✅ 3. Client'ı set et
      _client = client;

      // ✅ 4. Bağlantı testi yap
      await client
          .readHoldingRegisters(regHeartbeat, 1)
          .timeout(connectionTimeout);
    } catch (e) {
      // Hata durumunda cleanup
      _client = null;
      _log('Bağlantı testi hatası: $e');
      rethrow; // Exception'ı üst katmana fırlat
    }
  }

  @override
  Future<void> disconnect() async {
    _log('Bağlantı kapatılıyor...');
    _stopHealthCheck();
    _isConnected = false;
    _client = null;
    _log('✓ Bağlantı kapatıldı');
  }

  @override
  Future<void> sendRecommendation(List<int> ids) async {
    _ensureConnected();

    try {
      _log('Öneriler PLC\'ye gönderiliyor: $ids');

      if (ids.length < 3) {
        throw PLCException(
          errorCode: PLCErrorCodes.dataCorruption,
          message: 'Yetersiz öneri sayısı',
          technicalDetail: 'Beklenen: 3, Gelen: ${ids.length}',
        );
      }

      await writeRegister(regRecommendation1, ids[0]);
      await writeRegister(regRecommendation2, ids[1]);
      await writeRegister(regRecommendation3, ids[2]);

      _log('✓ Öneriler başarıyla gönderildi');
    } catch (e) {
      if (e is PLCException) rethrow;

      _log('✗ Gönderim hatası: $e');
      throw PLCException(
        errorCode: PLCErrorCodes.modbusWriteError,
        message: 'Veri gönderme hatası',
        technicalDetail: e.toString(),
      );
    }
  }

  @override
  Future<bool> checkTestersReady() async {
    _ensureConnected();

    try {
      final value = await readRegister(regTesterReady);
      _log('Tester durumu: ${value == 1 ? "HAZIR" : "HAZIR DEĞİL"}');
      return value == 1;
    } catch (e) {
      _log('✗ Tester durumu okunamadı: $e');
      throw PLCException(
        errorCode: PLCErrorCodes.modbusReadError,
        message: 'Tester durumu okunamadı',
        technicalDetail: e.toString(),
      );
    }
  }

  @override
  Future<void> sendSelectedTester(int testerNumber) async {
    _ensureConnected();

    if (testerNumber < 1 || testerNumber > 3) {
      throw PLCException(
        errorCode: PLCErrorCodes.invalidRegisterAddress,
        message: 'Geçersiz tester numarası',
        technicalDetail: 'Tester: $testerNumber (beklenen: 1-3)',
      );
    }

    try {
      await writeRegister(regSelectedTester, testerNumber);
      _log('✓ Seçilen tester gönderildi: $testerNumber');
    } catch (e) {
      throw PLCException(
        errorCode: PLCErrorCodes.modbusWriteError,
        message: 'Tester seçimi gönderilemedi',
        technicalDetail: e.toString(),
      );
    }
  }

  @override
  Future<int> checkPaymentStatus() async {
    _ensureConnected();

    try {
      final status = await readRegister(regPaymentStatus);
      _log('Ödeme durumu: $status (0=bekliyor, 1=tamam, 2=hata)');
      return status;
    } catch (e) {
      throw PLCException(
        errorCode: PLCErrorCodes.modbusReadError,
        message: 'Ödeme durumu okunamadı',
        technicalDetail: e.toString(),
      );
    }
  }

  @override
  Future<bool> checkPerfumeReady() async {
    _ensureConnected();

    try {
      final value = await readRegister(regPerfumeReady);
      _log('Parfüm durumu: ${value == 1 ? "HAZIR" : "HAZIRLANMIYOR"}');
      return value == 1;
    } catch (e) {
      throw PLCException(
        errorCode: PLCErrorCodes.modbusReadError,
        message: 'Parfüm durumu okunamadı',
        technicalDetail: e.toString(),
      );
    }
  }

  @override
  Stream<bool> watchTestersReady() async* {
    while (_isConnected && _client != null) {
      try {
        final ready = await checkTestersReady();
        yield ready;
        if (ready) break;
      } catch (e) {
        _log('✗ Tester polling hatası: $e');
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Stream<int> watchPaymentStatus() async* {
    while (_isConnected && _client != null) {
      try {
        final status = await checkPaymentStatus();
        yield status;
        if (status != 0) break;
      } catch (e) {
        _log('✗ Ödeme polling hatası: $e');
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Stream<bool> watchPerfumeReady() async* {
    while (_isConnected && _client != null) {
      try {
        final ready = await checkPerfumeReady();
        yield ready;
        if (ready) break;
      } catch (e) {
        _log('✗ Parfüm polling hatası: $e');
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<int> readRegister(int address) async {
    final client = _client;
    if (client == null) {
      throw PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'PLC bağlantısı yok',
        technicalDetail: 'Client is null in readRegister',
      );
    }

    try {
      final response = await client
          .readHoldingRegisters(address, 1)
          .timeout(responseTimeout);
      return response[0];
    } on TimeoutException {
      throw PLCException(
        errorCode: PLCErrorCodes.responseTimeout,
        message: 'PLC yanıt vermedi',
      );
    }
  }

  Future<void> writeRegister(int address, int value) async {
    final client = _client;
    if (client == null) {
      throw PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'PLC bağlantısı yok',
        technicalDetail: 'Client is null in writeRegister',
      );
    }

    try {
      await client.writeSingleRegister(address, value).timeout(responseTimeout);
    } on TimeoutException {
      throw PLCException(
        errorCode: PLCErrorCodes.responseTimeout,
        message: 'Yazma işlemi zaman aşımına uğradı',
      );
    }
  }

  @override
  Future<bool> healthCheck() async {
    if (!_isConnected) return false;

    if (_client == null) {
      _log('⚠ Health check: Client is null');
      _isConnected = false;
      return false;
    }

    try {
      await readRegister(regHeartbeat);
      return true;
    } catch (e) {
      _log('⚠ Health check başarısız: $e');
      _isConnected = false;
      return false;
    }
  }

  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final healthy = await healthCheck();
      if (!healthy) {
        _log('⚠ Bağlantı kesildi, yeniden bağlanılıyor...');
        try {
          await _reconnect();
        } catch (e) {
          _log('✗ Yeniden bağlanma başarısız: $e');
        }
      }
    });
  }

  void _stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  Future<void> _reconnect() async {
    await disconnect();

    for (int i = 0; i < reconnectAttempts; i++) {
      try {
        _log('Yeniden bağlanma denemesi ${i + 1}/$reconnectAttempts');
        await Future.delayed(reconnectDelay);
        await connect();
        _log('✓ Yeniden bağlantı başarılı');
        return;
      } catch (e) {
        _log('✗ Deneme ${i + 1} başarısız: $e');
        if (i < reconnectAttempts - 1) {
          await Future.delayed(reconnectDelay);
        }
      }
    }

    throw PLCException(
      errorCode: PLCErrorCodes.connectionLost,
      message: 'PLC ile bağlantı yeniden kurulamadı',
    );
  }

  void _ensureConnected() {
    if (!_isConnected) {
      throw PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'PLC bağlantısı kesildi',
      );
    }

    if (_client == null) {
      throw PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'PLC bağlantısı yok',
        technicalDetail: 'Client instance is null',
      );
    }
  }

  void _log(String message) {
    print('[ModbusPLC] $message');
  }

  @override
  bool get isConnected => _isConnected && _client != null;
}
