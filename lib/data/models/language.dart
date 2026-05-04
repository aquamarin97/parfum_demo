import 'package:flutter/foundation.dart';

@immutable
class Language {
  const Language({required this.code, required this.label, this.isRtl = false});

  factory Language.fromJson(Map<String, dynamic> json) => Language(
        code: json['code'] as String,
        label: json['label'] as String,
        isRtl: (json['rtl'] as bool?) ?? false,
      );

  final String code;
  final String label;
  final bool isRtl;

  @override
  bool operator ==(Object other) => other is Language && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Language($code)';
}
