import '../data/models/language.dart';
import 'language_registry.dart';

class LocaleManager {
  const LocaleManager(this._registry);

  final LanguageRegistry _registry;

  Language fromCode(String code) => _registry.findByCode(code);
}
