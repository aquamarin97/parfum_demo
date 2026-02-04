// FAZE 1.1 TEST CHECKLIST
// 
// Bu dosyayı main.dart'ın başına ekleyerek test edebilirsiniz

import 'package:flutter/material.dart';
import 'package:parfume_app/plc/config/register_loader.dart';

/// Test fonksiyonu - main() içinde çağırın
Future<void> testRegisterConfig() async {
  print('\n🧪 FAZE 1.1 TEST BAŞLIYOR...\n');

  final loader = RegisterLoader();

  // ============================================================================
  // TEST 1: Config yükleme
  // ============================================================================
  print('📋 TEST 1: Config Yükleme');
  try {
    final config = await loader.load();
    print('✅ Config başarıyla yüklendi');
    print('   Version: ${config.version}');
    print('   Host: ${config.connection.host}:${config.connection.port}');
  } catch (e) {
    print('❌ HATA: $e');
    return;
  }

  // ============================================================================
  // TEST 2: Register adreslerine erişim
  // ============================================================================
  print('\n📋 TEST 2: Register Adresleri');
  final config = loader.cachedConfig!;
  
  final testPaths = [
    'recommendations.first',
    'recommendations.second',
    'recommendations.third',
    'tester_control.testers_ready',
    'tester_control.selected_tester',
    'payment.status',
    'perfume_dispenser.ready',
    'system.heartbeat',
  ];

  for (final path in testPaths) {
    try {
      final address = config.getAddress(path);
      print('✅ $path → Register $address');
    } catch (e) {
      print('❌ $path → HATA: $e');
    }
  }

  // ============================================================================
  // TEST 3: Değer açıklamaları
  // ============================================================================
  print('\n📋 TEST 3: Değer Açıklamaları');
  
  final paymentGroup = config.registers.getGroup('payment')!;
  print('Payment Status değerleri:');
  for (int i = 0; i <= 4; i++) {
    final desc = paymentGroup.getValueDescription('status', i);
    print('  $i → ${desc ?? "Tanımsız"}');
  }

  // ============================================================================
  // TEST 4: Validation
  // ============================================================================
  print('\n📋 TEST 4: Validation');
  
  final recGroup = config.registers.getGroup('recommendations')!;
  final testValues = [0, 1, 500, 999, 1000];
  
  for (final value in testValues) {
    final isValid = recGroup.validateValue(value);
    print('  Değer $value → ${isValid ? "✅ Geçerli" : "❌ Geçersiz"}');
  }

  // ============================================================================
  // TEST 5: Workflow paths
  // ============================================================================
  print('\n📋 TEST 5: Workflow Paths');
  
  config.workflows.forEach((name, steps) {
    print('Workflow: $name');
    for (final step in steps) {
      try {
        final address = config.getAddress(step);
        print('  ✅ $step (R$address)');
      } catch (e) {
        print('  ❌ $step → HATA');
      }
    }
  });

  // ============================================================================
  // TEST 6: Config info
  // ============================================================================
  print('\n📋 TEST 6: Config Info\n');
  loader.printConfigInfo();

  // ============================================================================
  // TEST 7: Export (debug)
  // ============================================================================
  print('\n📋 TEST 7: Export All Registers');
  final exported = loader.exportAllRegisters();
  print('✅ ${exported.length} register export edildi');
  print('İlk 5 register:');
  exported.entries.take(5).forEach((e) {
    print('  • ${e.key}: ${e.value}');
  });

  print('\n✅ TÜM TESTLER TAMAMLANDI!\n');
}

// ============================================================================
// KULLANIM ÖRNEĞİ - main.dart
// ============================================================================
/*

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Test et
  await testRegisterConfig();
  
  // Normal uygulama devam eder
  runApp(MyApp());
}

*/