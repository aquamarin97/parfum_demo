import '../core/logging/app_logger.dart';
import '../data/models/language.dart';
import 'string_source.dart';

/// Loads localized string maps from an ordered list of [StringSource] instances.
///
/// Sources are tried in priority order; the first non-empty result is returned.
/// This lets a filesystem source (e.g. a USB update directory) take precedence
/// over the bundled asset source.
class StringRepository {
  /// Creates a [StringRepository] with an ordered [sources] list and a [logger].
  ///
  /// [sources] is tried in declaration order; earlier entries have higher priority.
  StringRepository(this._sources, this._logger);

  final List<StringSource> _sources;
  final AppLogger _logger;

  /// Loads string maps for every language in [languages].
  ///
  /// Returns a map from language code to its string key–value pairs.
  /// Languages whose strings cannot be loaded receive an empty map.
  Future<Map<String, Map<String, String>>> loadAll(
    List<Language> languages,
  ) async {
    final result = <String, Map<String, String>>{};
    for (final lang in languages) {
      result[lang.code] = await _loadFor(lang.code);
    }
    return result;
  }

  /// Loads the string map for a single language [code].
  ///
  /// Iterates through [_sources] in priority order and returns the first
  /// non-empty result. Logs a warning for each failing source and returns
  /// an empty map when all sources are exhausted.
  Future<Map<String, String>> _loadFor(String code) async {
    for (final source in _sources) {
      try {
        final data = await source.load(code);
        if (data != null && data.isNotEmpty) return data;
      } catch (e) {
        _logger.log(
          'StringSource ${source.runtimeType} failed for "$code": $e',
        );
      }
    }
    _logger.log('All string sources exhausted for language: "$code"');
    return {};
  }
}
