import '../../i18n/language_registry.dart';
import '../../i18n/string_repository.dart';
import 'i_string_map_repository.dart';

class I18nRepository implements IStringMapRepository {
  I18nRepository(this._stringRepository, this._registry);

  final StringRepository _stringRepository;
  final LanguageRegistry _registry;

  @override
  Future<Map<String, Map<String, String>>> loadStrings() {
    return _stringRepository.loadAll(_registry.available);
  }
}
