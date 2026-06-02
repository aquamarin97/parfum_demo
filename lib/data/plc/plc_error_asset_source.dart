import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/plc/i_plc_error_string_source.dart';

/// Loads PLC error messages from the bundled Flutter asset bundle.
///
/// Expected asset path: `assets/i18n/plc_errors_<languageCode>.json`
///
/// The JSON format uses string error codes as keys:
/// ```json
/// { "401": "Failed to connect to PLC", "402": "Connection timeout" }
/// ```
///
/// Returns `null` when the asset file does not exist for the requested
/// language; parse errors are propagated to the caller.
class PlcErrorAssetSource implements IPlcErrorStringSource {
  const PlcErrorAssetSource();

  /// Loads the error-code → message map for [languageCode].
  ///
  /// Returns `null` if the asset file is missing.
  /// Throws if the file exists but contains invalid JSON.
  @override
  Future<Map<int, String>?> load(String languageCode) async {
    try {
      final raw = await rootBundle.loadString(
        'assets/i18n/plc_errors_$languageCode.json',
      );
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json.map((k, v) => MapEntry(int.parse(k), v.toString()));
    } on FlutterError {
      return null; // asset not found for this language
    }
  }
}
