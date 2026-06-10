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
}