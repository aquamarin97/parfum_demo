import 'package:flutter/foundation.dart';

import 'language.dart';

/// The localised text and answer options for a single survey question.
@immutable
class QuestionTranslation {
  const QuestionTranslation({required this.text, required this.options});

  /// The question text in the target language.
  final String text;

  /// The selectable answer options in the target language.
  final List<String> options;
}

/// A single survey question with translations for all supported languages.
@immutable
class SurveyQuestion {
  const SurveyQuestion({required this.id, required this.translations});

  /// Unique question identifier used as the key in the answers map.
  final int id;

  /// Maps BCP 47 language code → localised question content.
  final Map<String, QuestionTranslation> translations;

  /// Returns the [QuestionTranslation] for [language].
  ///
  /// Falls back to the first available translation if [language] has no
  /// entry in [translations].
  QuestionTranslation translationFor(Language language) =>
      translations[language.code] ?? translations.values.first;
}