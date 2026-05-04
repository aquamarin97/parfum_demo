import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:parfume_app/plc/error/plc_error_codes.dart';
import 'package:parfume_app/plc/plc_service_manager.dart';

import '../core/constants/app_constants.dart';
import '../core/logging/app_logger.dart';
import '../data/models/kvkk_text.dart';
import '../data/models/language.dart';
import '../data/models/question.dart';
import '../data/models/recommendation.dart';
import '../data/models/survey.dart';
import '../data/repositories/i18n_repository.dart';
import '../data/repositories/kvkk_repository.dart';
import '../data/repositories/survey_repository.dart';
import '../data/local/preferences_store.dart';
import '../domain/engine/recommendation_engine.dart';
import '../domain/session/session_manager.dart';
import '../domain/session/timeout_watcher.dart';
import '../domain/state/app_state.dart';
import '../domain/state/app_state_machine.dart';
import '../i18n/language_registry.dart';

class AppStrings {
  const AppStrings({required this.localeCode, required this.values});

  final String localeCode;
  final Map<String, String> values;

  String t(String key) => values[key] ?? '[MISSING: $key]';
}

class AppViewModel extends ChangeNotifier {
  AppViewModel({
    required SurveyRepository surveyRepository,
    required KvkkRepository kvkkRepository,
    required I18nRepository i18nRepository,
    required PreferencesStore preferencesStore,
    required SessionManager sessionManager,
    required RecommendationEngine scoringEngine,
    required AppLogger logger,
    required LanguageRegistry languageRegistry,
  })  : _surveyRepository = surveyRepository,
        _kvkkRepository = kvkkRepository,
        _i18nRepository = i18nRepository,
        _preferencesStore = preferencesStore,
        _sessionManager = sessionManager,
        _scoringEngine = scoringEngine,
        _logger = logger,
        _languageRegistry = languageRegistry,
        _stateMachine = AppStateMachine() {
    _initializePLC();
  }

  final SurveyRepository _surveyRepository;
  final KvkkRepository _kvkkRepository;
  final I18nRepository _i18nRepository;
  final PreferencesStore _preferencesStore;
  final SessionManager _sessionManager;
  final RecommendationEngine _scoringEngine;
  final AppLogger _logger;
  final AppStateMachine _stateMachine;
  final LanguageRegistry _languageRegistry;

  late final PLCServiceManager _plcService;
  PLCServiceManager get plcService => _plcService;

  Survey? _survey;
  KvkkText? _kvkkText;
  Map<String, Map<String, String>> _stringMap = {};
  // _setup() çalışana kadar geçici yer tutucu; registry yüklendikten sonra güncellenir.
  Language _language = const Language(code: 'tr', label: 'TR');
  Map<int, int> _answers = {};
  Map<int, int> _scores = {};
  Recommendation _recommendation = Recommendation(topIds: []);
  bool _initialized = false;
  TimeoutWatcher? _timeoutWatcher;
  Timer? _loadingTimer;
  Timer? _resultTimer;

  AppState get state => _stateMachine.state;
  Language get language => _language;
  bool get initialized => _initialized;
  List<Language> get availableLanguages => _languageRegistry.available;

  AppStrings get strings {
    final values = _stringMap[_language.code];
    if (values != null && values.isNotEmpty) {
      return AppStrings(localeCode: _language.code, values: values);
    }
    // Seçilen dilin çeviri dosyası yoksa listedeki ilk dile düş.
    final fallbackCode = _languageRegistry.available.isNotEmpty
        ? _languageRegistry.available.first.code
        : 'tr';
    return AppStrings(
      localeCode: _language.code,
      values: _stringMap[fallbackCode] ?? {},
    );
  }

  Future<void> _initializePLC() async {
    _plcService = PLCServiceManager(
      autoConnect: true,
      onError: _handlePLCError,
    );
  }

  void _handlePLCError(PLCException error) {
    _logger.log('PLC Error: ${error.errorCode} - ${error.message}');

    if (error.errorCode == PLCErrorCodes.connectionFailed ||
        error.errorCode == PLCErrorCodes.connectionLost) {
      _setState(PLCErrorState(error));
    }
  }

  QuestionTranslation get currentQuestion => _survey!
      .questions[(state as QuestionsState).index]
      .translationFor(_language);

  int? get currentSelectionIndex {
    final questionId = _survey!.questions[(state as QuestionsState).index].id;
    return _answers[questionId];
  }

  String get progressLabel {
    final index = (state as QuestionsState).index + 1;
    return '$index/${AppConstants.totalQuestions}';
  }

  bool get canGoBack =>
      (state is QuestionsState) && (state as QuestionsState).index > 0;

  KvkkTranslation get kvkkText => _kvkkText!.translationFor(_language);

  Recommendation get recommendation => _recommendation;
  Language get currentLanguage => _language;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _setup();
  }

  void goToResult() {
    _recommendation = Recommendation.mock();
    _setState(ResultState(_recommendation));
  }

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
      _logger.log('App initialized');
      _setState(const IdleState());
    } catch (error) {
      _logger.log('Initialization failed: $error');
      _setState(ErrorState(error.toString()));
    }
  }

  void onUserInteraction() {
    _timeoutWatcher?.reset();
  }

  void startKvkk() {
    _logger.log('Transition to KVKK');
    _setState(const KvkkState());
  }

  void startQuestions() {
    _logger.log('Start questions');
    _setState(const QuestionsState(0));
  }

  void answerCurrentQuestion(int optionIndex) {
    if (state is! QuestionsState) return;
    final question = _survey!.questions[(state as QuestionsState).index];
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

  void goBackQuestion() {
    if (state is! QuestionsState) return;
    final index = (state as QuestionsState).index;
    if (index == 0) return;
    _setState(QuestionsState(index - 1));
  }

  void cancelToIdle() {
    _logger.log('Cancel to idle');
    resetToIdle();
  }

  void resetToIdle() {
    _resetSession();
    _setState(const IdleState());
  }

  void changeLanguage(Language language) {
    if (_language == language) return;
    _language = language;
    _preferencesStore.saveLanguage(language);
    _logger.log('Language changed to ${language.code}');
    resetToIdle();
    notifyListeners();
  }

  void _resetSession() {
    _answers = {};
    _scores = {};
    _recommendation = Recommendation(topIds: []);
    _sessionManager.resetSession();
    _loadingTimer?.cancel();
    _resultTimer?.cancel();
  }

  void _startLoadingSequence() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(AppConstants.loadingDelay, () {
      _recommendation = _scoringEngine.buildRecommendation(_scores, top: 3);
      _setState(ResultState(_recommendation));
      _startResultAutoReturn();
    });
  }

  void _startResultAutoReturn() {
    _resultTimer?.cancel();
    _resultTimer = Timer(AppConstants.resultAutoReturn, () {
      resetToIdle();
    });
  }

  void _handleTimeout() {
    _logger.log('Inactivity timeout');
    resetToIdle();
  }

  void _setState(AppState next) {
    _stateMachine.transition(next);
    _logger.log('State -> ${next.runtimeType}');
    notifyListeners();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _resultTimer?.cancel();
    _timeoutWatcher?.stop();
    super.dispose();
  }
}
