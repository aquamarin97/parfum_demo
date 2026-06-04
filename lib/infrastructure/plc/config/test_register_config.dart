// FAZE 1.1 TEST CHECKLIST
// 
// Bu dosyayı main.dart'ın başına ekleyerek test edebilirsiniz

import 'package:flutter/material.dart';
import 'package:parfume_app/infrastructure/plc/config/register_loader.dart';

/// Test fonksiyonu - main() içinde çağırın
Future<void> testRegisterConfig() async {
  debugPrint('\n🧪 FAZE 1.1 TEST BAŞLIYOR...\n');

  final loader = RegisterLoader();

  // ============================================================================
  // TEST 1: Config yükleme
  // ============================================================================
  debugPrint('📋 TEST 1: Config Yükleme');
  try {
    final config = await loader.load();
    debugPrint('✅ Config başarıyla yüklendi');
    debugPrint('   Version: ${config.version}');
    debugPrint('   Host: ${config.connection.host}:${config.connection.port}');
  } catch (e) {
    debugPrint('❌ HATA: $e');
    return;
  }

  // ============================================================================
  // TEST 2: Register adreslerine erişim
  // ============================================================================
  debugPrint('\n📋 TEST 2: Register Adresleri');
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
      debugPrint('✅ $path → Register $address');
    } catch (e) {
      debugPrint('❌ $path → HATA: $e');
    }
  }

  // ============================================================================
  // TEST 3: Değer açıklamaları
  // ============================================================================
  debugPrint('\n📋 TEST 3: Değer Açıklamaları');
  
  final paymentGroup = config.registers.getGroup('payment')!;
  debugPrint('Payment Status değerleri:');
  for (int i = 0; i <= 4; i++) {
    final desc = paymentGroup.getValueDescription('status', i);
    debugPrint('  $i → ${desc ?? "Tanımsız"}');
  }

  // ============================================================================
  // TEST 4: Validation
  // ============================================================================
  debugPrint('\n📋 TEST 4: Validation');
  
  final recGroup = config.registers.getGroup('recommendations')!;
  final testValues = [0, 1, 500, 999, 1000];
  
  for (final value in testValues) {
    final isValid = recGroup.validateValue(value);
    debugPrint('  Değer $value → ${isValid ? "✅ Geçerli" : "❌ Geçersiz"}');
  }

  // ============================================================================
  // TEST 5: Workflow paths
  // ============================================================================
  debugPrint('\n📋 TEST 5: Workflow Paths');
  
  config.workflows.forEach((name, steps) {
    debugPrint('Workflow: $name');
    for (final step in steps) {
      try {
        final address = config.getAddress(step);
        debugPrint('  ✅ $step (R$address)');
      } catch (e) {
        debugPrint('  ❌ $step → HATA');
      }
    }
  });

  // ============================================================================
  // TEST 6: Config info
  // ============================================================================
  debugPrint('\n📋 TEST 6: Config Info\n');
  loader.printConfigInfo();

  // ============================================================================
  // TEST 7: Export (debug)
  // ============================================================================
  debugPrint('\n📋 TEST 7: Export All Registers');
  final exported = loader.exportAllRegisters();
  debugPrint('✅ ${exported.length} register export edildi');
  debugPrint('İlk 5 register:');
  exported.entries.take(5).forEach((e) {
    debugPrint('  • ${e.key}: ${e.value}');
  });

  debugPrint('\n✅ TÜM TESTLER TAMAMLANDI!\n');
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