// modbus_plc_client.dart - CONFIG-BASED VERSION
import 'dart:async';
import 'dart:io';
import 'package:modbus/modbus.dart' as modbus;
import 'package:parfume_app/domain/plc/i_plc_client.dart';
import 'package:parfume_app/domain/plc/plc_exceptions.dart';
import 'package:parfume_app/infrastructure/plc/config/register_loader.dart';
import 'package:parfume_app/infrastructure/plc/config/register_config.dart';
import 'package:parfume_app/data/models/plc/plc_event.dart';

/// ✅ Config-based Modbus TCP PLC Client
///
/// Register adresleri artık JSON'dan yükleniyor.
/// Yeni register eklemek için sadece JSON'ı güncelle!
class ModbusPLCClient implements IPlcClient {
  ModbusPLCClient({
    this.connectionTimeout = const Duration(seconds: 3),
    this.responseTimeout = const Duration(seconds: 2),
    this.reconnectAttempts = 3,
    this.reconnectDelay = const Duration(seconds: 2),
  });

  final Duration connectionTimeout;
  final Duration responseTimeout;
  final int reconnectAttempts;
  final Duration reconnectDelay;

  modbus.ModbusClient? _client;
  bool _isConnected = false;
  Timer? _healthCheckTimer;

  // ✅ Config yükleyici
  final RegisterLoader _configLoader = RegisterLoader();
  PLCRegisterConfig? _config;

  // ✅ Register adreslerine erişim metodları (lazy load)
  int get _regRecommendation1 => _getAddress('recommendations.first');
  int get _regRecommendation2 => _getAddress('recommendations.second');
  int get _regRecommendation3 => _getAddress('recommendations.third');
  int get _regTesterReady => _getAddress('tester_control.testers_ready');
  int get _regSelectedTester => _getAddress('tester_control.selected_tester');
  int get _regPaymentStatus => _getAddress('payment.status');
  int get _regPerfumeReady => _getAddress('perfume_dispenser.ready');
  int get _regHeartbeat => _getAddress('system.heartbeat');

  // ✅ Config'den adres al (cache'li)
  int _getAddress(String path) {
    if (_config == null) {
      throw PLCException(
        errorCode: PLCErrorCodes.configurationError,
        message: 'PLC config yüklenmemiş',
        technicalDetail: 'Config must be loaded before accessing registers',
      );
    }

    try {
      return _config!.getAddress(path);
    } catch (e) {
      throw PLCException(
        errorCode: PLCErrorCodes.invalidRegisterAddress,
        message: 'Geçersiz register path: $path',
        technicalDetail: e.toString(),
      );
    }
  }

  @override
  Future<void> connect() async {
    try {
      // ✅ 1. Config'i yükle
      await _loadConfig();

      // ✅ 2. Connection parametrelerini config'den al
      final host = _config!.connection.host;
      final port = _config!.connection.port;

      _log('Bağlantı kuruluyor: $host:$port (config-based)');

      // ✅ 3. Bağlantıyı kur
      await _connectWithTimeout(host, port);

      _isConnected = true;
      _log('✓ Bağlantı başarılı');

      // EKLE: Bağlantı başarılı logu
      PLCEventLogger.instance.logConnection('PLC bağlantısı başarılı');

      _startHealthCheck();
    } on SocketException catch (e) {
      _client = null;
      _log('✗ Socket hatası: ${e.message}');

      // EKLE: Hata logu
      PLCEventLogger.instance.logError('Bağlantı hatası', error: e.toString());

      throw PLCException(
        errorCode: PLCErrorCodes.connectionFailed,
        message: 'PLC bağlantısı kurulamadı',
        technicalDetail: 'SocketException: ${e.message}',
      );
    } on TimeoutException {
      _client = null;
      _log('✗ Bağlantı timeout');

      // EKLE: Hata logu
      PLCEventLogger.instance.logError('Bağlantı hatası', error: 'Timeout');

      throw PLCException(
        errorCode: PLCErrorCodes.connectionTimeout,
        message: 'Bağlantı zaman aşımına uğradı',
      );
    } catch (e) {
      _client = null;
      _log('✗ Beklenmeyen hata: $e');

      // EKLE: Hata logu
      PLCEventLogger.instance.logError('Bağlantı hatası', error: e.toString());

      throw PLCException(
        errorCode: PLCErrorCodes.unknownError,
        message: 'Bağlantı hatası',
        technicalDetail: e.toString(),
      );
    }
  }

