/// Holds the localised string map for a single locale.
///
/// Instances are created by [AppViewModel] after the i18n layer has finished
/// loading and are accessed by UI components via `viewModel.strings`.
///
/// Missing keys return a visible placeholder so untranslated strings are
/// immediately obvious during development and QA.
class AppStrings {
  /// Creates an [AppStrings] instance for [localeCode] with the given [values].
  const AppStrings({required this.localeCode, required this.values});

  /// BCP 47 language code for this string map (e.g. `'tr'`, `'en'`).
  final String localeCode;

  /// Key–value pairs loaded from the corresponding i18n JSON file.
  final Map<String, String> values;

  /// Returns the localised string for [key].
  ///
  /// Returns `'[MISSING: key]'` when [key] is absent from [values], making
  /// untranslated strings immediately visible rather than silently empty.
  String t(String key) => values[key] ?? '[MISSING: $key]';
}