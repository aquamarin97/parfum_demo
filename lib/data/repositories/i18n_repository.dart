import '../../i18n/language_registry.dart';
import '../../i18n/string_repository.dart';
import 'i_string_map_repository.dart';

/// Loads localised string maps for all languages registered in
/// [LanguageRegistry].
///
/// Delegates to [StringRepository] which tries each [StringSource] in
/// priority order (filesystem first, asset bundle as fallback).
class I18nRepository implements IStringMapRepository {
  I18nRepository(this._stringRepository, this._registry);

  final StringRepository _stringRepository;
  final LanguageRegistry _registry;

  /// Loads string maps for every language in [LanguageRegistry.available].
  ///
  /// Returns an empty map for any language whose sources are all exhausted.
  @override
  Future<Map<String, Map<String, String>>> loadStrings() =>
      _stringRepository.loadAll(_registry.available);
}