// test/plc_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:parfume_app/plc/error/plc_error_codes.dart';
import 'package:parfume_app/plc/modbus_plc_client.dart';
import 'package:parfume_app/plc/plc_service_manager.dart';


/// PLC Modbus entegrasyonu için test dosyası
/// 
/// Bu testler için ModRSsim2'nin çalışıyor olması gerekir:
/// - IP: 127.0.0.1
/// - Port: 502
/// - Protocol: Modbus TCP

void main() {
  group('PLC Connection Tests', () {
    late ModbusPLCClient client;

    setUp(() {
      client = ModbusPLCClient(
        host: '127.0.0.1',
        port: 502,
      );
    });

    tearDown(() async {
      await client.disconnect();
    });

    test('Should connect to PLC successfully', () async {
      // ModRSsim2 çalışıyor olmalı
      await client.connect();
      expect(client.isConnected, true);
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('Should throw error when PLC is not available', () async {
      // Farklı bir port kullan (PLC yok)
      final badClient = ModbusPLCClient(
        host: '127.0.0.1',
        port: 9999,
      );

      expect(
        () => badClient.connect(),
        throwsA(isA<PLCException>()),
      );
    });

    test('Should send recommendations successfully', () async {
      await client.connect();
      
      final recommendations = [101, 202, 303];
      await client.sendRecommendation(recommendations);
      
      // ModRSsim2'de Register 0, 1, 2 değerlerini kontrol edin
      final reg0 = await client.readRegister(0);
      final reg1 = await client.readRegister(1);
      final reg2 = await client.readRegister(2);
      
      expect(reg0, 101);
      expect(reg1, 202);
      expect(reg2, 303);
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('Should read tester ready status', () async {
      await client.connect();
      
      // ModRSsim2'de Register 10'u 1 yapın
      await client.writeRegister(10, 1);
      
      final ready = await client.checkTestersReady();
      expect(ready, true);
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('Should watch payment status stream', () async {
      await client.connect();
      
      // ModRSsim2'de Register 20'yi 0 olarak başlat
      await client.writeRegister(20, 0);
      
      // 3 saniye sonra 1 yap (test için)
      Future.delayed(const Duration(seconds: 3), () async {
        await client.writeRegister(20, 1);
      });
      
      // Stream'i izle
      final statusStream = client.watchPaymentStatus();
      final status = await statusStream.first;
      
      expect(status, 1); // Payment complete
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('PLC Service Manager Tests', () {
    late PLCServiceManager service;

    setUp(() {
      service = PLCServiceManager(
        autoConnect: false,
      );
    });

    tearDown(() async {
      await service.disconnect();
      service.dispose();
    });

    test('Should initialize and connect', () async {
      await service.initialize();
      expect(service.isConnected, true);
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('Should handle connection error gracefully', () async {
      // Bad host ile servis oluştur
      final badService = PLCServiceManager(
        client: ModbusPLCClient(host: '192.168.999.999', port: 502),
        autoConnect: false,
      );

      await badService.initialize();
      
      expect(badService.hasError, true);
      expect(badService.lastError, isNotNull);
      expect(badService.lastError!.errorCode, PLCErrorCodes.connectionFailed);
      
      badService.dispose();
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('Should send recommendations through service', () async {
      await service.initialize();
      
      final recommendations = [111, 222, 333];
      await service.sendRecommendations(recommendations);
      
      // Başarılı gönderim kontrolü
      expect(service.isConnected, true);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('Error Code Tests', () {
    test('Should return correct error messages for Turkish', () {
      final message = PLCErrorCodes.getErrorMessage(
        PLCErrorCodes.connectionFailed,
        'tr',
      );
      expect(message, contains('bağlantı'));
    });

    test('Should return correct error messages for English', () {
      final message = PLCErrorCodes.getErrorMessage(
        PLCErrorCodes.connectionFailed,
        'en',
      );
      expect(message, contains('connect'));
    });

    test('Should return technical descriptions', () {
      final description = PLCErrorCodes.getTechnicalDescription(
        PLCErrorCodes.connectionFailed,
      );
      expect(description, isNotEmpty);
      expect(description, contains('TCP/IP'));
    });
  });
}

/// Manuel Test Senaryoları
/// 
/// Bu testleri manuel olarak çalıştırın:
/// 
/// 1. NORMAL FLOW TEST:
///    - ModRSsim2'yi başlatın
///    - flutter test test/plc_integration_test.dart
///    - Tüm testler geçmeli
/// 
/// 2. CONNECTION ERROR TEST:
///    - ModRSsim2'yi kapatın
///    - Uygulamayı çalıştırın
///    - Error 401 görmeli
/// 
/// 3. TIMEOUT TEST:
///    - ModRSsim2'de yavaş response simüle edin
///    - Timeout error görmeli
/// 
/// 4. REAL-TIME TEST:
///    - Uygulamayı çalıştırın
///    - ModRSsim2'de register değerlerini manuel değiştirin
///    - Uygulama gerçek zamanlı güncellenmeli
