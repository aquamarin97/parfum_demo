/// Contract for a single source of localised string key–value pairs.
///
/// Implementations are tried in priority order by [StringRepository].
/// Returning `null` signals that this source has no data for the
/// requested language; the repository then tries the next source.
///
/// Throwing signals an unexpected error (e.g. malformed JSON) that the
/// repository will catch, log, and skip.
abstract class StringSource {
  /// Loads the string map for [languageCode].
  ///
  /// Returns `null` when this source has no data for the language —
  /// this is the expected case and the caller falls through to the
  /// next source silently.
  ///
  /// Throws if the source exists but cannot be parsed. The caller
  /// ([StringRepository]) is responsible for catching and logging
  /// such failures.
  Future<Map<String, String>?> load(String languageCode);
}