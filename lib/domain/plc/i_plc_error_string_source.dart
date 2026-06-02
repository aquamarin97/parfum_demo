/// Contract for loading localised PLC error messages.
abstract interface class IPlcErrorStringSource {
  /// Loads the error-code → user-message map for [languageCode].
  ///
  /// Returns `null` when this source has no data for the requested language.
  /// The caller is responsible for falling back to another source or to a
  /// technical description.
  Future<Map<int, String>?> load(String languageCode);
}
