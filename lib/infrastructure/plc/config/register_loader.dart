// register_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'register_config.dart';

/// PLC Register konfigürasyonunu yükler ve cache'ler
/// 
/// Kullanım:
/// ```dart
/// final loader = RegisterLoader();
/// final config = await loader.load();
/// final address = config.getAddress('recommendations.first');
/// ```
class RegisterLoader {
  RegisterLoader({
    this.configPath = 'assets/config/plc_registers.json',
  });

  final String configPath;
  PLCRegisterConfig? _cachedConfig;
  DateTime? _lastLoadTime;

  /// Konfigürasyonu yükle (ilk yüklemede cache'e al)
  Future<PLCRegisterConfig> load({bool forceReload = false}) async {
    // Cache varsa ve force reload değilse, cache'den dön
    if (!forceReload && _cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      print('[RegisterLoader] Loading config from: $configPath');
      
      // JSON dosyasını oku
      final jsonString = await rootBundle.loadString(configPath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Parse et
      final config = PLCRegisterConfig.fromJson(jsonData);

      // Validate et
      _validateConfig(config);

      // Cache'e al
      _cachedConfig = config;
      _lastLoadTime = DateTime.now();

      print('[RegisterLoader] ✓ Config loaded: v${config.version}');
      print('[RegisterLoader] ✓ Total registers: ${_getTotalRegisterCount(config)}');
      
      return config;
    } catch (e) {
      print('[RegisterLoader] ✗ Config load failed: $e');
      rethrow;
    }
  }

  /// Cache'lenmiş config'i al (yüklenmemişse null)
  PLCRegisterConfig? get cachedConfig => _cachedConfig;

  /// Config yüklü mü?
  bool get isLoaded => _cachedConfig != null;

  /// Son yükleme zamanı
  DateTime? get lastLoadTime => _lastLoadTime;

  /// Cache'i temizle
  void clearCache() {
    _cachedConfig = null;
    _lastLoadTime = null;
    print('[RegisterLoader] Cache cleared');
  }

  /// Config'i validate et
  void _validateConfig(PLCRegisterConfig config) {
    // Version kontrolü
    if (config.version.isEmpty) {
      throw FormatException('Config version boş olamaz');
    }

    // Connection kontrolü
    if (config.connection.host.isEmpty) {
      throw FormatException('PLC host adresi boş olamaz');
    }

    if (config.connection.port <= 0 || config.connection.port > 65535) {
      throw FormatException('Geçersiz port: ${config.connection.port}');
    }

    // Register kontrolü
    if (config.registers.groups.isEmpty) {
      throw FormatException('En az bir register grubu tanımlanmalı');
    }

    // Required register'ları kontrol et
    for (final path in config.validation.requiredRegisters) {
      try {
        config.getAddress(path);
      } catch (e) {
        throw FormatException('Required register bulunamadı: $path');
      }
    }

    // Adres çakışmalarını kontrol et
    _checkAddressConflicts(config);

    print('[RegisterLoader] ✓ Config validation passed');
  }

  /// Register adres çakışmalarını kontrol et
  void _checkAddressConflicts(PLCRegisterConfig config) {
    final usedAddresses = <int, String>{};
    
    for (final group in config.registers.groups.values) {
      for (final entry in group.addresses.entries) {
        final address = entry.value;
        final name = entry.key;
        final fullPath = '${group.name}.$name';

        if (usedAddresses.containsKey(address)) {
          throw FormatException(
            'Adres çakışması: $fullPath ve ${usedAddresses[address]} '
            'aynı adresi kullanıyor: $address',
          );
        }

        usedAddresses[address] = fullPath;
      }
    }
  }

  /// Toplam register sayısını hesapla
  int _getTotalRegisterCount(PLCRegisterConfig config) {
    return config.registers.groups.values
        .map((g) => g.addresses.length)
        .fold(0, (a, b) => a + b);
  }

  /// Config bilgilerini pretty print et
  void printConfigInfo() {
    if (_cachedConfig == null) {
      print('[RegisterLoader] Config yüklenmemiş');
      return;
    }

    final config = _cachedConfig!;
    
    print('═══════════════════════════════════════════');
    print('PLC REGISTER CONFIG INFO');
    print('═══════════════════════════════════════════');
    print('Version: ${config.version}');
    print('Description: ${config.description}');
    print('Connection: ${config.connection.host}:${config.connection.port}');
    print('───────────────────────────────────────────');
    print('Register Groups:');
    
    for (final group in config.registers.groups.values) {
      print('  • ${group.name}: ${group.addresses.length} registers');
      print('    Type: ${group.type.toJson()}');
      print('    Range: ${_getAddressRange(group)}');
    }
    
    print('───────────────────────────────────────────');
    print('Workflows: ${config.workflows.length}');
    config.workflows.forEach((name, steps) {
      print('  • $name: ${steps.length} steps');
    });
    
    print('───────────────────────────────────────────');
    print('Validation:');
    print('  Required: ${config.validation.requiredRegisters.length}');
    print('  Critical Errors: ${config.validation.criticalErrors.length}');
    print('═══════════════════════════════════════════');
  }

  String _getAddressRange(RegisterGroup group) {
    if (group.addresses.isEmpty) return 'N/A';
    
    final addresses = group.addresses.values.toList()..sort();
    final min = addresses.first;
    final max = addresses.last;
    
    return min == max ? '$min' : '$min-$max';
  }

  /// Tüm register'ları export et (debug için)
  Map<String, dynamic> exportAllRegisters() {
    if (_cachedConfig == null) {
      throw StateError('Config yüklenmemiş');
    }

    final result = <String, dynamic>{};
    final allAddresses = _cachedConfig!.registers.getAllAddresses();

    for (final reg in allAddresses) {
      result[reg.fullPath] = {
        'address': reg.address,
        'type': reg.type.toJson(),
        'group': reg.group,
        'description': reg.description,
      };
    }

    return result;
  }
}