  /// ✅ Config yükle
  Future<void> _loadConfig() async {
    try {
      _log('Config yükleniyor...');
      _config = await _configLoader.load();

      _log('✓ Config yüklendi: v${_config!.version}');
      _log('  Total registers: ${_config!.registers.getAllAddresses().length}');
      _log(
        '  Connection: ${_config!.connection.host}:${_config!.connection.port}',
      );
    } catch (e) {
      throw PLCException(
        errorCode: PLCErrorCodes.configurationError,
        message: 'Config yüklenemedi',
        technicalDetail: e.toString(),
      );
    }
  }

  Future<void> _connectWithTimeout(String host, int port) async {
    try {
      _log('Creating Modbus TCP client...');
      final client = modbus.createTcpClient(host, port: port);

      _log('Client created, connecting...');
      _client = client;

      await client.connect().timeout(connectionTimeout);
      _log('Connected, testing communication...');

      // ✅ Config'den heartbeat adresini al
      await client
          .readHoldingRegisters(_regHeartbeat, 1)
          .timeout(connectionTimeout);

      _log('✓ Bağlantı testi başarılı');
    } catch (e) {
      _client = null;
      _log('Bağlantı hatası: $e');
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _log('Bağlantı kapatılıyor...');
    _stopHealthCheck();

    try {
      if (_client != null) {
        await _client!.close();
      }
    } catch (e) {
      _log('Disconnect hatası (görmezden geliniyor): $e');
    }

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

      // ✅ Config-based register yazma
      await writeRegister(_regRecommendation1, ids[0]);
      await writeRegister(_regRecommendation2, ids[1]);
      await writeRegister(_regRecommendation3, ids[2]);

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
      final value = await readRegister(_regTesterReady);
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
      await writeRegister(_regSelectedTester, testerNumber);
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
      final status = await readRegister(_regPaymentStatus);

      // ✅ Config'den değer açıklamasını al
      final description = _config!.registers
          .getGroup('payment')
          ?.getValueDescription('status', status);

      _log(
        'Ödeme durumu: $status${description != null ? " ($description)" : ""}',
      );
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
      final value = await readRegister(_regPerfumeReady);
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
      final value = response[0];

      // EKLE: Okuma başarılı logu
      PLCEventLogger.instance.logRead(address, value);

      return value;
    } on TimeoutException {
      // EKLE: Hata logu
      PLCEventLogger.instance.logError(
        'Register $address okuma hatası',
        error: 'Timeout',
      );

      throw PLCException(
        errorCode: PLCErrorCodes.responseTimeout,
        message: 'PLC yanıt vermedi',
      );
    } catch (e) {
      // EKLE: Hata logu
      PLCEventLogger.instance.logError(
        'Register $address okuma hatası',
        error: e.toString(),
      );

      rethrow;
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

      // EKLE: Yazma başarılı logu
      PLCEventLogger.instance.logWrite(address, value);
    } on TimeoutException {
      // EKLE: Hata logu
      PLCEventLogger.instance.logError(
        'Register $address yazma hatası',
        error: 'Timeout',
      );

      throw PLCException(
        errorCode: PLCErrorCodes.responseTimeout,
        message: 'Yazma işlemi zaman aşımına uğradı',
      );
    } catch (e) {
      // EKLE: Hata logu
      PLCEventLogger.instance.logError(
        'Register $address yazma hatası',
        error: e.toString(),
      );

      rethrow;
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
      await readRegister(_regHeartbeat);
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

  // ✅ DEBUG: Config'i yazdır
  void printConfig() {
    if (_config == null) {
      _log('Config henüz yüklenmedi');
      return;
    }

    _configLoader.printConfigInfo();
  }
}
