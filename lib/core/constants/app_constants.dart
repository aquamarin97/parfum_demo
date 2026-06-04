/// Application-wide constants shared across layers.
///
/// UI sizing tokens live in [AppSizes]; colors in [AppColors] and
/// [AdminColors]. Only values that are genuinely cross-cutting belong here.
class AppConstants {
  // ── Survey ────────────────────────────────────────────────────────────────

  /// Total number of survey questions presented to the customer.
  static const int totalQuestions = 16;

  /// Total number of perfumes in the catalogue.
  static const int totalPerfumes = 24;

  /// Number of top-scoring perfumes passed to the recommendation engine.
  static const int scoringPickCount = 5;

  // ── Timeouts & delays ─────────────────────────────────────────────────────

  /// How long the kiosk waits without interaction before resetting to idle.
  static const Duration inactivityTimeout = Duration(seconds: 120);

  /// Artificial delay shown on the loading screen while results are computed.
  static const Duration loadingDelay = Duration(milliseconds: 1500);

  /// How long the result screen is shown before the kiosk resets to idle.
  static const Duration resultAutoReturn = Duration(seconds: 400);

  /// Remaining seconds below which the countdown timer switches to urgent style.
  static const int timerUrgentThreshold = 60;

  // ── Animation durations ───────────────────────────────────────────────────

  /// Duration of the logo entry animation on the idle and question screens.
  static const Duration logoAnimationDuration = Duration(milliseconds: 1500);

  /// Duration of the question text slide-in animation.
  static const Duration questionAnimationDuration = Duration(milliseconds: 600);

  /// Duration of the result content fade/slide transition.
  static const Duration resultTransitionDuration = Duration(milliseconds: 400);

  // ── Tester button stagger ─────────────────────────────────────────────────

  /// Base entry animation delay for tester buttons, in milliseconds.
  static const int testerButtonBaseDelay = 400;

  /// Additional delay per button index for staggered entry, in milliseconds.
  static const int testerButtonStaggerDelay = 100;

  // ── Asset paths ───────────────────────────────────────────────────────────

  /// Asset path for the survey question set.
  static const String surveyAssetPath = 'assets/content/survey_questions.json';

  /// Asset path for the KVKK consent text.
  static const String kvkkAssetPath = 'assets/content/kvkk_legal_01.json';

  // ── Admin ─────────────────────────────────────────────────────────────────

  /// Password required to access the admin panel.
  ///
  /// TODO: replace with a secure value before release.
  static const String adminPassword = '1234';
}