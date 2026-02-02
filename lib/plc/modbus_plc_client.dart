// modbus_plc_client.dart
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

  // Register adresleri (ModRSsim2 ile uyumlu)
  static const int regRecommendation1 = 0; // İlk öneri ID
  static const int regRecommendation2 = 1; // İkinci öneri ID
  static const int regRecommendation3 = 2; // Üçüncü öneri ID
  static const int regTesterReady = 10; // Testerlar hazır mı? (1=evet, 0=hayır)
  static const int regSelectedTester = 11; // Seçilen tester (1-3)
  static const int regPaymentStatus =
      20; // Ödeme durumu (0=bekliyor, 1=tamam, 2=hata)
  static const int regPerfumeReady = 30; // Parfüm hazır mı? (1=evet, 0=hayır)
  static const int regHeartbeat = 100; // Heartbeat (PLC canlılık kontrolü)

  @override
  Future<void> connect() async {
    try {
      _log('Bağlantı kuruluyor: $host:$port');

      // Timeout ile bağlantı dene
      await _connectWithTimeout();

      _isConnected = true;
      _log('✓ Bağlantı başarılı');

      // Health check başlat
      _startHealthCheck();
    } on SocketException catch (e) {
      _log('✗ Socket hatası: $e');
      throw PLCException(
        errorCode: PLCErrorCodes.connectionFailed,
        message: 'PLC bağlantısı kurulamadı',
        technicalDetail: 'SocketException: ${e.message}',
      );
    } on TimeoutException {
      _log('✗ Bağlantı timeout');
      throw PLCException(
        errorCode: PLCErrorCodes.connectionTimeout,
        message: 'Bağlantı zaman aşımına uğradı',
      );
    } catch (e) {
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
      // Timeout parametresini buradan kaldırıyoruz
      _client = modbus.createTcpClient(host, port: port);

      // Bağlantıyı test eden okuma işlemini timeout ile sarmalıyoruz
      await readRegister(regHeartbeat).timeout(connectionTimeout);
    } on TimeoutException {
      _client = null;
      rethrow;
    } catch (e) {
      _client = null;
      print("Bağlantı hatası: $e");
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

      // 3 öneriyi sırayla yaz
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

  /// Testerların hazır olup olmadığını kontrol et
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

  /// Seçilen tester numarasını PLC'ye gönder
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

  /// Ödeme durumunu kontrol et
  /// Returns: 0=bekliyor, 1=tamam, 2=hata
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

  /// Parfümün hazır olup olmadığını kontrol et
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

  /// Stream: Testerların hazır olmasını bekle
  Stream<bool> watchTestersReady() async* {
    while (_isConnected) {
      try {
        final ready = await checkTestersReady();
        yield ready;
        if (ready) break;
      } catch (e) {
        _log('✗ Tester polling hatası: $e');
        // Hata durumunda yine de devam et
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// Stream: Ödeme durumunu izle
  Stream<int> watchPaymentStatus() async* {
    while (_isConnected) {
      try {
        final status = await checkPaymentStatus();
        yield status;
        if (status != 0) break; // 0 dışında bir değer gelirse dur
      } catch (e) {
        _log('✗ Ödeme polling hatası: $e');
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// Stream: Parfüm hazır olmasını bekle
  Stream<bool> watchPerfumeReady() async* {
    while (_isConnected) {
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

  /// Tek bir register oku (Holding Register)
  Future<int> readRegister(int address) async {
    try {
      final response = await _client!
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

  /// Tek bir register'a yaz
  Future<void> writeRegister(int address, int value) async {
    try {
      await _client!
          .writeSingleRegister(address, value)
          .timeout(responseTimeout);
    } on TimeoutException {
      throw PLCException(
        errorCode: PLCErrorCodes.responseTimeout,
        message: 'Yazma işlemi zaman aşımına uğradı',
      );
    }
  }

  /// PLC bağlantısının sağlıklı olup olmadığını kontrol et
  Future<bool> healthCheck() async {
    if (!_isConnected) return false;

    try {
      // Heartbeat register'ını oku
      await readRegister(regHeartbeat);
      return true;
    } catch (e) {
      _log('⚠ Health check başarısız: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Periyodik health check başlat
  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final healthy = await healthCheck();
      if (!healthy) {
        _log('⚠ Bağlantı kesildi, yeniden bağlanılıyor...');
        await _reconnect();
      }
    });
  }

  void _stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// Bağlantıyı yeniden kur
  Future<void> _reconnect() async {
    for (int i = 0; i < reconnectAttempts; i++) {
      try {
        _log('Yeniden bağlanma denemesi ${i + 1}/$reconnectAttempts');
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
    if (!_isConnected || _client == null) {
      throw PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'PLC bağlantısı yok',
      );
    }
  }

  void _log(String message) {
    print('[ModbusPLC] $message');
  }

  bool get isConnected => _isConnected;
}
