import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:parfume_app/core/strings/app_strings.dart';

/// Loads admin-panel localised strings from [assets/admin/].
///
/// Only Turkish and English are supported. Any other locale code falls back
/// to English. Returns an [AppStrings] instance so admin widgets can use the
/// same [AppStrings.t] interface as the rest of the app.
Future<AppStrings> loadAdminStrings(String localeCode) async {
  final code = (localeCode == 'tr') ? 'tr' : 'en';

  String raw;
  try {
    raw = await rootBundle.loadString('assets/admin/strings_$code.json');
  } catch (_) {
    raw = await rootBundle.loadString('assets/admin/strings_en.json');
  }

  final decoded = json.decode(raw) as Map<String, dynamic>;
  final values = decoded.map((k, v) => MapEntry(k, v.toString()));
  return AppStrings(localeCode: code, values: values);
}
