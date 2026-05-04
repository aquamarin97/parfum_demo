import 'language.dart';

class KvkkTranslation {
  const KvkkTranslation({
    required this.title,
    required this.body,
    required this.approvalLabel,
    required this.buttonLabel,
  });

  final String title;
  final String body;
  final String approvalLabel;
  final String buttonLabel;
}

class KvkkText {
  const KvkkText({required this.id, required this.translations});

  final String id;
  final Map<String, KvkkTranslation> translations;

  KvkkTranslation translationFor(Language language) {
    return translations[language.code] ?? translations.values.first;
  }
}
