import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../data/models/language.dart';

/// Mevcut dilleri keşfeder.
/// Önce exe yanındaki i18n/languages.json'a bakar (USB güncelleme),
/// bulamazsa assets/i18n/languages.json'a düşer.
/// Her iki kaynak da başarısız olursa _fallback listesiyle devam eder.
class LanguageRegistry {
  static const _manifestAsset = 'assets/i18n/languages.json';

  // Kod değişikliği olmadan yeni dil eklendiğinde bu liste hiç kullanılmaz.
  // Yalnızca languages.json hiç okunamazsa devreye girer (ilk kurulum hatası vb.).
  static const _fallback = [
    Language(code: 'tr', label: 'TR'),
    Language(code: 'en', label: 'EN'),
    Language(code: 'ar', label: 'AR', isRtl: true),
  ];

  List<Language> _languages = _fallback;

  List<Language> get available => List.unmodifiable(_languages);

  Language findByCode(String code) =>
      _languages.firstWhere((l) => l.code == code, orElse: () => _languages.first);

  Future<void> load() async {
    // 1. Filesystem override (USB / manuel güncelleme)
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final file = File(p.join(exeDir, 'i18n', 'languages.json'));
      if (await file.exists()) {
        _languages = _parse(jsonDecode(await file.readAsString()) as List);
        return;
      }
    } catch (_) {}

    // 2. Bundled asset
    try {
      final raw = await rootBundle.loadString(_manifestAsset);
      _languages = _parse(jsonDecode(raw) as List);
    } catch (_) {
      // _fallback ile devam et
    }
  }

  static List<Language> _parse(List<dynamic> json) => json
      .map((e) => Language.fromJson(e as Map<String, dynamic>))
      .toList();
}
