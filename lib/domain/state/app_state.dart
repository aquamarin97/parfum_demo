// app_state.dart file
import 'package:parfume_app/plc/error/plc_error_codes.dart';

import '../../data/models/recommendation.dart';

sealed class AppState {
  const AppState();
}

class IdleState extends AppState {
  const IdleState();
}

class KvkkState extends AppState {
  const KvkkState();
}

class QuestionsState extends AppState {
  const QuestionsState(this.index);

  final int index;
}

class LoadingState extends AppState {
  const LoadingState();
}

class ResultState extends AppState {
  const ResultState(this.recommendation);

  final Recommendation recommendation;
}

class ErrorState extends AppState {
  const ErrorState(this.message);

  final String message;
}

class PLCErrorState extends AppState {
  const PLCErrorState(this.exception);
  final PLCException exception;
}
