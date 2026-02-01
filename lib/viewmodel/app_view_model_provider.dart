// app_view_model_provider.dart file
import 'package:provider/provider.dart';

import '../core/logging/app_logger.dart';
import '../data/local/asset_json_loader.dart';
import '../data/local/preferences_store.dart';
import '../data/repositories/i18n_repository.dart';
import '../data/repositories/kvkk_repository.dart';
import '../data/repositories/survey_repository.dart';
import '../domain/engine/seeded_random_scoring_engine.dart';
import '../domain/session/session_manager.dart';
import '../viewmodel/app_view_model.dart';
import '../i18n/string_repository.dart';

class AppViewModelProvider {
  static ChangeNotifierProvider<AppViewModel> create() {
    final loader = AssetJsonLoader();
    final prefs = PreferencesStore();
    final surveyRepo = SurveyRepository(loader);
    final kvkkRepo = KvkkRepository(loader);
    final i18nRepo = I18nRepository(StringRepository(loader));
    final sessionManager = SessionManager();
    final engine = SeededRandomScoringEngine();
    final logger = AppLogger();

    return ChangeNotifierProvider<AppViewModel>(
      create: (_) => AppViewModel(
        surveyRepository: surveyRepo,
        kvkkRepository: kvkkRepo,
        i18nRepository: i18nRepo,
        preferencesStore: prefs,
        sessionManager: sessionManager,
        scoringEngine: engine,
        logger: logger,
      )..initialize(),
    );
  }
}