import 'package:flutter/material.dart';

/// The category of a [PLCEvent].
enum PLCEventType {
  /// A connection was established or lost.
  connection,

  /// A register value was read.
  read,

  /// A register value was written.
  write,

  /// An error occurred.
  error,

  /// A general informational message.
  info,
}

/// An immutable record of a single PLC operation or state change.
@immutable
class PLCEvent {
  /// Creates a [PLCEvent], defaulting [timestamp] to [DateTime.now].
  PLCEvent({
    required this.type,
    required this.message,
    this.register,
    this.value,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final PLCEventType type;

  /// Human-readable description of the event.
  final String message;

  /// Register address involved in the event, if any.
  final int? register;

  /// Register value involved in the event, if any.
  final int? value;

  /// Error detail string, populated for [PLCEventType.error] events.
  final String? error;

  /// When the event occurred.
  final DateTime timestamp;

  /// UI color associated with [type].
  ///
  /// Note: color logic lives here for convenience; consider moving to
  /// the UI layer if the model is ever used outside Flutter.
  Color get color => switch (type) {
    PLCEventType.connection => Colors.blue,
    PLCEventType.read       => Colors.green,
    PLCEventType.write      => Colors.orange,
    PLCEventType.error      => Colors.red,
    PLCEventType.info       => Colors.grey,
  };

  /// UI icon associated with [type].
  IconData get icon => switch (type) {
    PLCEventType.connection => Icons.link,
    PLCEventType.read       => Icons.download,
    PLCEventType.write      => Icons.upload,
    PLCEventType.error      => Icons.error,
    PLCEventType.info       => Icons.info,
  };

  /// Time formatted as `HH:mm:ss`.
  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}';

  @override
  String toString() {
    final parts = ['[$formattedTime]', type.name.toUpperCase(), message];
    if (register != null) parts.add('R$register');
    if (value != null) parts.add('= $value');
    if (error != null) parts.add('ERROR: $error');
    return parts.join(' ');
  }
}

/// In-memory circular log of [PLCEvent] entries.
///
/// Retains the most recent [_maxEvents] entries, discarding the oldest
/// when the buffer is full. Events are stored newest-first.
///
/// TODO: replace singleton with an injected dependency to improve
/// testability and remove the global state.
class PLCEventLogger {
  PLCEventLogger._();

  /// The global logger instance.
  static final PLCEventLogger instance = PLCEventLogger._();

  final List<PLCEvent> _events = [];

  /// Maximum number of events retained in memory.
  static const int _maxEvents = 200;

  /// An unmodifiable view of the current event list, newest first.
  List<PLCEvent> get events => List.unmodifiable(_events);

  /// Appends [event] to the log, evicting the oldest entry if the
  /// buffer exceeds [_maxEvents].
  void log(PLCEvent event) {
    _events.insert(0, event);
    if (_events.length > _maxEvents) _events.removeLast();
    debugPrint('[PLCEvent] $event');
  }

  /// Logs a [PLCEventType.connection] event with [message].
  void logConnection(String message) =>
      log(PLCEvent(type: PLCEventType.connection, message: message));

  /// Logs a [PLCEventType.read] event for [register] returning [value].
  void logRead(int register, int value) => log(PLCEvent(
        type: PLCEventType.read,
        message: 'Register read',
        register: register,
        value: value,
      ));

  /// Logs a [PLCEventType.write] event for [register] with [value].
  void logWrite(int register, int value) => log(PLCEvent(
        type: PLCEventType.write,
        message: 'Register write',
        register: register,
        value: value,
      ));

  /// Logs a [PLCEventType.error] event with optional [error] detail.
  void logError(String message, {String? error}) =>
      log(PLCEvent(type: PLCEventType.error, message: message, error: error));

  /// Logs a [PLCEventType.info] event with [message].
  void logInfo(String message) =>
      log(PLCEvent(type: PLCEventType.info, message: message));

  /// Clears all events from the log.
  void clear() => _events.clear();
}