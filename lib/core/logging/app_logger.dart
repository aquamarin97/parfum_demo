// app_logger.dart file
import 'file_log_writer.dart';

class AppLogger {
  AppLogger({FileLogWriter? writer}) : _writer = writer ?? NoopFileLogWriter();

  final FileLogWriter _writer;

  void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final formatted = '[$timestamp] $message';
    // ignore: avoid_print
    print(formatted);
    _writer.write(formatted);
  }
}