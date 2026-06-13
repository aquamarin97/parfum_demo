import '../core/strings/app_strings.dart';

/// Contract that exposes the subset of [AppViewModel] needed by the result
/// screen view-models.
///
/// [ResultViewModel] and [ResultViewModelWithPLC] depend on this interface
/// rather than the concrete [AppViewModel], keeping them testable and
/// decoupled from the full application state.
abstract interface class IResultContext {
  /// Ordered list of recommended perfume IDs computed by the scoring engine.
  List<int> get topIds;

  /// Localised strings for the active language.
  AppStrings get strings;

  /// BCP 47 language code for the active locale (e.g. `'tr'`, `'en'`).
  String get languageCode;

  /// Cancels the current flow and returns the kiosk to the idle screen.
  ///
  /// Resets all session state before transitioning.
  void cancelToIdle();

  /// Resets all session state and transitions directly to the idle screen.
  void resetToIdle();

  /// Fully formatted price label for the active language and current price
  /// settings (e.g. `'Fiyat: 490 TL'`).
  String get priceLabel;

  /// Product price in major currency units (e.g. 490 for 490 TL).
  int get price;

  /// Currency code (e.g. `'TL'`, `'EUR'`).
  String get currency;

  /// Başarıyla tamamlanan satış sonrası kaydedilmiş oturumu temizler.
  void clearSession();

  /// Belirtilen slot için ürün fiyatını döner (TL, büyük birim).
  ///
  /// Slot için özel fiyat tanımlanmışsa onu, aksi hâlde global [price]'ı döner.
  int priceForSlot(int slotId);
}