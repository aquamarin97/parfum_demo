// app_constants.dart file
class AppConstants {
  static const int totalQuestions = 16;
  static const int totalPerfumes = 24;
  static const int scoringPickCount = 5;
  static const Duration inactivityTimeout = Duration(seconds: 120);
  static const Duration loadingDelay = Duration(milliseconds: 1500);
  static const Duration resultAutoReturn = Duration(seconds: 400);

  static const String surveyAssetPath = 'assets/content/survey_questions.json';
  static const String kvkkAssetPath = 'assets/content/kvkk_legal_01.json';

  static const String stringsTr = 'assets/i18n/strings_tr.json';
  static const String stringsEn = 'assets/i18n/strings_en.json';
  static const String stringsAr = 'assets/i18n/strings_ar.json';
}
