import 'package:flutter/foundation.dart';

import 'language.dart';

/// The localised content for a single KVKK consent screen.
@immutable
class KvkkTranslation {
  const KvkkTranslation({
    required this.title,
    required this.body,
    required this.approvalLabel,
    required this.buttonLabel,
  });

  /// Consent screen heading.
  final String title;

  /// Full consent text displayed in the scrollable area.
  final String body;

  /// Label for the approval checkbox.
  final String approvalLabel;

  /// Label for the confirm button.
  final String buttonLabel;
}

/// The KVKK consent text with translations for all supported languages.
@immutable
class KvkkText {
  const KvkkText({required this.id, required this.translations});

  /// Document identifier loaded from the asset JSON.
  final String id;

  /// Maps BCP 47 language code → localised consent content.
  final Map<String, KvkkTranslation> translations;

  /// Returns the [KvkkTranslation] for [language].
  ///
  /// Falls back to the first available translation if [language] has no
  /// entry in [translations].
  KvkkTranslation translationFor(Language language) =>
      translations[language.code] ?? translations.values.first;
}