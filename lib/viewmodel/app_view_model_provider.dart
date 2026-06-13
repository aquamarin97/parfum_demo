import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:parfume_app/data/plc/modbus_plc_client.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../core/logging/app_logger.dart';
import '../core/logging/rotating_file_log_writer.dart';
import '../data/local/asset_json_loader.dart';
import '../data/local/preferences_store.dart';
import '../data/repositories/i18n_repository.dart';
import '../data/repositories/kvkk_repository.dart';
import '../data/repositories/survey_repository.dart';
import '../domain/engine/rule_based_scoring_engine.dart';
import '../domain/session/session_manager.dart';
import '../i18n/language_registry.dart';
import '../i18n/sources/asset_string_source.dart';
import '../i18n/sources/filesystem_string_source.dart';
import '../i18n/string_repository.dart';
import '../infrastructure/plc/plc_service_manager.dart';
import '../viewmodel/app_view_model.dart';

/// Composition root for [AppViewModel] and its dependencies.
///
/// All concrete implementations are instantiated and wired here so that
/// [AppViewModel] itself depends only on interfaces and abstract types.
class AppViewModelProvider {
  /// Creates a fully wired [ChangeNotifierProvider] for [AppViewModel].
  ///
  /// Dependency order: logger → repositories → i18n → engine → PLC → view-model.
  static ChangeNotifierProvider<AppViewModel> create() {
    final loader = AssetJsonLoader();
    final prefs = PreferencesStore();
    final surveyRepo = SurveyRepository(loader);
    final kvkkRepo = KvkkRepository(loader);

    final registry = LanguageRegistry();

    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final logDir = p.join(exeDir, 'logs');
    final fsI18nPath = p.join(exeDir, 'i18n');

    final logger = AppLogger(
      writer: RotatingFileLogWriter(logDirectory: logDir),
      minimumLevel: kDebugMode ? LogLevel.debug : LogLevel.info,
    );

    // Filesystem source: i18n/ directory next to the executable (USB update).

    final stringRepo = StringRepository(
      [
        FilesystemStringSource(fsI18nPath), // USB/filesystem first
        const AssetStringSource(),          // Bundled asset fallback
      ],
      logger,
    );

    final i18nRepo = I18nRepository(stringRepo, registry);
    final sessionManager = SessionManager();
    final engine = RuleBasedScoringEngine();

    final plcClient = ModbusPLCClient();
    final plcService = PLCServiceManager(
      client: plcClient,
      logger: logger,
      autoConnect: true,
    );

    return ChangeNotifierProvider<AppViewModel>(
      create: (_) => AppViewModel(
        surveyRepository: surveyRepo,
        kvkkRepository: kvkkRepo,
        i18nRepository: i18nRepo,
        preferencesStore: prefs,
        sessionManager: sessionManager,
        scoringEngine: engine,
        logger: logger,
        languageRegistry: registry,
        plcService: plcService,
      )..initialize(),
    );
  }
}
