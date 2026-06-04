// register_loader.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'register_config.dart';

/// Loads and caches the PLC register configuration from the asset bundle.
///
/// The configuration is parsed once and cached; subsequent calls to [load]
/// return the cached value unless [forceReload] is `true`.
///
/// Example:
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

  /// Loads the configuration, caching it after the first successful load.
  Future<PLCRegisterConfig> load({bool forceReload = false}) async {
    // Return cached config unless a reload is forced.
    if (!forceReload && _cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      debugPrint('[RegisterLoader] Loading config from: $configPath');

      // Read JSON asset.
      final jsonString = await rootBundle.loadString(configPath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Parse.
      final config = PLCRegisterConfig.fromJson(jsonData);

      // Validate.
      _validateConfig(config);

      // Cache.
      _cachedConfig = config;
      _lastLoadTime = DateTime.now();

      debugPrint('[RegisterLoader] ✓ Config loaded: v${config.version}');
      debugPrint('[RegisterLoader] ✓ Total registers: ${_getTotalRegisterCount(config)}');

      return config;
    } catch (e) {
      debugPrint('[RegisterLoader] ✗ Config load failed: $e');
      rethrow;
    }
  }

  /// The cached configuration, or `null` if [load] has not been called yet.
  PLCRegisterConfig? get cachedConfig => _cachedConfig;

  /// Whether the configuration has been loaded successfully.
  bool get isLoaded => _cachedConfig != null;

  /// The timestamp of the last successful [load] call.
  DateTime? get lastLoadTime => _lastLoadTime;

  /// Clears the cached configuration, forcing the next [load] call to reload.
  void clearCache() {
    _cachedConfig = null;
    _lastLoadTime = null;
    debugPrint('[RegisterLoader] Cache cleared');
  }

  /// Validates [config] and throws [FormatException] on any violation.
  void _validateConfig(PLCRegisterConfig config) {
    // Version check.
    if (config.version.isEmpty) {
      throw FormatException('Config version must not be empty');
    }

    // Connection check.
    if (config.connection.host.isEmpty) {
      throw FormatException('PLC host must not be empty');
    }

    if (config.connection.port <= 0 || config.connection.port > 65535) {
      throw FormatException('Invalid port: ${config.connection.port}');
    }

    // Register check.
    if (config.registers.groups.isEmpty) {
      throw FormatException('At least one register group must be defined');
    }

    // Required register check.
    for (final path in config.validation.requiredRegisters) {
      try {
        config.getAddress(path);
      } catch (e) {
        throw FormatException('Required register not found: $path');
      }
    }

    // Address conflict check.
    _checkAddressConflicts(config);

    debugPrint('[RegisterLoader] ✓ Config validation passed');
  }

  /// Checks for duplicate register addresses across all groups.
  void _checkAddressConflicts(PLCRegisterConfig config) {
    final usedAddresses = <int, String>{};

    for (final group in config.registers.groups.values) {
      for (final entry in group.addresses.entries) {
        final address = entry.value;
        final name = entry.key;
        final fullPath = '${group.name}.$name';

        if (usedAddresses.containsKey(address)) {
          throw FormatException(
            'Address conflict: $fullPath and ${usedAddresses[address]} '
            'share address $address',
          );
        }

        usedAddresses[address] = fullPath;
      }
    }
  }

  /// Returns the total number of registers across all groups.
  int _getTotalRegisterCount(PLCRegisterConfig config) {
    return config.registers.groups.values
        .map((g) => g.addresses.length)
        .fold(0, (a, b) => a + b);
  }

  /// Prints a formatted summary of the loaded configuration to the debug console.
  void printConfigInfo() {
    if (_cachedConfig == null) {
      debugPrint('[RegisterLoader] Config not loaded');
      return;
    }

    final config = _cachedConfig!;

    debugPrint('═══════════════════════════════════════════');
    debugPrint('PLC REGISTER CONFIG INFO');
    debugPrint('═══════════════════════════════════════════');
    debugPrint('Version: ${config.version}');
    debugPrint('Description: ${config.description}');
    debugPrint('Connection: ${config.connection.host}:${config.connection.port}');
    debugPrint('───────────────────────────────────────────');
    debugPrint('Register Groups:');

    for (final group in config.registers.groups.values) {
      debugPrint('  • ${group.name}: ${group.addresses.length} registers');
      debugPrint('    Type: ${group.type.toJson()}');
      debugPrint('    Range: ${_getAddressRange(group)}');
    }

    debugPrint('───────────────────────────────────────────');
    debugPrint('Workflows: ${config.workflows.length}');
    config.workflows.forEach((name, steps) {
      debugPrint('  • $name: ${steps.length} steps');
    });

    debugPrint('───────────────────────────────────────────');
    debugPrint('Validation:');
    debugPrint('  Required: ${config.validation.requiredRegisters.length}');
    debugPrint('  Critical Errors: ${config.validation.criticalErrors.length}');
    debugPrint('═══════════════════════════════════════════');
  }

  String _getAddressRange(RegisterGroup group) {
    if (group.addresses.isEmpty) return 'N/A';

    final addresses = group.addresses.values.toList()..sort();
    final min = addresses.first;
    final max = addresses.last;

    return min == max ? '$min' : '$min-$max';
  }

  /// Exports all register definitions as a map, keyed by full path.
  Map<String, dynamic> exportAllRegisters() {
    if (_cachedConfig == null) {
      throw StateError('Config not loaded — call load() first');
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
