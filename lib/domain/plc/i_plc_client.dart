/// PLC'ye gönderilecek komut türleri (CMD_ACTION, R100).
enum PLCCommandAction {
  idle(0),
  testerPress(1),
  startPayment(2),
  salePress(3),
  systemReset(4),
  abortSession(5);

  const PLCCommandAction(this.value);
  final int value;
}

/// PLC donanımıyla iletişim kuran client'ların uyması gereken sözleşme.
///
/// Register haritası v1.1 (Modbus TCP, Holding Registers 4x):
///   Blok 1 — Komutlar   (100–102): Flutter yazar, PLC okur
///   Blok 2 — Durum      (200–203): PLC yazar, Flutter okur
///   Blok 3 — Ödeme      (300–303): çift yönlü
///   Blok 4 — Sensörler  (400–424): PLC yazar, Flutter okur
///   Blok 5 — Hata       (500–504): PLC yazar (500–503), Flutter yazar (504=ACK)
///   Blok 6 — Heartbeat  (600–601): çift yönlü
abstract interface class IPlcClient {
  // -------------------------------------------------------------------------
  // Bağlantı
  // -------------------------------------------------------------------------

  Future<void> connect();
  Future<void> disconnect();
  bool get isConnected;
  Future<bool> healthCheck();

  // -------------------------------------------------------------------------
  // Komut protokolü — Blok 1 (Flutter→PLC) + Blok 2 (PLC→Flutter)
  // -------------------------------------------------------------------------

  /// CMD_ACTION (R100), CMD_SLOT (R101), CMD_SEQUENCE_ID (R102) yazar.
  ///
  /// Kullanılan sequence ID'yi döner.
  Future<int> sendCommand(PLCCommandAction action, int slot);

  /// STATUS_LAST_CMD_SEQ_ID (R201) == [seqId] olana kadar bekler.
  ///
  /// `true` → STATUS_LAST_CMD_RESULT (R202) = 0 (başarılı).
  /// `false` → STATUS_LAST_CMD_RESULT = 1 (başarısız).
  /// [timeout] aşılırsa [PLCException] fırlatır.
  Future<bool> waitForCommandAck(
    int seqId, {
    Duration timeout = const Duration(seconds: 30),
  });

  /// STATUS_SYSTEM (R200) değerini okur.
  ///
  /// 0=boşta, 1=meşgul, 2=hata
  Future<int> readSystemStatus();

  /// STATUS_ACTIVE_SLOT (R203) değerini okur.
  Future<int> readActiveSlot();

  // -------------------------------------------------------------------------
  // Ödeme — Blok 3
  // -------------------------------------------------------------------------

  /// PAYMENT_AMOUNT (R301) yazar — kuruş cinsinden (15000 = 150,00 TL).
  Future<void> writePaymentAmount(int amountKurus);

  /// PAYMENT_CONFIRMED_ACK (R302) = 1 yazar; PLC sıfırlar.
  Future<void> writePaymentConfirmedAck();

  /// PAYMENT_STATUS (R300) register'ını periyodik okur ve her değeri emit eder.
  ///
  /// 0=bekliyor, 1=onaylandı, 2=reddedildi, 3=timeout
  Stream<int> watchPaymentStatus({
    Duration pollInterval = const Duration(seconds: 1),
  });

  /// SALE_COMPLETED (R303) = 1 olana kadar periyodik okur.
  ///
  /// `true` emit edildiğinde register sıfırlanır ve stream biter.
  Stream<bool> watchSaleCompleted({
    Duration pollInterval = const Duration(milliseconds: 500),
  });

  // -------------------------------------------------------------------------
  // Sensörler — Blok 4
  // -------------------------------------------------------------------------

  /// SENSOR_PRESENCE (R400) okur.
  ///
  /// 0=kullanıcı yok, 1=kullanıcı var
  Future<int> readPresenceSensor();

  /// SENSOR_STOCK_1..24 (R401–R424) batch okur.
  ///
  /// Dönen listenin 0. elemanı slot-1'e, 23. elemanı slot-24'e karşılık gelir.
  /// 0=boş, 1=dolu
  Future<List<int>> readStockSensors();

  // -------------------------------------------------------------------------
  // Hata — Blok 5
  // -------------------------------------------------------------------------

  /// İki hata slotunu birlikte okur.
  ///
  /// - `code` / `slot`   → R500 / R501 (birincil hata)
  /// - `code2` / `slot2` → R502 / R503 (ikincil hata, 0=hata yok)
  Future<({int code, int slot, int code2, int slot2})> readErrors();

  /// ERROR_ACK (R504) = 1 yazar; PLC hatayı temizler.
  Future<void> writeErrorAck();

  // -------------------------------------------------------------------------
  // Heartbeat — Blok 6
  // -------------------------------------------------------------------------

  /// PLC_HEARTBEAT (R600) okur.
  Future<int> readPLCHeartbeat();

  /// FLUTTER_HEARTBEAT (R601) yazar.
  Future<void> writeFlutterHeartbeat(int value);

  // -------------------------------------------------------------------------
  // Admin: doğrudan register erişimi
  // -------------------------------------------------------------------------

  /// Herhangi bir holding register'ı tek seferlik okur.
  Future<int> readRegister(int address);

  /// Herhangi bir holding register'a tek seferlik yazar.
  Future<void> writeRegister(int address, int value);
}
