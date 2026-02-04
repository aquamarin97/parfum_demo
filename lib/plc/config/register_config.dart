// register_config.dart
/// PLC Register konfigürasyon modeli
/// 
/// JSON'dan yüklenen register haritasını Dart object'e dönüştürür
/// ve type-safe erişim sağlar.

class PLCRegisterConfig {
  PLCRegisterConfig({
    required this.version,
    required this.description,
    required this.connection,
    required this.registers,
    required this.workflows,
    required this.validation,
  });

  final String version;
  final String description;
  final ConnectionConfig connection;
  final RegisterMap registers;
  final Map<String, List<String>> workflows;
  final ValidationConfig validation;

  factory PLCRegisterConfig.fromJson(Map<String, dynamic> json) {
    return PLCRegisterConfig(
      version: json['version'] as String,
      description: json['description'] as String,
      connection: ConnectionConfig.fromJson(
        json['connection'] as Map<String, dynamic>,
      ),
      registers: RegisterMap.fromJson(
        json['registers'] as Map<String, dynamic>,
      ),
      workflows: (json['workflows'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, List<String>.from(v as List))),
      validation: ValidationConfig.fromJson(
        json['validation'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'description': description,
      'connection': connection.toJson(),
      'registers': registers.toJson(),
      'workflows': workflows,
      'validation': validation.toJson(),
    };
  }

  /// Register adresini path string'inden al
  /// Örnek: "recommendations.first" → 0
  int getAddress(String path) {
    final parts = path.split('.');
    if (parts.length != 2) {
      throw ArgumentError('Geçersiz register path: $path');
    }

    final groupName = parts[0];
    final registerName = parts[1];

    final group = registers.getGroup(groupName);
    if (group == null) {
      throw ArgumentError('Register grubu bulunamadı: $groupName');
    }

    final address = group.addresses[registerName];
    if (address == null) {
      throw ArgumentError('Register bulunamadı: $path');
    }

    return address;
  }

  /// Register'ın açıklamasını al
  String? getDescription(String groupName) {
    return registers.getGroup(groupName)?.description;
  }

  /// Register'ın tipini al (read/write/read_write)
  RegisterType? getType(String groupName) {
    return registers.getGroup(groupName)?.type;
  }
}

// ============================================================================

class ConnectionConfig {
  ConnectionConfig({
    required this.host,
    required this.port,
    required this.slaveId,
    required this.timeoutMs,
    required this.retryCount,
  });

  final String host;
  final int port;
  final int slaveId;
  final int timeoutMs;
  final int retryCount;

  factory ConnectionConfig.fromJson(Map<String, dynamic> json) {
    return ConnectionConfig(
      host: json['host'] as String,
      port: json['port'] as int,
      slaveId: json['slave_id'] as int,
      timeoutMs: json['timeout_ms'] as int,
      retryCount: json['retry_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'slave_id': slaveId,
      'timeout_ms': timeoutMs,
      'retry_count': retryCount,
    };
  }

  Duration get timeout => Duration(milliseconds: timeoutMs);
}

// ============================================================================

class RegisterMap {
  RegisterMap({required this.groups});

  final Map<String, RegisterGroup> groups;

  factory RegisterMap.fromJson(Map<String, dynamic> json) {
    final groups = <String, RegisterGroup>{};
    
    json.forEach((key, value) {
      groups[key] = RegisterGroup.fromJson(
        key,
        value as Map<String, dynamic>,
      );
    });

    return RegisterMap(groups: groups);
  }

  Map<String, dynamic> toJson() {
    return groups.map((k, v) => MapEntry(k, v.toJson()));
  }

  RegisterGroup? getGroup(String name) => groups[name];

  /// Tüm register adreslerini düz liste olarak al
  List<RegisterAddress> getAllAddresses() {
    final result = <RegisterAddress>[];
    
    groups.forEach((groupName, group) {
      group.addresses.forEach((registerName, address) {
        result.add(RegisterAddress(
          group: groupName,
          name: registerName,
          address: address,
          type: group.type,
          description: group.description,
        ));
      });
    });

    return result;
  }
}

// ============================================================================

enum RegisterType {
  read,
  write,
  readWrite;

  static RegisterType fromString(String value) {
    switch (value) {
      case 'read':
        return RegisterType.read;
      case 'write':
        return RegisterType.write;
      case 'read_write':
        return RegisterType.readWrite;
      default:
        throw ArgumentError('Geçersiz register type: $value');
    }
  }

  String toJson() {
    switch (this) {
      case RegisterType.read:
        return 'read';
      case RegisterType.write:
        return 'write';
      case RegisterType.readWrite:
        return 'read_write';
    }
  }
}

// ============================================================================

class RegisterGroup {
  RegisterGroup({
    required this.name,
    required this.description,
    required this.type,
    required this.addresses,
    required this.dataType,
    this.values,
    this.minValue,
    this.maxValue,
  });

  final String name;
  final String description;
  final RegisterType type;
  final Map<String, int> addresses;
  final String dataType;
  final Map<String, Map<String, String>>? values; // Enum-like değerler
  final int? minValue;
  final int? maxValue;

  factory RegisterGroup.fromJson(String name, Map<String, dynamic> json) {
    return RegisterGroup(
      name: name,
      description: json['description'] as String,
      type: RegisterType.fromString(json['type'] as String),
      addresses: (json['addresses'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as int)),
      dataType: json['data_type'] as String,
      values: json['values'] != null
          ? (json['values'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(
                k,
                (v as Map<String, dynamic>)
                    .map((k2, v2) => MapEntry(k2, v2.toString())),
              ),
            )
          : null,
      minValue: json['min_value'] as int?,
      maxValue: json['max_value'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'type': type.toJson(),
      'addresses': addresses,
      'data_type': dataType,
      if (values != null) 'values': values,
      if (minValue != null) 'min_value': minValue,
      if (maxValue != null) 'max_value': maxValue,
    };
  }

  /// Değer açıklamasını al
  /// Örnek: getValueDescription('status', 1) → "Onaylandı"
  String? getValueDescription(String registerName, int value) {
    if (values == null) return null;
    
    final registerValues = values![registerName];
    if (registerValues == null) return null;
    
    return registerValues[value.toString()];
  }

  /// Değeri validate et
  bool validateValue(int value) {
    if (minValue != null && value < minValue!) return false;
    if (maxValue != null && value > maxValue!) return false;
    return true;
  }
}

// ============================================================================

class RegisterAddress {
  RegisterAddress({
    required this.group,
    required this.name,
    required this.address,
    required this.type,
    required this.description,
  });

  final String group;
  final String name;
  final int address;
  final RegisterType type;
  final String description;

  String get fullPath => '$group.$name';

  bool get isReadable =>
      type == RegisterType.read || type == RegisterType.readWrite;
  
  bool get isWritable =>
      type == RegisterType.write || type == RegisterType.readWrite;

  @override
  String toString() => '$fullPath ($address)';
}

// ============================================================================

class ValidationConfig {
  ValidationConfig({
    required this.requiredRegisters,
    required this.criticalErrors,
  });

  final List<String> requiredRegisters;
  final List<String> criticalErrors;

  factory ValidationConfig.fromJson(Map<String, dynamic> json) {
    return ValidationConfig(
      requiredRegisters: List<String>.from(json['required_registers'] as List),
      criticalErrors: List<String>.from(json['critical_errors'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'required_registers': requiredRegisters,
      'critical_errors': criticalErrors,
    };
  }
}