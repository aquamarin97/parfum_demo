import 'dart:convert';

import 'package:flutter/services.dart';

import '../string_source.dart';

class AssetStringSource implements StringSource {
  const AssetStringSource();

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
