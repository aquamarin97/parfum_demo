// locale_manager.dart file
import '../data/models/language.dart';

class LocaleManager {
  const LocaleManager();

  Language fromCode(String code) {
    return Language.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => Language.tr,
    );
  }
}