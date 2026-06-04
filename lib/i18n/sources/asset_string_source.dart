import 'dart:convert';

import 'package:flutter/services.dart';

import '../string_source.dart';

/// A [StringSource] that loads string maps from the Flutter asset bundle.
///
/// Expected asset path: `assets/i18n/strings_<languageCode>.json`
///
/// Returns `null` when the asset file is missing for the requested
/// language; parse errors are also silenced so [StringRepository] falls
/// through to the next source.
class AssetStringSource implements StringSource {
  const AssetStringSource();

  /// Loads the string map for [languageCode] from the asset bundle.
  ///
  /// Returns `null` if the asset does not exist or cannot be parsed.
  @override
  Future<Map<String, String>?> load(String languageCode) async {
    try {
      final raw = await rootBundle.loadString(
        'assets/i18n/strings_$languageCode.json',
      );
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return null;
    }
  }
}