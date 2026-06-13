import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/language.dart';
import '../../domain/plc/plc_timings.dart';
import '../../domain/session/session_snapshot.dart';

/// Persists user preferences across app restarts using [SharedPreferences].
///
/// Manages:
/// - Language code — the locale selected by the customer.
/// - Device ID — a UUID generated once per device and reused thereafter.
/// - Price — the product price shown on the payment screen (default: 490).
/// - Currency — the currency unit shown alongside the price (default: 'TL').
/// - PLCTimings — configurable PLC timeout/polling values.
/// - Slot prices — per-slot price overrides (slotId → price in TL).
class PreferencesStore {
  static const _keyLanguage            = 'pref_language';
  static const _keyDeviceId            = 'pref_device_id';
  static const _keyPrice               = 'pref_price';
  static const _keyCurrency            = 'pref_currency';
  static const _keySession             = 'pref_session';
  static const _keyTimingAckSec        = 'pref_timing_ack_sec';
  static const _keyTimingIdlePollMs    = 'pref_timing_idle_poll_ms';
  static const _keyTimingPayPollMs     = 'pref_timing_pay_poll_ms';
  static const _keyTimingSalePollMs    = 'pref_timing_sale_poll_ms';
  static const _keySlotPrices          = 'pref_slot_prices';

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

  /// Son oturumu JSON olarak kaydeder.
  Future<void> saveSession(SessionSnapshot snapshot) async {
    final prefs = await _prefs;
    await prefs.setString(_keySession, jsonEncode(snapshot.toJson()));
  }

  /// Kaydedilmiş oturumu döner; yoksa veya geçersizse `null`.
  Future<SessionSnapshot?> readSession() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keySession);
    if (raw == null) return null;
    try {
      final snapshot = SessionSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return snapshot.isValid ? snapshot : null;
    } catch (_) {
      return null;
    }
  }

  /// Kayıtlı oturumu siler.
  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_keySession);
  }

  // ---------------------------------------------------------------------------
  // PLC Timings
  // ---------------------------------------------------------------------------

  /// Kaydedilmiş [PLCTimings] değerlerini döner; kayıt yoksa varsayılanları kullanır.
  Future<PLCTimings> readTimings() async {
    final prefs = await _prefs;
    return PLCTimings(
      commandAckTimeoutSec:
          prefs.getInt(_keyTimingAckSec) ?? PLCTimings.defaults.commandAckTimeoutSec,
      systemIdlePollMs:
          prefs.getInt(_keyTimingIdlePollMs) ?? PLCTimings.defaults.systemIdlePollMs,
      paymentStatusPollMs:
          prefs.getInt(_keyTimingPayPollMs) ?? PLCTimings.defaults.paymentStatusPollMs,
      saleCompletedPollMs:
          prefs.getInt(_keyTimingSalePollMs) ?? PLCTimings.defaults.saleCompletedPollMs,
    );
  }

  /// [PLCTimings] değerlerini kalıcı olarak kaydeder.
  Future<void> saveTimings(PLCTimings t) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyTimingAckSec, t.commandAckTimeoutSec);
    await prefs.setInt(_keyTimingIdlePollMs, t.systemIdlePollMs);
    await prefs.setInt(_keyTimingPayPollMs, t.paymentStatusPollMs);
    await prefs.setInt(_keyTimingSalePollMs, t.saleCompletedPollMs);
  }

  // ---------------------------------------------------------------------------
  // Slot Prices
  // ---------------------------------------------------------------------------

  /// Slot bazlı fiyat haritasını döner: slotId → TL cinsinden fiyat.
  ///
  /// Kayıt yoksa boş harita döner (varsayılan global fiyat kullanılır).
  Future<Map<int, int>> readSlotPrices() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keySlotPrices);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(int.parse(k), v as int));
    } catch (_) {
      return {};
    }
  }

  /// Slot bazlı fiyat haritasını kalıcı olarak kaydeder.
  Future<void> saveSlotPrices(Map<int, int> prices) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(prices.map((k, v) => MapEntry(k.toString(), v)));
    await prefs.setString(_keySlotPrices, encoded);
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