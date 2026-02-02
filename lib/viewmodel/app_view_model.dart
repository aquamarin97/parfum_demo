// app_view_model.dart file
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

class AppStrings {
  const AppStrings({required this.localeCode, required this.values});

  final String localeCode;
  final Map<String, String> values;

  // Mevcut getter'lar
  String get brandName => _value('brand_name');
  String get idleTitle_1 => _value('idle_title_1');
  String get idleTitle_2 => _value('idle_title_2');
  String get idleSubtitle => _value('idle_subtitle');
  String get start => _value('start');
  String get cancel => _value('cancel');
  String get back => _value('back');
  String get loading => _value('loading');
  String get resultTitle => _value('result_title');
  String get recommendationLabel => _value('recommendation_label');
  String get backToStart => _value('back_to_start');
  String get errorTitle => _value('error_title');
  String get errorBody => _value('error_body');

  // ✅ Result ekranı için yeni getter'lar
  String get fragranceRecommendationsSelected => _value('fragrance_recommendations_selected');
  String get testersPreparing => _value('testers_preparing');
  String get testersPrepared => _value('testers_prepared');
  String get customerChoice => _value('customer_choice');
  String get paymentWaiting => _value('payment_waiting');
  String get paymentCompleted => _value('payment_completed');
  String get paymentFailed => _value('payment_failed');
  String get fragrancePreparing => _value('fragrance_preparing');
  String get fragrancePrepared => _value('fragrance_prepared');
  String get giftCardNotCreated => _value('gift_card_not_created');
  
  String get pleaseSelect => _value('please_select');
  String get noPriceDifference => _value('no_price_difference');
  String get priceLabel => _value('price_label');
  String get retryOrCancel => _value('retry_or_cancel');
  String get retryPayment => _value('retry_payment');
  String get cancelPayment => _value('cancel_payment');
  String get giftCardQuestion => _value('gift_card_question');
  String get yes => _value('yes');
  String get no => _value('no');
  String get thankYouMessage => _value('thank_you_message');
  String get goodbyeMessage => _value('goodbye_message');

  String _value(String key) {
    return values[key] ?? '[MISSING: $key]';
  }
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
  })  : _surveyRepository = surveyRepository,
        _kvkkRepository = kvkkRepository,
        _i18nRepository = i18nRepository,
        _preferencesStore = preferencesStore,
        _sessionManager = sessionManager,
        _scoringEngine = scoringEngine,
        _logger = logger,
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

  // ✅ PLC
  late final PLCServiceManager _plcService;
  PLCServiceManager get plcService => _plcService;

  Survey? _survey;
  KvkkText? _kvkkText;
  Map<Language, Map<String, String>> _stringMap = {};
  Language _language = Language.tr;
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

  AppStrings get strings => AppStrings(
        localeCode: _language.code,
        values: _stringMap[_language] ?? {},
      );

  // --- PLC init + error handling ---
  Future<void> _initializePLC() async {
    _plcService = PLCServiceManager(
      autoConnect: true,
      onError: _handlePLCError,
    );
  }

  void _handlePLCError(PLCException error) {
    _logger.log('PLC Error: ${error.errorCode} - ${error.message}');

    // Critical error'larda error state'e geç
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

  // app_view_model.dart içinde güncelleme
  void goToResult() {
    _recommendation = Recommendation.mock();
    _setState(ResultState(_recommendation));
  }

  Future<void> _setup() async {
    try {
      _language = await _preferencesStore.readLanguage() ?? Language.tr;
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

    // PLC tarafında dispose/close varsa çağır (sende hangi isim varsa ona göre düzenle)
    // _plcService.dispose();
    // veya: _plcService.close();

    super.dispose();
  }
}
