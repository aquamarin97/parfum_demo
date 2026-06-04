import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../data/models/language.dart';

/// Discovers the set of supported languages at runtime.
///
/// Sources are tried in priority order:
/// 1. `i18n/languages.json` next to the executable (USB/manual update).
/// 2. `assets/i18n/languages.json` bundled with the app.
///
/// If both sources fail, [available] remains empty and [AppViewModel]
/// transitions to [ErrorState] — no silent fallback is used so that
/// missing configuration is immediately visible.
///
/// This design allows new languages to be added without a code change or
/// app update — simply replace the `languages.json` file on the device.
class LanguageRegistry {
  static const _manifestAsset = 'assets/i18n/languages.json';

  List<Language> _languages = [];

  /// The currently loaded language list.
  ///
  /// Returns an unmodifiable view. Call [load] before accessing this
  /// to ensure the list reflects the latest source.
  List<Language> get available => List.unmodifiable(_languages);

  /// Returns the [Language] matching [code], or the first available
  /// language if no match is found.
  ///
  /// Throws [StateError] if [load] has not been called or both sources
  /// failed — callers must ensure [available] is non-empty.
  Language findByCode(String code) {
    if (_languages.isEmpty) {
      throw StateError(
        'LanguageRegistry is empty — call load() first.',
      );
    }
    return _languages.firstWhere(
      (l) => l.code == code,
      orElse: () => _languages.first,
    );
  }

  /// Loads the language list from the highest-priority available source.
  ///
  /// Safe to call multiple times — the list is replaced on each call.
  Future<void> load() async {
    // 1. Filesystem override — USB or manual update next to the executable.
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final file = File(p.join(exeDir, 'i18n', 'languages.json'));
      if (await file.exists()) {
        _languages = _parse(jsonDecode(await file.readAsString()) as List);
        return;
      }
    } catch (_) {
      // Fall through to asset source.
    }

    // 2. Bundled asset.
    try {
      final raw = await rootBundle.loadString(_manifestAsset);
      _languages = _parse(jsonDecode(raw) as List);
    } catch (_) {
      // Both sources failed — _languages remains empty.
      // AppViewModel._setup() will transition to ErrorState.
    }
  }

  static List<Language> _parse(List<dynamic> json) => json
      .map((e) => Language.fromJson(e as Map<String, dynamic>))
      .toList();
}