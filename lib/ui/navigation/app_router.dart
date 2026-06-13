import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parfume_app/ui/screens/plc_error/plc_error_screen.dart';

import '../../domain/state/app_state.dart';
import '../../viewmodel/app_view_model.dart';
import '../screens/error/error_screen.dart';
import '../screens/idle/idle_screen.dart';
import '../screens/kvkk/kvkk_screen.dart';
import '../screens/loading/loading_screen.dart';
import '../screens/question/question_screen.dart';
import '../screens/result/result_screen.dart';

class AppRouter {
  const AppRouter({this.debugOverrideState});

  /// Sadece debug modda geçerlidir. Belirli bir ekranı doğrudan açmak için
  /// [AppState] subtype'ı buraya verin.
  ///
  /// Örnek kullanım (app.dart veya main.dart içinde):
  /// ```dart
  /// AppRouter(debugOverrideState: KvkkState())
  /// AppRouter(debugOverrideState: QuestionsState())
  /// AppRouter(debugOverrideState: ResultState())
  /// ```
  final AppState? debugOverrideState;

  Widget build(AppViewModel viewModel) {
    // Release modda override tamamen devre dışı kalır.
    final state = (kDebugMode && debugOverrideState != null)
        ? debugOverrideState!
        : viewModel.state;

    return switch (state) {
      InitializingState() => const SizedBox.shrink(),
      IdleState()         => IdleScreen(viewModel: viewModel),
      KvkkState()         => KvkkScreen(viewModel: viewModel),
      QuestionsState()    => QuestionScreen(viewModel: viewModel),
      LoadingState()      => LoadingScreen(viewModel: viewModel),
      ResultState()       => ResultScreen(viewModel: viewModel),
      PLCErrorState()     => PLCErrorScreen(
          viewModel: viewModel,
          errorCode: state.exception.errorCode,
          onRetry: () async {
            await viewModel.plcService.initialize();
            if (viewModel.plcService.isConnected) {
              viewModel.resetToIdle();
            }
          },
        ),
      ErrorState()        => ErrorScreen(viewModel: viewModel),
    };
  }
}