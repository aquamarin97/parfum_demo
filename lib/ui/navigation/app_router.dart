import 'package:flutter/material.dart';
import 'package:parfume_app/ui/screens/plc_error/plc_error_screen.dart';

import '../../domain/state/app_state.dart';
import '../../viewmodel/app_view_model.dart';
import '../screens/error_screen.dart';
import '../screens/idle_screen.dart';
import '../screens/kvkk_screen/kvkk_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/question_screen.dart';
import '../screens/result/result_screen.dart';

/// Maps each [AppState] subtype to its corresponding screen widget.
///
/// The exhaustive switch ensures the compiler forces a router update whenever
/// a new [AppState] subtype is added to the sealed class.
class AppRouter {
  const AppRouter();

  Widget build(AppViewModel viewModel) {
    final state = viewModel.state;

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
          languageCode: viewModel.languageCode,
          technicalDetail: state.exception.technicalDetail,
          onRetry: () async {
            await viewModel.plcService.reconnect();
            if (viewModel.plcService.isConnected) {
              viewModel.resetToIdle();
            }
          },
        ),
      ErrorState()        => ErrorScreen(viewModel: viewModel),
    };
  }
}
