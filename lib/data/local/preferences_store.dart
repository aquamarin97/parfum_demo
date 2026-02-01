// preferences_store.dart file
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/language.dart';

class PreferencesStore {
  static const _keyLanguage = 'pref_language';
  static const _keyDeviceId = 'pref_device_id';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<Language?> readLanguage() async {
    final prefs = await _prefs;
    final code = prefs.getString(_keyLanguage);
    return Language.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => Language.tr,
    );
  }

  Future<void> saveLanguage(Language language) async {
    final prefs = await _prefs;
    await prefs.setString(_keyLanguage, language.code);
  }

  Future<String> readOrCreateDeviceId() async {
    final prefs = await _prefs;
    final existing = prefs.getString(_keyDeviceId);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final id = const Uuid().v4();
    await prefs.setString(_keyDeviceId, id);
    return id;
  }
}