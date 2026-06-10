import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:parfume_app/domain/plc/plc_exceptions.dart';
import 'package:parfume_app/infrastructure/plc/plc_service_manager.dart';

import '../core/constants/app_constants.dart';
import '../core/logging/app_logger.dart';
import '../core/strings/app_strings.dart';
import '../domain/session/timer_coordinator.dart';
import 'i_result_context.dart';
import '../data/models/kvkk_text.dart';
import '../data/models/language.dart';
import '../data/models/question.dart';
import '../data/models/recommendation.dart';
import '../data/models/survey.dart';
import '../data/repositories/i_kvkk_repository.dart';
import '../data/repositories/i_string_map_repository.dart';
import '../data/repositories/i_survey_repository.dart';
import '../data/local/preferences_store.dart';
import '../domain/engine/recommendation_engine.dart';
import '../domain/session/session_manager.dart';
import '../domain/session/timeout_watcher.dart';
import '../domain/state/app_state.dart';
import '../domain/state/app_state_machine.dart';
import '../i18n/language_registry.dart';

/// Root view-model for the kiosk application.
///
/// Owns the [AppStateMachine], coordinates all repositories, and exposes the
/// current [AppState] to the widget tree via [ChangeNotifier]. Also implements
/// [IResultContext] so that result-screen view-models can depend on the narrow
/// interface rather than this concrete class.
///
/// Lifecycle:
/// 1. Constructed and wired by [AppViewModelProvider].
/// 2. [initialize] is called once; it triggers [_setup] which loads all
///    assets and transitions from [InitializingState] to [IdleState].
/// 3. User interactions drive further state transitions via public methods.
/// 4. [dispose] cancels all timers and listeners.
class AppViewModel extends ChangeNotifier implements IResultContext {
  /// Creates an [AppViewModel] with all required dependencies injected.
  ///
  /// Call [initialize] after construction to start the async setup sequence.
  AppViewModel({
    required ISurveyRepository surveyRepository,
    required IKvkkRepository kvkkRepository,
    required IStringMapRepository i18nRepository,
    required PreferencesStore preferencesStore,
    required SessionManager sessionManager,
    required RecommendationEngine scoringEngine,
    required AppLogger logger,
    required LanguageRegistry languageRegistry,
    required PLCServiceManager plcService,
  })  : _surveyRepository = surveyRepository,
        _kvkkRepository = kvkkRepository,
        _i18nRepository = i18nRepository,
        _preferencesStore = preferencesStore,
        _sessionManager = sessionManager,
        _scoringEngine = scoringEngine,
        _logger = logger,
        _languageRegistry = languageRegistry,
        _stateMachine = AppStateMachine(),
        _plcService = plcService {
    _plcService.addListener(_onPLCStateChanged);
    _timerCoordinator = TimerCoordinator(
      loadingDelay: AppConstants.loadingDelay,
      resultDuration: AppConstants.resultAutoReturn,
      onLoadingComplete: () {
        _recommendation = _scoringEngine.buildRecommendation(_scores, top: 3);
        _setState(ResultState(_recommendation));
      },
      onResultTimeout: resetToIdle,
    );
  }

  final ISurveyRepository _surveyRepository;
  final IKvkkRepository _kvkkRepository;
  final IStringMapRepository _i18nRepository;
  final PreferencesStore _preferencesStore;
  final SessionManager _sessionManager;
  final RecommendationEngine _scoringEngine;
  final AppLogger _logger;
  final AppStateMachine _stateMachine;
  final LanguageRegistry _languageRegistry;
  final PLCServiceManager _plcService;

  Survey? _survey;
  KvkkText? _kvkkText;
  Map<String, Map<String, String>> _stringMap = {};

  /// Temporary placeholder until [_setup] resolves the persisted language.
  Language _language = const Language(code: 'tr', label: 'TR');
  Map<int, int> _answers = {};
  Map<int, int> _scores = {};
  Recommendation _recommendation = Recommendation(topIds: []);

  int _languageVersion = 0;
  int get languageVersion => _languageVersion;

  /// Guards against calling [initialize] more than once.
  bool _setupStarted = false;

  /// Becomes `true` when [_setup] completes (successfully or with an error).
  /// The UI waits for this flag before rendering any screen.
  bool _initialized = false;

  TimeoutWatcher? _timeoutWatcher;
  late final TimerCoordinator _timerCoordinator;
  Timer? _watchdogTimer;
  static const _watchdogInterval = Duration(seconds: 30);
  AppStrings? _cachedStrings;

  /// The current application state.
  AppState get state => _stateMachine.state;

