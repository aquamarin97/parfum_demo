/// Writes a formatted log line to a persistent output.
///
/// Implementations must be safe to call repeatedly from the same isolate and
/// should never throw — any failures must be handled internally so that log
/// writing never crashes the application.
abstract class FileLogWriter {
  /// Appends [message] to the underlying output.
  Future<void> write(String message);
}

/// No-op implementation used during testing or when file logging is disabled.
class NoopFileLogWriter implements FileLogWriter {
  @override
  Future<void> write(String message) async {}
}