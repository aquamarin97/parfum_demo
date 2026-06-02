/// PLC donanımıyla iletişim kuran client'ların uyması gereken sözleşme.
///
/// Somut implementasyonlar (ör. [ModbusPLCClient]) bu interface'i implement
/// eder. Test ortamında mock implementasyonlar kolayca yazılabilir.
abstract interface class IPlcClient {
  /// PLC'ye bağlantı kurar.
  ///
  /// Bağlantı zaten kuruluysa işlem tekrarlanmaz.
  /// Throws [PLCException] bağlantı kurulamazsa.
  Future<void> connect();

  /// Mevcut PLC bağlantısını kapatır.
  ///
  /// Bağlantı zaten kapalıysa sessizce tamamlanır.
  Future<void> disconnect();

  /// Parfüm önerilerini PLC register'larına yazar.
  ///
  /// [ids] en az 3 elemanlı olmalıdır; sırasıyla birinci, ikinci ve
  /// üçüncü öneri register'larına yazılır.
  ///
  /// Throws [PLCException] yazma işlemi başarısız olursa.
  Future<void> sendRecommendation(List<int> ids);

  /// Kullanıcının seçtiği tester numarasını PLC'ye gönderir.
  ///
  /// [testerNumber] 1–3 arasında olmalıdır.
  ///
  /// Throws [PLCException] geçersiz numara veya yazma hatası durumunda.
  Future<void> sendSelectedTester(int testerNumber);

  /// Testerların fiziksel olarak hazır olup olmadığını sorgular.
  ///
  /// Returns `true` tüm testerlar hazırsa, `false` henüz hazır değilse.
  /// Throws [PLCException] okuma hatası durumunda.
  Future<bool> checkTestersReady();

  /// Ödeme register'ının anlık değerini döner.
  ///
  /// Returns `0` ödeme bekleniyor, `1` ödeme tamamlandı, `2` ödeme hatası.
  /// Throws [PLCException] okuma hatası durumunda.
  Future<int> checkPaymentStatus();

  /// Parfüm dispenserının hazır olup olmadığını sorgular.
  ///
  /// Returns `true` parfüm dispenseri hazırsa, `false` henüz hazır değilse.
  /// Throws [PLCException] okuma hatası durumunda.
  Future<bool> checkPerfumeReady();

  /// Testerlar hazır olana kadar periyodik olarak sorgulayan stream.
  ///
  /// `true` emit edildiğinde stream tamamlanır.
  /// Throws [PLCException] bağlantı kesilirse.
  Stream<bool> watchTestersReady();

  /// Ödeme durumu değiştiğinde yeni değeri emit eden stream.
  ///
  /// `0` dışında bir değer emit edildiğinde stream tamamlanır.
  /// Throws [PLCException] bağlantı kesilirse.
  Stream<int> watchPaymentStatus();

  /// Parfüm dispenseri hazır olana kadar periyodik olarak sorgulayan stream.
  ///
  /// `true` emit edildiğinde stream tamamlanır.
  /// Throws [PLCException] bağlantı kesilirse.
  Stream<bool> watchPerfumeReady();

  /// PLC bağlantısının aktif olup olmadığını döner.
  bool get isConnected;

  /// PLC'ye heartbeat register okuyarak sağlık kontrolü yapar.
  ///
  /// Returns `true` bağlantı sağlıklıysa, `false` bağlantı kopuksa.
  Future<bool> healthCheck();
}