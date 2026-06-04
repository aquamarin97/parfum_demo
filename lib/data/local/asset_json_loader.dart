import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads and decodes JSON files from the Flutter asset bundle.
///
/// Throws a [FormatException] if the decoded value is not a
/// [Map<String, dynamic>] — callers can assume the return value is
/// always a valid JSON object.
class AssetJsonLoader {
  const AssetJsonLoader();

  /// Loads and decodes the JSON file at [path] from the asset bundle.
  ///
  /// [path] must be declared in `pubspec.yaml` under `flutter: assets:`.
  ///
  /// Throws [FlutterError] if the asset does not exist.
  /// Throws [FormatException] if the file is not a JSON object.
  Future<Map<String, dynamic>> loadJson(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    throw FormatException('Expected a JSON object at $path, '
        'got ${decoded.runtimeType}');
  }
}