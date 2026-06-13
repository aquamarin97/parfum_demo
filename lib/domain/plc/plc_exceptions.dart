/// Error code constants and technical descriptions for PLC faults.
///
/// Localised user-facing messages are stored separately in
/// `assets/i18n/plc_errors_<languageCode>.json` and loaded via
/// [IPlcErrorStringSource] implementations.
class PLCErrorCodes {
  // Connection errors (400–409)
  static const int connectionFailed = 401;
  static const int connectionTimeout = 402;
  static const int connectionLost = 403;
  static const int invalidHost = 404;
  static const int portNotAvailable = 405;

  // Communication errors (410–419)
  static const int modbusReadError = 410;
  static const int modbusWriteError = 411;
  static const int invalidRegisterAddress = 412;
  static const int dataCorruption = 413;
  static const int responseTimeout = 414;

  // PLC state errors (420–429)
  static const int plcNotReady = 420;
  static const int plcEmergencyStop = 421;
  static const int sensorError = 422;
  static const int motorError = 423;

  // Application errors (430–439)
  static const int unknownError = 430;
  static const int configurationError = 431;
  static const int commandRejected = 432;
  static const int systemFault = 433;

  /// Returns a developer-facing technical description for [errorCode].
  static String getTechnicalDescription(int errorCode) {
    return _technicalDescriptions[errorCode] ?? 'Unknown error code: $errorCode';
  }

  static final Map<int, String> _technicalDescriptions = {
    connectionFailed:
        'TCP/IP connection could not be established. Check IP and port settings.',
    connectionTimeout:
        'Connection timeout: 3000 ms. Is the PLC reachable on the network?',
    connectionLost:
        'Active connection dropped. Check cable and PLC power.',
    invalidHost: 'Target IP address is in an invalid format. Default: 127.0.0.1',
    portNotAvailable: 'Modbus TCP port (502) is in use or blocked.',
    modbusReadError: 'Read Holding Registers (FC03) command failed.',
    modbusWriteError:
        'Write Single Register (FC06) or Multiple (FC16) command failed.',
    invalidRegisterAddress: 'Register address out of range (0–65535).',
    dataCorruption:
        'CRC/checksum error. Possible electrical noise or cable issue.',
    responseTimeout:
        'PLC read timeout: 2000 ms. PLC response may be slow.',
    plcNotReady: 'PLC is not in RUN mode. Check PLC panel.',
    plcEmergencyStop: 'E-STOP is active. Safety circuit must be inspected.',
    sensorError:
        'Analog/digital sensor read error. Sensor calibration required.',
    motorError: 'Motor driver fault. Check inverter/driver.',
    unknownError: 'Uncategorised error. Review log files.',
    configurationError: 'Modbus settings are incorrect. Check config file.',
    commandRejected: 'PLC rejected the command (STATUS_LAST_CMD_RESULT=1).',
    systemFault: 'PLC system entered fault state (STATUS_SYSTEM=2).',
  };
}

/// Represents a PLC communication or state fault.
class PLCException implements Exception {
  PLCException({
    required this.errorCode,
    required this.message,
    this.technicalDetail,
  }) : timestamp = DateTime.now();

  final int errorCode;

  /// English technical fallback message set by the infrastructure layer.
  ///
  /// Localised user-facing messages are loaded at the UI layer via
  /// [IPlcErrorStringSource] using the active language code.
  final String message;
  final String? technicalDetail;
  final DateTime timestamp;

  @override
  String toString() =>
      'PLCException(code: $errorCode, message: $message, time: $timestamp)';

  /// Returns the technical description with any additional runtime detail appended.
  String getTechnicalInfo() {
    final base = PLCErrorCodes.getTechnicalDescription(errorCode);
    if (technicalDetail != null) return '$base\n\nAdditional detail: $technicalDetail';
    return base;
  }
}
