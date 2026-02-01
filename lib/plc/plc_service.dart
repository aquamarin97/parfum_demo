import 'dart:async';

class PLCService {
  // 1.5 - Önerileri PLC'ye gönder
  static Future<void> sendRecommendations(List<int> perfumeIds) async {
    // PLC'ye veri gönderme simülasyonu
    print('DEBUG: PLC\'ye gönderilen ID\'ler: $perfumeIds');
    await Future.delayed(const Duration(milliseconds: 500));
    return;
  }

  // 2.5 - Testerlar hazır mı?
  static Stream<bool> get onTestersReady {
    // 2 saniye sonra hazır sinyali gönderir
    return Stream.value(true).delay(const Duration(seconds: 2));
  }

  // 7.5 - Ödeme tamamlandı mı?
  static Stream<bool> get onPaymentComplete {
    // 3 saniye bekleyip ödeme yapıldı sinyali gönderir
    return Stream.value(true).delay(const Duration(seconds: 3));
  }

  // Ödeme kontrolü (Önceki yaptığımız)
  static Future<bool> checkPaymentStatus() async {
    await Future.delayed(const Duration(seconds: 1));
    return true; 
  }

  // 8.5 - Parfüm hazır mı?
  static Stream<bool> get onPerfumeReady {
    // Dolum işleminin 4 saniye sürdüğünü simüle eder
    return Stream.value(true).delay(const Duration(seconds: 4));
  }
}

// Stream üzerinde .delay kullanabilmek için küçük bir yardımcı eklenti
extension StreamDelay<T> on Stream<T> {
  Stream<T> delay(Duration duration) {
    return asyncMap((event) async {
      await Future.delayed(duration);
      return event;
    });
  }
}