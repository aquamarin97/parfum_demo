import 'package:flutter/foundation.dart';

/// An immutable representation of a supported UI language.
///
/// Equality is based solely on [code] so that language comparisons are
/// locale-independent (e.g. `Language('tr') == Language('tr')`).
@immutable
class Language {
  const Language({
    required this.code,
    required this.label,
    this.isRtl = false,
  });

  /// Deserialises a [Language] from a JSON map.
  ///
  /// Expected keys: `code` (String), `label` (String), `rtl` (bool?).
  factory Language.fromJson(Map<String, dynamic> json) => Language(
        code: json['code'] as String,
        label: json['label'] as String,
        isRtl: (json['rtl'] as bool?) ?? false,
      );

  /// BCP 47 language code (e.g. `'tr'`, `'en'`, `'ar'`).
  final String code;

  /// Short display label shown in the language switcher (e.g. `'TR'`).
  final String label;

  /// Whether this language uses right-to-left text direction.
  final bool isRtl;

  @override
  bool operator ==(Object other) => other is Language && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Language($code)';
}