  /// The active [Language] used for all UI strings.
  Language get language => _language;

  /// Whether initial setup has completed and the UI may be rendered.
  bool get initialized => _initialized;

  /// Languages available for selection, as loaded from the language registry.
  List<Language> get availableLanguages => _languageRegistry.available;

  /// The [PLCServiceManager] instance, exposed for admin panel access.
  PLCServiceManager get plcService => _plcService;

  /// Returns the localised string map for the active language.
  ///
  /// Result is cached; the cache is invalidated when the language changes.
  /// Falls back to the first available language if the active language has no
  /// loaded strings, and to an empty map if no languages are available at all.
  @override
  AppStrings get strings => _cachedStrings ??= _buildStrings();

  AppStrings _buildStrings() {
    final values = _stringMap[_language.code];
    if (values != null && values.isNotEmpty) {
      return AppStrings(localeCode: _language.code, values: values);
    }
    final fallbackCode = _languageRegistry.available.isNotEmpty
        ? _languageRegistry.available.first.code
        : 'tr';
    return AppStrings(
      localeCode: _language.code,
      values: _stringMap[fallbackCode] ?? {},
    );
  }

  @override
  List<int> get topIds => _recommendation.topIds;

  @override
  String get languageCode => _language.code;

  /// The [QuestionTranslation] for the question currently shown.
  ///
  /// Must only be called while [state] is [QuestionsState].
  QuestionTranslation get currentQuestion => _survey!
      .questions[(state as QuestionsState).index]
      .translationFor(_language);

  /// The option index previously selected for the current question, or `null`.
  ///
  /// Must only be called while [state] is [QuestionsState].
  int? get currentSelectionIndex {
    final questionId =
        _survey!.questions[(state as QuestionsState).index].id;
    return _answers[questionId];
  }

  /// Human-readable progress label, e.g. `'3/16'`.
  ///
  /// Must only be called while [state] is [QuestionsState].
  String get progressLabel {
    final index = (state as QuestionsState).index + 1;
    return '$index/${AppConstants.totalQuestions}';
  }

  /// Whether the user can navigate to the previous question.
  bool get canGoBack =>
      (state is QuestionsState) && (state as QuestionsState).index > 0;

  /// The KVKK consent text for the active language.
  ///
  /// Must only be called while [state] is [KvkkState] and after [_setup]
  /// has completed.
  KvkkTranslation get kvkkText => _kvkkText!.translationFor(_language);

  /// The most recent recommendation computed by the scoring engine.
  Recommendation get recommendation => _recommendation;

  /// Alias for [language]; provided for clarity in contexts where the
  /// distinction between locale and language object matters.
  Language get currentLanguage => _language;

  /// Starts the async initialisation sequence exactly once.
  ///
  /// Safe to call multiple times; subsequent calls are no-ops.
  void initialize() {
    if (_setupStarted) return;
    _setupStarted = true;
    _setup();
  }

  /// Transitions directly to [ResultState] with mock data.
  ///
  /// Debug builds only — no-op in release to prevent mock data reaching
  /// production kiosks.
  void goToResult() {
    if (!kDebugMode) return;
    _recommendation = Recommendation.mock();
    _setState(ResultState(_recommendation));
  }

  /// Loads all assets, resolves the saved language, and starts the inactivity
  /// watcher before transitioning to [IdleState].
  ///
  /// On failure, transitions to [ErrorState] with the error description.
  Future<void> _setup() async {
    try {
      await _languageRegistry.load();
      final savedCode = await _preferencesStore.readLanguageCode();
      _language = _languageRegistry.findByCode(
        savedCode ?? _languageRegistry.available.first.code,
      );
      await _preferencesStore.readOrCreateDeviceId();
      _survey = await _surveyRepository.loadSurvey();
      _kvkkText = await _kvkkRepository.loadKvkk();
      _stringMap = await _i18nRepository.loadStrings();
      _timeoutWatcher = TimeoutWatcher(
        timeout: AppConstants.inactivityTimeout,
        onTimeout: _handleTimeout,
      )..start();
      _startWatchdog();
      _logger.log('App initialized');
      _initialized = true;
      _setState(const IdleState());
    } catch (error) {
      _logger.log('Initialization failed: $error');
      // Set to true even on failure so the UI exits the loading screen.
      _initialized = true;
      _setState(ErrorState(error.toString()));
    }
  }

  /// Notifies the inactivity watcher that the user is active.
  ///
  /// Should be called on every pointer-down event at the root of the widget
  /// tree.
  void onUserInteraction() {
    _timeoutWatcher?.reset();
  }

