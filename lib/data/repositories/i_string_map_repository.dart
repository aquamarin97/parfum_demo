/// Contract for loading the localised string maps for all supported languages.
///
/// The returned map uses BCP 47 language codes as keys; each value is a
/// flat key → string map for that locale.
///
/// Implementations may load from the asset bundle, the filesystem
/// (USB update), or a remote source.
abstract interface class IStringMapRepository {
  /// Loads and returns string maps for all supported languages.
  ///
  /// Returns an empty map for any language whose strings could not be
  /// loaded — callers should handle missing keys gracefully.
  Future<Map<String, Map<String, String>>> loadStrings();
}