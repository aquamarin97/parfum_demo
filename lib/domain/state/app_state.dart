import 'package:parfume_app/domain/plc/plc_exceptions.dart';

import '../../data/models/recommendation.dart';

/// Base class for all application states.
///
/// The state machine ([AppStateMachine]) controls valid transitions between
/// subtypes. UI routing ([AppRouter]) switches exhaustively over this sealed
/// class, so adding a new subtype produces a compile-time error in both places.
sealed class AppState {
  const AppState();
}

/// Initial state while the app is loading its configuration and assets.
///
/// Transitions to [IdleState] on success or [ErrorState] on failure.
class InitializingState extends AppState {
  const InitializingState();
}

/// The app is idle and waiting for user interaction.
///
/// This is the resting state shown on the kiosk home screen.
class IdleState extends AppState {
  const IdleState();
}

/// The KVKK (data-privacy consent) screen is being shown.
class KvkkState extends AppState {
  const KvkkState();
}

/// A survey question at [index] is being presented to the user.
///
/// [index] is zero-based and must be within the bounds of the loaded
/// question list.
class QuestionsState extends AppState {
  const QuestionsState(this.index);

  /// Zero-based index of the current survey question.
  final int index;
}

/// The recommendation engine is computing results.
///
/// The UI shows a loading indicator during this state.
class LoadingState extends AppState {
  const LoadingState();
}

/// Fragrance recommendations have been computed and are ready to display.
class ResultState extends AppState {
  const ResultState(this.recommendation);

  /// The computed recommendation to present to the user.
  final Recommendation recommendation;
}

/// A non-PLC application error has occurred.
///
/// [message] is an English technical description intended for logging and
/// the developer-facing error screen.
class ErrorState extends AppState {
  const ErrorState(this.message);

  /// English technical error description.
  final String message;
}

/// A PLC communication or state fault has occurred.
///
/// Transitions back to [IdleState] after a successful reconnect, or remains
/// in this state while retry attempts are in progress.
class PLCErrorState extends AppState {
  const PLCErrorState(this.exception);

  /// The PLC fault that caused this state transition.
  final PLCException exception;
}