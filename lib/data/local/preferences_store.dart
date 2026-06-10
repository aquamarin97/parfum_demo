import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/language.dart';

/// Persists user preferences across app restarts using [SharedPreferences].
///
/// Manages:
/// - Language code — the locale selected by the customer.
/// - Device ID — a UUID generated once per device and reused thereafter.
/// - Price — the product price shown on the payment screen (default: 490).
/// - Currency — the currency unit shown alongside the price (default: 'TL').
class PreferencesStore {
  static const _keyLanguage = 'pref_language';
  static const _keyDeviceId = 'pref_device_id';
  static const _keyPrice = 'pref_price';
  static const _keyCurrency = 'pref_currency';

  static const _defaultPrice = 490;
  static const _defaultCurrency = 'TL';

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

  /// Returns the persisted product price, or [_defaultPrice] if none has
  /// been saved yet.
  Future<int> readPrice() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyPrice) ?? _defaultPrice;
  }

  /// Persists [price] so it is restored on the next app launch.
  Future<void> savePrice(int price) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyPrice, price);
  }

  /// Returns the persisted currency unit, or [_defaultCurrency] if none has
  /// been saved yet.
  Future<String> readCurrency() async {
    final prefs = await _prefs;
    return prefs.getString(_keyCurrency) ?? _defaultCurrency;
  }

  /// Persists [currency] so it is restored on the next app launch.
  Future<void> saveCurrency(String currency) async {
    final prefs = await _prefs;
    await prefs.setString(_keyCurrency, currency);
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