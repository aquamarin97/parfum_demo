import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:modbus/modbus.dart' as modbus;
import 'package:parfume_app/domain/plc/i_plc_client.dart';
import 'package:parfume_app/domain/plc/plc_exceptions.dart';
import 'package:parfume_app/infrastructure/plc/config/register_loader.dart';
import 'package:parfume_app/infrastructure/plc/config/register_config.dart';
import 'package:parfume_app/data/models/plc/plc_event.dart';

/// Modbus TCP tabanlı PLC istemcisi — Register Haritası v1.0
///
/// Tüm register adresleri JSON config'den yüklenir.
/// Komut protokolü: CMD_ACTION (R100) + CMD_SLOT (R101) + CMD_SEQUENCE_ID (R102).
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
  Timer? _heartbeatTimer;

  final RegisterLoader _configLoader = RegisterLoader();
  PLCRegisterConfig? _config;

  // Sequence ID: 0–255, her komutta +1 (döngüsel).
  int _sequenceId = 0;
  // Flutter heartbeat: 0–65535, her saniye +1 (döngüsel).
  int _flutterHeartbeat = 0;
  // Heartbeat guard: kuyrukta zaten bir yazma varsa yenisini ekleme.
  bool _heartbeatQueued = false;

  // Serialization: tüm Modbus operasyonları sırayla çalışır.
  // Her yeni operasyon bir öncekinin tamamlanmasını bekler.
  Future<void> _lastOp = Future.value();

  /// Tüm register okuma/yazma işlemlerini sıraya koyar.
  ///
  /// Hatalı operasyonlar bir sonrakini engellemez.
  Future<T> _serialized<T>(Future<T> Function() fn) {
    final result = _lastOp.then((_) => fn());
    _lastOp = result.then((_) {}, onError: (_) {});
    return result;
  }

  // -------------------------------------------------------------------------
  // Block 1 — Komutlar (Flutter yazar)
  // -------------------------------------------------------------------------
  int get _regCmdAction   => _getAddress('commands.action');      // 100
  int get _regCmdSlot     => _getAddress('commands.slot');        // 101
  int get _regCmdSeqId    => _getAddress('commands.sequence_id'); // 102

  // -------------------------------------------------------------------------
  // Block 2 — Sistem Durumu (PLC yazar)
  // -------------------------------------------------------------------------
  int get _regStatusSystem        => _getAddress('system_status.system');          // 200
  int get _regStatusLastCmdSeqId  => _getAddress('system_status.last_cmd_seq_id'); // 201
  int get _regStatusLastCmdResult => _getAddress('system_status.last_cmd_result'); // 202
  // int get _regStatusActiveSlot => _getAddress('system_status.active_slot');     // 203

  // -------------------------------------------------------------------------
  // Block 3 — Ödeme (çift yönlü)
  // -------------------------------------------------------------------------
  int get _regPaymentStatus       => _getAddress('payment.status');        // 300
  int get _regPaymentAmount       => _getAddress('payment.amount');        // 301
  int get _regPaymentConfirmedAck => _getAddress('payment.confirmed_ack'); // 302
  int get _regSaleCompleted       => _getAddress('payment.sale_completed');// 303

  // -------------------------------------------------------------------------
  // Block 4 — Sensörler (PLC yazar)
  // -------------------------------------------------------------------------
  int get _regSensorPresence => _getAddress('sensors.presence');  // 400
  int get _regSensorStock1   => _getAddress('sensors.stock_1');   // 401

  // -------------------------------------------------------------------------
  // Block 5 — Hata (500–504)
  // -------------------------------------------------------------------------
  int get _regErrorCode  => _getAddress('errors.error_code');   // 500
  int get _regErrorSlot  => _getAddress('errors.error_slot');   // 501
  int get _regErrorCode2 => _getAddress('errors.error_code_2'); // 502
  int get _regErrorSlot2 => _getAddress('errors.error_slot_2'); // 503
  int get _regErrorAck   => _getAddress('errors.error_ack');    // 504

  // -------------------------------------------------------------------------
  // Block 6 — Heartbeat (çift yönlü)
  // -------------------------------------------------------------------------
  int get _regPlcHeartbeat     => _getAddress('heartbeat.plc_heartbeat');     // 600
  int get _regFlutterHeartbeat => _getAddress('heartbeat.flutter_heartbeat'); // 601

  // -------------------------------------------------------------------------
  // Bağlantı
  // -------------------------------------------------------------------------

  @override
  Future<void> connect() async {
    try {
      await _loadConfig();

      final host = _config!.connection.host;
      final port = _config!.connection.port;
      _log('Bağlantı kuruluyor: $host:$port');

      await _connectWithTimeout(host, port);

      _isConnected = true;
      _log('✓ Bağlantı başarılı');
      PLCEventLogger.instance.logConnection('PLC bağlantısı başarılı');

      _startHealthCheckTimer();
      _startHeartbeatTimer();
    } on SocketException catch (e) {
      _client = null;
      PLCEventLogger.instance.logError('Bağlantı hatası', error: e.toString());
      throw PLCException(
        errorCode: PLCErrorCodes.connectionFailed,
        message: 'PLC bağlantısı kurulamadı',
        technicalDetail: 'SocketException: ${e.message}',
      );
    } on TimeoutException {
      _client = null;
      PLCEventLogger.instance.logError('Bağlantı hatası', error: 'Timeout');
      throw PLCException(
        errorCode: PLCErrorCodes.connectionTimeout,
        message: 'Bağlantı zaman aşımına uğradı',
      );
    } catch (e) {
      _client = null;
      PLCEventLogger.instance.logError('Bağlantı hatası', error: e.toString());
      throw PLCException(
        errorCode: PLCErrorCodes.unknownError,
        message: 'Bağlantı hatası',
        technicalDetail: e.toString(),
      );
    }
  }

  @override
  Future<void> disconnect() async {
    _log('Bağlantı kapatılıyor...');
    // Önce flag'leri sıfırla — kuyruktaki işlemler hızlı fail olsun.
    _isConnected = false;
    _heartbeatQueued = false;
    _stopHealthCheckTimer();
    _stopHeartbeatTimer();
    _lastOp = Future.value();

    try {
      await _client?.close();
    } catch (e) {
      _log('Disconnect hatası (görmezden geliniyor): $e');
    }

    _client = null;
    _log('✓ Bağlantı kapatıldı');
  }

  @override
  bool get isConnected => _isConnected && _client != null;

  @override
  Future<bool> healthCheck() async {
    if (!_isConnected || _client == null) return false;
    try {
      await readRegister(_regPlcHeartbeat);
      return true;
    } catch (e) {
      _log('Health check başarısız: $e');
      _isConnected = false;
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Komut protokolü
  // -------------------------------------------------------------------------

  @override
  Future<int> sendCommand(PLCCommandAction action, int slot) async {
    _ensureConnected();
    _sequenceId = (_sequenceId + 1) & 0xFF;
    final seqId = _sequenceId;

    try {
      // Önce veri registerları, son olarak seqId (PLC trigger noktası)
      await writeRegister(_regCmdSlot, slot);
      await writeRegister(_regCmdAction, action.value);
      await writeRegister(_regCmdSeqId, seqId);
      _log('→ CMD action=${action.value} slot=$slot seqId=$seqId');
      return seqId;
    } catch (e) {
      if (e is PLCException) rethrow;
      throw PLCException(
        errorCode: PLCErrorCodes.modbusWriteError,
        message: 'Komut gönderilemedi',
        technicalDetail: e.toString(),
      );
    }
  }

  @override
  Future<bool> waitForCommandAck(
    int seqId, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _ensureConnected();
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline) && _isConnected) {
      final lastAcked = await _serialized(() => _readRegisterImpl(_regStatusLastCmdSeqId, silent: true));
      if (lastAcked == seqId) {
        final result = await _serialized(() => _readRegisterImpl(_regStatusLastCmdResult, silent: true));
        _log('← ACK seqId=$seqId result=$result');
        PLCEventLogger.instance.logRead(_regStatusLastCmdSeqId, lastAcked);
        PLCEventLogger.instance.logRead(_regStatusLastCmdResult, result);
        return result == 0;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    throw PLCException(
      errorCode: PLCErrorCodes.responseTimeout,
      message: 'Komut yanıtı alınamadı',
      technicalDetail: 'Beklenen seqId: $seqId',
    );
  }

  @override
  Future<int> readSystemStatus() async {
    _ensureConnected();
    return readRegister(_regStatusSystem);
  }

  @override
  Future<int> readActiveSlot() async {
    _ensureConnected();
    return readRegister(_getAddress('system_status.active_slot'));
  }

  // -------------------------------------------------------------------------
  // Ödeme
  // -------------------------------------------------------------------------

  @override
  Future<void> writePaymentAmount(int amountKurus) async {
    _ensureConnected();
    await writeRegister(_regPaymentAmount, amountKurus);
    _log('→ PAYMENT_AMOUNT=$amountKurus TL');
  }

  @override
  Future<void> writePaymentConfirmedAck() async {
    _ensureConnected();
    await writeRegister(_regPaymentConfirmedAck, 1);
    _log('→ PAYMENT_CONFIRMED_ACK=1');
  }

  @override
  Stream<int> watchPaymentStatus({
    Duration pollInterval = const Duration(seconds: 1),
  }) async* {
    while (true) {
      final status = await readRegister(_regPaymentStatus);
      _log('← PAYMENT_STATUS=$status');
      yield status;
      if (status != 0) break;
      await Future.delayed(pollInterval);
    }
  }

  @override
  Stream<bool> watchSaleCompleted({
    Duration pollInterval = const Duration(milliseconds: 500),
  }) async* {
    while (true) {
      final value = await readRegister(_regSaleCompleted);
      if (value == 1) {
        _log('← SALE_COMPLETED=1 — sıfırlanıyor');
        await writeRegister(_regSaleCompleted, 0);
        yield true;
        break;
      }
      yield false;
      await Future.delayed(pollInterval);
    }
  }

  // -------------------------------------------------------------------------
  // Sensörler
  // -------------------------------------------------------------------------

  @override
  Future<int> readPresenceSensor() async {
    _ensureConnected();
    return readRegister(_regSensorPresence);
  }

  @override
  Future<List<int>> readStockSensors() =>
      _serialized(() => _readStockSensorsImpl());

  Future<List<int>> _readStockSensorsImpl() async {
    _ensureConnected();
    final client = _client;
    if (client == null) {
      throw PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'PLC bağlantısı yok',
      );
    }

    try {
      // 24 register'ı tek seferde batch okur (R401–R424)
      final response = await client
          .readHoldingRegisters(_regSensorStock1, 24)
          .timeout(responseTimeout);
      return List<int>.from(response);
    } catch (e) {
      throw PLCException(
        errorCode: PLCErrorCodes.modbusReadError,
        message: 'Stok sensörleri okunamadı',
        technicalDetail: e.toString(),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Hata
  // -------------------------------------------------------------------------

  @override
  Future<({int code, int slot, int code2, int slot2})> readErrors() async {
    _ensureConnected();
    final code  = await readRegister(_regErrorCode);
    final slot  = await readRegister(_regErrorSlot);
    final code2 = await readRegister(_regErrorCode2);
    final slot2 = await readRegister(_regErrorSlot2);
    return (code: code, slot: slot, code2: code2, slot2: slot2);
  }

  @override
  Future<void> writeErrorAck() async {
    _ensureConnected();
    await writeRegister(_regErrorAck, 1);
    _log('→ ERROR_ACK=1');
  }

  // -------------------------------------------------------------------------
  // Heartbeat
  // -------------------------------------------------------------------------

  @override
  Future<int> readPLCHeartbeat() async {
    _ensureConnected();
    return readRegister(_regPlcHeartbeat);
  }

  @override
  Future<void> writeFlutterHeartbeat(int value) async {
    _ensureConnected();
    await writeRegister(_regFlutterHeartbeat, value);
  }

  // -------------------------------------------------------------------------
  // Doğrudan register erişimi (admin + internal)
  // -------------------------------------------------------------------------

  @override
  Future<int> readRegister(int address) =>
      _serialized(() => _readRegisterImpl(address));

  @override
  Future<void> writeRegister(int address, int value) =>
      _serialized(() => _writeRegisterImpl(address, value));

  Future<int> _readRegisterImpl(int address, {bool silent = false}) async {
    final client = _client;
    if (client == null) {
      throw PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'PLC bağlantısı yok',
        technicalDetail: 'Client null in readRegister($address)',
      );
    }

    try {
      final response = await client
          .readHoldingRegisters(address, 1)
          .timeout(responseTimeout);
      final value = response[0];
      if (!silent) PLCEventLogger.instance.logRead(address, value);
      return value;
    } on TimeoutException {
      PLCEventLogger.instance.logError('R$address okuma hatası', error: 'Timeout');
      throw PLCException(
        errorCode: PLCErrorCodes.responseTimeout,
        message: 'PLC yanıt vermedi',
      );
    } catch (e) {
      PLCEventLogger.instance.logError('R$address okuma hatası', error: e.toString());
      rethrow;
    }
  }

  Future<void> _writeRegisterImpl(int address, int value, {bool silent = false}) async {
    final client = _client;
    if (client == null) {
      throw PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'PLC bağlantısı yok',
        technicalDetail: 'Client null in writeRegister($address, $value)',
      );
    }

    try {
      await client.writeSingleRegister(address, value).timeout(responseTimeout);
      if (!silent) PLCEventLogger.instance.logWrite(address, value);
    } on TimeoutException {
      PLCEventLogger.instance.logError('R$address yazma hatası', error: 'Timeout');
      throw PLCException(
        errorCode: PLCErrorCodes.responseTimeout,
        message: 'Yazma işlemi zaman aşımına uğradı',
      );
    } catch (e) {
      PLCEventLogger.instance.logError('R$address yazma hatası', error: e.toString());
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  Future<void> _loadConfig() async {
    try {
      _log('Config yükleniyor...');
      _config = await _configLoader.load();
      _log('✓ Config v${_config!.version} yüklendi '
          '(${_config!.registers.getAllAddresses().length} register, '
          '${_config!.connection.host}:${_config!.connection.port})');
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
      final client = modbus.createTcpClient(host, port: port);
      _client = client;
      await client.connect().timeout(connectionTimeout);
      // Bağlantıyı test et — PLC_HEARTBEAT oku
      await client.readHoldingRegisters(_regPlcHeartbeat, 1).timeout(connectionTimeout);
      _log('✓ Bağlantı testi başarılı');
    } catch (e) {
      _client = null;
      rethrow;
    }
  }

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

  void _ensureConnected() {
    if (!_isConnected || _client == null) {
      throw PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'PLC bağlantısı yok',
      );
    }
  }

  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!_isConnected || _client == null) return;
      final healthy = await healthCheck();
      if (!healthy) {
        _log('⚠ Bağlantı kesildi — yeniden bağlanma üst katmana bırakıldı');
        _isConnected = false;
        _stopHealthCheckTimer();
        _stopHeartbeatTimer();
        try { await _client?.close(); } catch (_) {}
        _client = null;
      }
    });
  }

  void _stopHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatQueued = false;
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Kuyrukta zaten bir heartbeat yazma varsa bu tiki atla.
      if (!_isConnected || _client == null || _heartbeatQueued) return;
      _heartbeatQueued = true;
      _flutterHeartbeat = (_flutterHeartbeat + 1) % 65536;
      _serialized(() => _writeRegisterImpl(_regFlutterHeartbeat, _flutterHeartbeat, silent: true))
          .then((_) => _heartbeatQueued = false)
          .catchError((_) => _heartbeatQueued = false);
    });
  }

  void _stopHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _log(String message) => debugPrint('[ModbusPLC] $message');
}
