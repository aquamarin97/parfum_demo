import 'file_log_writer.dart';

/// Severity levels for log messages, ordered from least to most critical.
enum LogLevel { debug, info, warning, error }

/// Application-wide structured logger with level filtering and optional file output.
///
/// Messages below [minimumLevel] are silently discarded, allowing verbose
/// [LogLevel.debug] output during development while keeping production logs clean
/// by setting [minimumLevel] to [LogLevel.info].
class AppLogger {
  AppLogger({
    FileLogWriter? writer,
    LogLevel minimumLevel = LogLevel.debug,
  })  : _writer = writer ?? NoopFileLogWriter(),
        _minimumLevel = minimumLevel;

  final FileLogWriter _writer;
  final LogLevel _minimumLevel;

  /// Logs development-level detail; silenced when [minimumLevel] ≥ [LogLevel.info].
  void debug(String message) => _emit(LogLevel.debug, message);

  /// Logs a normal-flow event.
  void info(String message) => _emit(LogLevel.info, message);

  /// Logs an unexpected but recoverable condition.
  void warning(String message) => _emit(LogLevel.warning, message);

  /// Logs a fault that requires attention.
  void error(String message) => _emit(LogLevel.error, message);

  /// Backward-compatible alias for [info].
  void log(String message) => info(message);

  void _emit(LogLevel level, String message) {
    if (level.index < _minimumLevel.index) return;
    final timestamp = DateTime.now().toIso8601String();
    final label = level.name.toUpperCase().padRight(7); // align columns
    final formatted = '[$timestamp] [$label] $message';
    // ignore: avoid_print
    print(formatted);
    _writer.write(formatted);
  }
}
