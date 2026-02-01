// language.dart file
enum Language {
  tr(code: 'tr', label: 'TR', isRtl: false),
  en(code: 'en', label: 'EN', isRtl: false),
  ar(code: 'ar', label: 'AR', isRtl: true);

  const Language({required this.code, required this.label, required this.isRtl});

  final String code;
  final String label;
  final bool isRtl;
}