# 🔌 PLC Modbus Entegrasyonu - Kullanım Rehberi

## 📋 Genel Bakış

Bu entegrasyon, Flutter parfüm kiosk uygulamasının Modbus TCP protokolü üzerinden PLC ile iletişim kurmasını sağlar.

### Özellikler
- ✅ Modbus TCP bağlantı yönetimi
- ✅ Otomatik yeniden bağlanma
- ✅ Detaylı hata yönetimi (error codes)
- ✅ Health check ve watchdog
- ✅ Stream-based real-time monitoring
- ✅ ModRSsim2 simülatör desteği

## 🏗️ Mimari

```
┌─────────────────┐
│  Flutter App    │
│  (Kiosk UI)     │
└────────┬────────┘
         │
         ├─ PLCServiceManager (Bağlantı Yönetimi)
         │
         └─ ModbusPLCClient (Modbus TCP)
                  │
                  ├─ ModRSsim2 (Test)
                  └─ Gerçek PLC (Production)
```

## 📦 Gerekli Paketler

`pubspec.yaml` dosyanıza ekleyin:

```yaml
dependencies:
  modbus: ^0.1.0
  provider: ^6.1.2  # Zaten var
```

## 📁 Dosya Yapısı

Projenize şu dosyaları ekleyin:

```
lib/
├── core/
│   └── errors/
│       └── plc_error_codes.dart          # Hata kodları ve mesajlar
├── plc/
│   ├── plc_client.dart                   # Interface (mevcut)
│   └── modbus_plc_client.dart            # Modbus implementasyonu
├── services/
│   └── plc_service_manager.dart          # Bağlantı yöneticisi
└── ui/
    └── screens/
        ├── plc_error_screen.dart         # Hata ekranı
        └── result/
            └── result_view_model_with_plc.dart  # PLC-enabled ViewModel
```

## 🚀 Kurulum Adımları

### 1. Dosyaları Projeye Ekleyin

```bash
# Core errors
mkdir -p lib/core/errors
cp plc_error_codes.dart lib/core/errors/

# PLC client
cp modbus_plc_client.dart lib/plc/

# Services
mkdir -p lib/services
cp plc_service_manager.dart lib/services/

# UI screens
cp plc_error_screen.dart lib/ui/screens/
cp result_view_model_with_plc.dart lib/ui/screens/result/
```

### 2. AppViewModel'i Güncelleyin

`lib/viewmodel/app_view_model.dart` dosyasına PLC servisini ekleyin:

```dart
import '../services/plc_service_manager.dart';
import '../core/errors/plc_error_codes.dart';

class AppViewModel extends ChangeNotifier {
  // Mevcut alanlar...
  
  late final PLCServiceManager _plcService;
  
  AppViewModel({
    // Mevcut parametreler...
  }) : _stateMachine = AppStateMachine() {
    _initializePLC();
  }
  
  Future<void> _initializePLC() async {
    _plcService = PLCServiceManager(
      autoConnect: true,
      onError: _handlePLCError,
    );
  }
  
  void _handlePLCError(PLCException error) {
    _logger.log('PLC Error: ${error.errorCode} - ${error.message}');
    
    // Critical error'larda error state'e geç
    if (error.errorCode == PLCErrorCodes.connectionFailed ||
        error.errorCode == PLCErrorCodes.connectionLost) {
      _setState(PLCErrorState(error));
    }
  }
  
  PLCServiceManager get plcService => _plcService;
}
```

### 3. AppState'e PLC Error State Ekleyin

`lib/domain/state/app_state.dart`:

```dart
class PLCErrorState extends AppState {
  const PLCErrorState(this.exception);
  final PLCException exception;
}
```

### 4. AppRouter'ı Güncelleyin

`lib/ui/navigation/app_router.dart`:

```dart
import '../screens/plc_error_screen.dart';

Widget build(AppViewModel viewModel) {
  final state = viewModel.state;
  
  // Mevcut state kontrolleri...
  
  if (state is PLCErrorState) {
    return PLCErrorScreen(
      viewModel: viewModel,
      errorCode: state.exception.errorCode,
      errorMessage: state.exception.getUserMessage(
        viewModel.language.code,
      ),
      technicalDetail: state.exception.technicalDetail,
      onRetry: () async {
        await viewModel.plcService.reconnect();
        if (viewModel.plcService.isConnected) {
          viewModel.resetToIdle();
        }
      },
    );
  }
  
  // ...
}
```

### 5. ResultScreen'i Güncelleyin

`lib/ui/screens/result/result_screen.dart`:

