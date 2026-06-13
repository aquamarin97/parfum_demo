/// PLC iletişim süre parametreleri — admin panelinden düzenlenebilir.
///
/// Tüm değerler [PreferencesStore]'a kaydedilir ve uygulama başlangıcında
/// [PLCServiceManager]'a aktarılır.
class PLCTimings {
  const PLCTimings({
    this.commandAckTimeoutSec = 30,
    this.systemIdlePollMs = 500,
    this.paymentStatusPollMs = 1000,
    this.saleCompletedPollMs = 500,
  });

  static const PLCTimings defaults = PLCTimings();

  /// Komut ACK bekleme süresi (saniye). Varsayılan: 30
  final int commandAckTimeoutSec;

  /// Sistem boşta polling aralığı (ms). Varsayılan: 500
  final int systemIdlePollMs;

  /// Ödeme durumu polling aralığı (ms). Varsayılan: 1000
  final int paymentStatusPollMs;

  /// Satış tamamlanma polling aralığı (ms). Varsayılan: 500
  final int saleCompletedPollMs;

  PLCTimings copyWith({
    int? commandAckTimeoutSec,
    int? systemIdlePollMs,
    int? paymentStatusPollMs,
    int? saleCompletedPollMs,
  }) =>
      PLCTimings(
        commandAckTimeoutSec:
            commandAckTimeoutSec ?? this.commandAckTimeoutSec,
        systemIdlePollMs: systemIdlePollMs ?? this.systemIdlePollMs,
        paymentStatusPollMs: paymentStatusPollMs ?? this.paymentStatusPollMs,
        saleCompletedPollMs: saleCompletedPollMs ?? this.saleCompletedPollMs,
      );
}
