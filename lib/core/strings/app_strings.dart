class AppStrings {
  const AppStrings({required this.localeCode, required this.values});

  final String localeCode;
  final Map<String, String> values;

  String t(String key) => values[key] ?? '[MISSING: $key]';
}