```dart
import 'result_view_model_with_plc.dart';

@override
Widget build(BuildContext context) {
  return ChangeNotifierProvider(
    create: (_) => ResultViewModelWithPLC(
      appViewModel: widget.viewModel,
      plcService: widget.viewModel.plcService,  // PLC service'i inject et
    ),
    child: Consumer<ResultViewModelWithPLC>(
      builder: (context, viewModel, _) {
        // Mevcut kod...
      },
    ),
  );
}
```

## 🧪 Test Etme

### ModRSsim2 ile Test

1. **ModRSsim2'yi başlatın**:
   ```
   - Connection → Modbus Settings
   - Protocol: Modbus TCP
   - Port: 502
   - IP: 127.0.0.1
   - Start Server
   ```

2. **Flutter uygulamasını çalıştırın**:
   ```bash
   flutter run
   ```

3. **Register'ları izleyin**:
   ```
   Window → Register View
   Type: Holding Registers
   Start: 0, Count: 101
   ```

4. **Manuel test**:
   - Register 10 = 1 → Testerlar hazır
   - Register 20 = 1 → Ödeme tamam
   - Register 30 = 1 → Parfüm hazır

### Hata Senaryolarını Test Etme

**Bağlantı Hatası (401)**:
```bash
# ModRSsim2'yi kapatın
# Uygulamayı başlatın
# Beklenen: PLC Error Screen (401)
```

**Bağlantı Kopması (403)**:
```bash
# Normal çalışırken ModRSsim2'yi kapatın
# Beklenen: 10 saniye içinde error (403)
```

## 🔧 Konfigürasyon

### Development (ModRSsim2)

`lib/plc/modbus_plc_client.dart`:
```dart
ModbusPLCClient({
  this.host = '127.0.0.1',
  this.port = 502,
  this.connectionTimeout = const Duration(seconds: 3),
  this.responseTimeout = const Duration(seconds: 2),
});
```

### Production (Gerçek PLC)

```dart
ModbusPLCClient({
  this.host = '192.168.1.100',  // Gerçek PLC IP
  this.port = 502,
  this.connectionTimeout = const Duration(seconds: 5),
  this.responseTimeout = const Duration(seconds: 3),
  this.reconnectAttempts = 5,
});
```

## 📊 Register Haritası

| Register | Açıklama | Tip | Değerler |
|----------|----------|-----|----------|
| 0 | İlk öneri ID | R/W | 1-999 |
| 1 | İkinci öneri ID | R/W | 1-999 |
| 2 | Üçüncü öneri ID | R/W | 1-999 |
| 10 | Tester hazır | R | 0=Hayır, 1=Evet |
| 11 | Seçilen tester | R/W | 1-3 |
| 20 | Ödeme durumu | R | 0=Bekliyor, 1=Tamam, 2=Hata |
| 30 | Parfüm hazır | R | 0=Hayır, 1=Evet |
| 100 | Heartbeat | R | Herhangi |

## 🐛 Hata Kodları

| Kod | Açıklama | Çözüm |
|-----|----------|-------|
| 401 | Bağlantı kurulamadı | IP/Port kontrol edin |
| 402 | Connection timeout | Network gecikmesi |
| 403 | Bağlantı kesildi | PLC gücünü kontrol edin |
| 410 | Read hatası | Register adresi |
| 411 | Write hatası | Write izni |
| 420 | PLC hazır değil | PLC modunu kontrol edin |

## 📝 Logging

Konsol logları:
```
[PLCService] PLC bağlantısı başlatılıyor...
[ModbusPLC] Bağlantı kuruluyor: 127.0.0.1:502
[ModbusPLC] ✓ Bağlantı başarılı
[PLCService] Öneriler gönderiliyor: [101, 202, 303]
[ModbusPLC] ✓ Öneriler başarıyla gönderildi
```

## 🚨 Önemli Notlar

1. **Port 502**: Modbus TCP standart portu. Root/admin yetkisi gerektirebilir
2. **Firewall**: Windows Defender veya antivirus engelleyebilir
3. **Network**: PLC aynı network'te olmalı
4. **Timeout**: PLC yanıt süresine göre ayarlayın
5. **Error Handling**: Tüm PLC işlemlerinde try-catch kullanın

## 📚 Kaynaklar

- [Modbus Protocol](https://www.modbus.org/)
- [ModRSsim2 Download](https://sourceforge.net/projects/modrssim2/)
- [Flutter Modbus Package](https://pub.dev/packages/modbus)

## 🤝 Destek

Sorun yaşarsanız:
1. ModRSsim2 loglarını kontrol edin
2. Flutter console'u inceleyin
3. Network trafiğini izleyin (Wireshark)
4. Register adreslerini doğrulayın