import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/language.dart';

/// Persists user preferences across app restarts using [SharedPreferences].
///
/// Manages two entries:
/// - Language code — the locale selected by the customer.
/// - Device ID — a UUID generated once per device and reused thereafter.
class PreferencesStore {
  static const _keyLanguage = 'pref_language';
  static const _keyDeviceId = 'pref_device_id';

  static const _uuid = Uuid();

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  /// Returns the persisted BCP 47 language code, or `null` if none has
  /// been saved yet.
  Future<String?> readLanguageCode() async {
    final prefs = await _prefs;
    return prefs.getString(_keyLanguage);
  }

  /// Persists [language] so it is restored on the next app launch.
  Future<void> saveLanguage(Language language) async {
    final prefs = await _prefs;
    await prefs.setString(_keyLanguage, language.code);
  }

  /// Returns the device ID, creating and persisting a new UUID v4 if
  /// none exists yet.
  ///
  /// The ID is stable for the lifetime of the app installation and can
  /// be used to correlate logs across sessions.
  Future<String> readOrCreateDeviceId() async {
    final prefs = await _prefs;
    final existing = prefs.getString(_keyDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuid.v4();
    await prefs.setString(_keyDeviceId, id);
    return id;
  }
}