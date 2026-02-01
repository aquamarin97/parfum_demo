// file_log_writer.dart file
abstract class FileLogWriter {
  Future<void> write(String message);
}

class NoopFileLogWriter implements FileLogWriter {
  @override
  Future<void> write(String message) async {
    // TODO: implement file logging if required.
  }
}