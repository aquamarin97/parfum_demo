// i18n_repository.dart file
import '../../i18n/string_repository.dart';
import '../models/language.dart';

class I18nRepository {
  I18nRepository(this._stringRepository);

  final StringRepository _stringRepository;

  Future<Map<Language, Map<String, String>>> loadStrings() {
    return _stringRepository.loadAll();
  }
}