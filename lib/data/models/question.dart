// question.dart file
import 'language.dart';

class QuestionTranslation {
  const QuestionTranslation({required this.text, required this.options});

  final String text;
  final List<String> options;
}

class SurveyQuestion {
  const SurveyQuestion({required this.id, required this.translations});

  final int id;
  final Map<Language, QuestionTranslation> translations;

  QuestionTranslation translationFor(Language language) {
    return translations[language] ?? translations.values.first;
  }
}