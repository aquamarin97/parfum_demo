// app_router.dart file
import 'package:flutter/material.dart';
import 'package:parfume_app/ui/screens/result/result_screen.dart';

import '../../domain/state/app_state.dart';
import '../../viewmodel/app_view_model.dart';
import '../screens/error_screen.dart';
import '../screens/idle_screen.dart';
import '../screens/kvkk_screen/kvkk_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/question_screen.dart';

class AppRouter {
  const AppRouter();

  Widget build(AppViewModel viewModel) {
    final state = viewModel.state;
    if (state is IdleState) {
      return IdleScreen(viewModel: viewModel);
    }
    if (state is KvkkState) {
      return KvkkScreen(viewModel: viewModel);
    }
    if (state is QuestionsState) {
      return QuestionScreen(viewModel: viewModel);
    }
    if (state is LoadingState) {
      return LoadingScreen(viewModel: viewModel);
    }
    if (state is ResultState) {
      return ResultScreen(viewModel: viewModel);
    }
    if (state is ErrorState) {
      return ErrorScreen(viewModel: viewModel);
    }
    return ErrorScreen(viewModel: viewModel);
  }
}