  /// Transitions to [KvkkState] to begin the consent flow.
  void startKvkk() {
    _logger.log('Transition to KVKK');
    _setState(const KvkkState());
  }

  /// Transitions to [QuestionsState] at index 0 to begin the survey.
  void startQuestions() {
    _logger.log('Start questions');
    _setState(const QuestionsState(0));
  }

  /// Records the user's answer for the current question and advances the flow.
  ///
  /// If this is the last question, transitions to [LoadingState] and starts
  /// the loading sequence. Otherwise advances to the next question.
  void answerCurrentQuestion(int optionIndex) {
    if (state is! QuestionsState) return;
    final question =
        _survey!.questions[(state as QuestionsState).index];
    _answers[question.id] = optionIndex;
    _scores = _scoringEngine.computeScores(
      sessionId: _sessionManager.sessionId,
      answers: _answers,
    );

    final lastIndex = _survey!.questions.length - 1;
    if ((state as QuestionsState).index >= lastIndex) {
      _setState(const LoadingState());
      _startLoadingSequence();
    } else {
      final nextIndex = (state as QuestionsState).index + 1;
      _setState(QuestionsState(nextIndex));
    }
  }

  /// Navigates to the previous survey question.
  ///
  /// No-op if already at the first question or not in [QuestionsState].
  void goBackQuestion() {
    if (state is! QuestionsState) return;
    final index = (state as QuestionsState).index;
    if (index == 0) return;
    _setState(QuestionsState(index - 1));
  }

  @override
  void cancelToIdle() {
    // Semantically distinct from resetToIdle: signals the user deliberately
    // abandoned the flow (useful for future analytics). Behaviour is identical
    // today but the two entry-points are kept separate to allow divergence.
    _logger.log('User cancelled — returning to idle');
    resetToIdle();
  }

  @override
  void resetToIdle() {
    _resetSession();
    _setState(const IdleState());
  }

  /// Changes the active language and persists the choice.
  ///
  /// No-op if [language] is already the active language.
  /// The current screen stays active and rebuilds with the new language.
  void changeLanguage(Language language) {
    if (_language == language) return;
    _language = language;
    _languageVersion++;
    _cachedStrings = null;
    _preferencesStore.saveLanguage(language);
    _logger.log('Language changed to ${language.code}');
    notifyListeners();
  }

  void _resetSession() {
    _answers = {};
    _scores = {};
    _recommendation = Recommendation(topIds: []);
    _sessionManager.resetSession();
    _timerCoordinator.cancel();
  }

  void _startLoadingSequence() {
    _timerCoordinator.startLoadingSequence();
  }

  void onAdminPanelOpened() {
    _timeoutWatcher?.stop();
    _logger.log('Admin panel opened — inactivity timeout suspended.');
  }

  void onAdminPanelClosed() {
    _timeoutWatcher?.start();
    _logger.log('Admin panel closed — inactivity timeout resumed.');
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(_watchdogInterval, (_) {
      _logger.log('Watchdog tick — state: ${_stateMachine.state.runtimeType}');
      if (_stateMachine.state is LoadingState) {
        _logger.log('Watchdog: stuck in LoadingState — resetting.');
        resetToIdle();
      }
    });
  }

  void _handleTimeout() {
    _logger.log('Inactivity timeout');
    resetToIdle();
  }

  /// Reacts to [PLCServiceManager] state changes.
  ///
  /// Promotes connection-level faults to [PLCErrorState].
  void _onPLCStateChanged() {
    final error = _plcService.lastError;
    if (_plcService.hasError && error != null) _handlePLCError(error);
  }

  void _handlePLCError(PLCException error) {
    _logger.log('PLC Error: ${error.errorCode} - ${error.message}');
    if (error.errorCode == PLCErrorCodes.connectionFailed ||
        error.errorCode == PLCErrorCodes.connectionLost) {
      _setState(PLCErrorState(error));
    }
  }

  /// Attempts the state transition and logs rejected transitions.
  void _setState(AppState next) {
    if (!_stateMachine.transition(next)) {
      _logger.log(
        'Invalid transition: '
        '${_stateMachine.state.runtimeType} → ${next.runtimeType}',
      );
      return;
    }
    _logger.log('State → ${next.runtimeType}');
    notifyListeners();
  }

  @override
  void dispose() {
    _plcService.removeListener(_onPLCStateChanged);
    _timerCoordinator.dispose();
    _timeoutWatcher?.stop();
    _watchdogTimer?.cancel();
    super.dispose();
  }
}