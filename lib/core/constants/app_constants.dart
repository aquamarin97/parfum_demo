class AppConstants {
  static const int totalQuestions = 16;
  static const int totalPerfumes = 24;
  static const int scoringPickCount = 5;
  static const Duration inactivityTimeout = Duration(seconds: 120);
  static const Duration loadingDelay = Duration(milliseconds: 1500);
  static const Duration logoAnimationDuration = Duration(milliseconds: 1500);
  static const Duration questionAnimationDuration = Duration(milliseconds: 600);
  static const Duration resultTransitionDuration = Duration(milliseconds: 400);
  static const Duration resultAutoReturn = Duration(seconds: 400);
  static const int testerButtonBaseDelay = 400;
  static const int testerButtonStaggerDelay = 100;
  static const int timerUrgentThreshold = 60; // seconds
  static const String surveyAssetPath = 'assets/content/survey_questions.json';
  static const String kvkkAssetPath = 'assets/content/kvkk_legal_01.json';
}
