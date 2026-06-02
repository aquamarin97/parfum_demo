import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../string_source.dart';

/// A [StringSource] that loads string maps from the local filesystem.
///
/// Intended for USB or manual-copy update scenarios. [basePath] should point
/// to the directory that contains `strings_<languageCode>.json` files —
/// typically the `i18n/` folder next to the application executable.
class FilesystemStringSource implements StringSource {
  const FilesystemStringSource(this.basePath);

  /// Base directory that contains per-language JSON files.
  final String basePath;

  /// Loads the string map for [languageCode] from the filesystem.
  ///
  /// Returns `null` (silently) when the file does not exist — this is the
  /// expected case and the caller should fall through to the next source.
  ///
  /// Throws if the file exists but cannot be read or contains invalid JSON.
  /// The caller ([StringRepository]) is responsible for catching and logging
  /// such failures.
  @override
  Future<Map<String, String>?> load(String languageCode) async {
    final file = File(p.join(basePath, 'strings_$languageCode.json'));

    if (!await file.exists()) return null;

    final raw = await file.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return json.map((k, v) => MapEntry(k, v.toString()));
  }
}
