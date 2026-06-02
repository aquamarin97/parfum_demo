import 'dart:convert';

import 'package:flutter/services.dart';

import '../string_source.dart';

/// Flutter asset bundle'ından string'leri yükleyen [StringSource] implementasyonu.
///
/// Beklenen dosya yolu: `assets/i18n/strings_<languageCode>.json`
/// Dosya bulunamazsa veya parse edilemezse `null` döner.
class AssetStringSource implements StringSource {
  const AssetStringSource();

  /// [languageCode] için asset'ten string map'i yükler.
  ///
  /// Returns başarılıysa string map'i, dosya yoksa veya hata varsa `null`.
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