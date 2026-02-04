// lib/plc/admin/models/plc_event.dart
import 'package:flutter/material.dart';

/// PLC event types
enum PLCEventType { connection, read, write, error, info }

/// PLC event modeli
@immutable
class PLCEvent {
  PLCEvent({
    required this.type,
    required this.message,
    this.register,
    this.value,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? PLCEvent._currentTime();

  final PLCEventType type;
  final String message;
  final int? register;
  final int? value;
  final String? error;
  final DateTime timestamp;

  static DateTime _currentTime() => DateTime.now();

  Color get color {
    switch (type) {
      case PLCEventType.connection:
        return Colors.blue;
      case PLCEventType.read:
        return Colors.green;
      case PLCEventType.write:
        return Colors.orange;
      case PLCEventType.error:
        return Colors.red;
      case PLCEventType.info:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (type) {
      case PLCEventType.connection:
        return Icons.link;
      case PLCEventType.read:
        return Icons.download;
      case PLCEventType.write:
        return Icons.upload;
      case PLCEventType.error:
        return Icons.error;
      case PLCEventType.info:
        return Icons.info;
    }
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    final parts = ['[$formattedTime]', type.name.toUpperCase(), message];
    if (register != null) parts.add('R$register');
    if (value != null) parts.add('= $value');
    if (error != null) parts.add('ERROR: $error');
    return parts.join(' ');
  }
}

/// Event logger singleton
class PLCEventLogger {
  PLCEventLogger._();

  static final PLCEventLogger instance = PLCEventLogger._();

  final List<PLCEvent> _events = [];
  final int _maxEvents = 200;

  List<PLCEvent> get events => List.unmodifiable(_events);

  void log(PLCEvent event) {
    _events.insert(0, event);
    if (_events.length > _maxEvents) {
      _events.removeLast();
    }

    // Debug print
    debugPrint('[PLC Event] ${event.toString()}');
  }

  void logConnection(String message) {
    log(PLCEvent(type: PLCEventType.connection, message: message));
  }

  void logRead(int register, int value) {
    log(
      PLCEvent(
        type: PLCEventType.read,
        message: 'Register okuma',
        register: register,
        value: value,
      ),
    );
  }

  void logWrite(int register, int value) {
    log(
      PLCEvent(
        type: PLCEventType.write,
        message: 'Register yazma',
        register: register,
        value: value,
      ),
    );
  }

  void logError(String message, {String? error}) {
    log(PLCEvent(type: PLCEventType.error, message: message, error: error));
  }

  void logInfo(String message) {
    log(PLCEvent(type: PLCEventType.info, message: message));
  }

  void clear() {
    _events.clear();
  }
}
