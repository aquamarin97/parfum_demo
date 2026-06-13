// Register Config v1.0 — Test Checklist
// Çalıştırmak için main.dart'a geçici olarak ekleyin:
//   await testRegisterConfig();

import 'package:flutter/material.dart';
import 'package:parfume_app/infrastructure/plc/config/register_loader.dart';

Future<void> testRegisterConfig() async {
  debugPrint('\n🧪 REGISTER CONFIG v1.0 TEST BAŞLIYOR...\n');

  final loader = RegisterLoader();

  // ============================================================
  // TEST 1: Config yükleme
  // ============================================================
  debugPrint('📋 TEST 1: Config Yükleme');
  try {
    final config = await loader.load();
    debugPrint('✅ Config yüklendi v${config.version}');
    debugPrint('   Host: ${config.connection.host}:${config.connection.port}');
    debugPrint('   Toplam register: ${config.registers.getAllAddresses().length}');
  } catch (e) {
    debugPrint('❌ Config yüklenemedi: $e');
    return;
  }

  final config = loader.cachedConfig!;

  // ============================================================
  // TEST 2: Blok 1 — Komutlar (100–102)
  // ============================================================
  debugPrint('\n📋 TEST 2: Blok 1 — Komutlar');
  _testPath(config, 'commands.action',      expectedAddress: 100);
  _testPath(config, 'commands.slot',        expectedAddress: 101);
  _testPath(config, 'commands.sequence_id', expectedAddress: 102);

  // ============================================================
  // TEST 3: Blok 2 — Sistem Durumu (200–203)
  // ============================================================
  debugPrint('\n📋 TEST 3: Blok 2 — Sistem Durumu');
  _testPath(config, 'system_status.system',          expectedAddress: 200);
  _testPath(config, 'system_status.last_cmd_seq_id', expectedAddress: 201);
  _testPath(config, 'system_status.last_cmd_result', expectedAddress: 202);
  _testPath(config, 'system_status.active_slot',     expectedAddress: 203);

  // ============================================================
  // TEST 4: Blok 3 — Ödeme (300–303)
  // ============================================================
  debugPrint('\n📋 TEST 4: Blok 3 — Ödeme');
  _testPath(config, 'payment.status',        expectedAddress: 300);
  _testPath(config, 'payment.amount',        expectedAddress: 301);
  _testPath(config, 'payment.confirmed_ack', expectedAddress: 302);
  _testPath(config, 'payment.sale_completed',expectedAddress: 303);

  // ============================================================
  // TEST 5: Blok 4 — Sensörler (400–424)
  // ============================================================
  debugPrint('\n📋 TEST 5: Blok 4 — Sensörler');
  _testPath(config, 'sensors.presence', expectedAddress: 400);
  _testPath(config, 'sensors.stock_1',  expectedAddress: 401);
  _testPath(config, 'sensors.stock_24', expectedAddress: 424);

  // ============================================================
  // TEST 6: Blok 5 — Hata (500–501)
  // ============================================================
  debugPrint('\n📋 TEST 6: Blok 5 — Hata');
  _testPath(config, 'errors.error_code', expectedAddress: 500);
  _testPath(config, 'errors.error_slot', expectedAddress: 501);

  // ============================================================
  // TEST 7: Blok 6 — Heartbeat (600–601)
  // ============================================================
  debugPrint('\n📋 TEST 7: Blok 6 — Heartbeat');
  _testPath(config, 'heartbeat.plc_heartbeat',     expectedAddress: 600);
  _testPath(config, 'heartbeat.flutter_heartbeat', expectedAddress: 601);

  // ============================================================
  // TEST 8: Değer açıklamaları
  // ============================================================
  debugPrint('\n📋 TEST 8: Değer Açıklamaları');

  final cmdGroup = config.registers.getGroup('commands')!;
  debugPrint('CMD_ACTION değerleri:');
  for (int i = 0; i <= 4; i++) {
    final desc = cmdGroup.getValueDescription('action', i);
    debugPrint('  $i → ${desc ?? "Tanımsız"}');
  }

  final statusGroup = config.registers.getGroup('system_status')!;
  debugPrint('STATUS_SYSTEM değerleri:');
  for (int i = 0; i <= 2; i++) {
    final desc = statusGroup.getValueDescription('system', i);
    debugPrint('  $i → ${desc ?? "Tanımsız"}');
  }

  final paymentGroup = config.registers.getGroup('payment')!;
  debugPrint('PAYMENT_STATUS değerleri:');
  for (int i = 0; i <= 3; i++) {
    final desc = paymentGroup.getValueDescription('status', i);
    debugPrint('  $i → ${desc ?? "Tanımsız"}');
  }

  final errorGroup = config.registers.getGroup('errors')!;
  debugPrint('ERROR_CODE değerleri:');
  for (int i = 0; i <= 6; i++) {
    final desc = errorGroup.getValueDescription('error_code', i);
    debugPrint('  $i → ${desc ?? "Tanımsız"}');
  }

  // ============================================================
  // TEST 9: Workflow paths
  // ============================================================
  debugPrint('\n📋 TEST 9: Workflow Paths');
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

  debugPrint('\n✅ TÜM TESTLER TAMAMLANDI!\n');
}

void _testPath(dynamic config, String path, {required int expectedAddress}) {
  try {
    final address = config.getAddress(path);
    final ok = address == expectedAddress;
    debugPrint(
      '${ok ? "✅" : "⚠"} $path → R$address${ok ? "" : " (beklenen: R$expectedAddress)"}',
    );
  } catch (e) {
    debugPrint('❌ $path → HATA: $e');
  }
}
