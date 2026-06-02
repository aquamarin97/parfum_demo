import 'dart:io';

import 'package:path/path.dart' as p;

import 'file_log_writer.dart';

/// A [FileLogWriter] that appends log lines to a file and rotates it when it
/// exceeds [maxBytes].
///
/// Rotation renames `<fileName>` to `<baseName>.1<ext>`, overwriting any
/// existing backup, then starts a fresh log file. Only [maxBackups] backup
/// files are kept; the oldest is deleted on each rotation.
///
/// Writes are serialised internally so concurrent async callers never
/// interleave partial lines. All I/O errors are silently swallowed —
/// log writing must never propagate to the application.
///
/// Example layout (maxBackups = 1):
/// ```
/// logs/
///   app.log      ← active
///   app.1.log    ← most recent backup
/// ```
class RotatingFileLogWriter implements FileLogWriter {
  RotatingFileLogWriter({
    required String logDirectory,
    this.fileName = 'app.log',
    this.maxBytes = 5 * 1024 * 1024, // 5 MB
    this.maxBackups = 1,
  }) : _logDirectory = logDirectory;

  /// Directory where the log files are stored.
  final String _logDirectory;

  /// Name of the active log file.
  final String fileName;

  /// Maximum file size in bytes before rotation is triggered.
  final int maxBytes;

  /// Number of backup files to retain after rotation.
  final int maxBackups;

  // Serialises concurrent write calls — resolved value is intentionally unused.
  Future<void> _pending = Future<void>.value();

  @override
  Future<void> write(String message) {
    // Chain so every write waits for the previous one to finish.
    _pending = _pending.then((_) => _writeImpl(message));
    return _pending;
  }

  Future<void> _writeImpl(String message) async {
    try {
      final dir = Directory(_logDirectory);
      if (!await dir.exists()) await dir.create(recursive: true);

      final file = File(p.join(_logDirectory, fileName));

      if (await file.exists() && await file.length() >= maxBytes) {
        await _rotate();
      }

      await file.writeAsString('$message\n', mode: FileMode.append);
    } catch (_) {
      // Swallow — log writing must never crash the app.
    }
  }

  Future<void> _rotate() async {
    final baseName = p.basenameWithoutExtension(fileName);
    final ext = p.extension(fileName); // includes the dot, e.g. ".log"

    // Shift existing backups: oldest (maxBackups) is deleted, others move up.
    for (var i = maxBackups; i >= 1; i--) {
      final backup = File(p.join(_logDirectory, '$baseName.$i$ext'));
      if (!await backup.exists()) continue;
      if (i == maxBackups) {
        await backup.delete();
      } else {
        await backup.rename(p.join(_logDirectory, '$baseName.${i + 1}$ext'));
      }
    }

    // Rename the active log to the first backup slot.
    final activeLog = File(p.join(_logDirectory, fileName));
    await activeLog.rename(p.join(_logDirectory, '$baseName.1$ext'));
  }
}
