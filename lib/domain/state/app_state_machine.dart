import 'app_state.dart';

/// Manages valid [AppState] transitions for the application.
///
/// Only explicitly permitted transitions are allowed; any attempt to move
/// to an invalid next state is rejected and the current state is preserved.
/// Callers are responsible for logging rejected transitions.
///
/// Valid transition table:
/// ```
/// InitializingState → IdleState | ErrorState | PLCErrorState
/// IdleState         → KvkkState | ErrorState | PLCErrorState
/// KvkkState         → QuestionsState | IdleState | PLCErrorState
/// QuestionsState    → QuestionsState | LoadingState | IdleState | PLCErrorState
/// LoadingState      → ResultState | ErrorState | PLCErrorState
/// ResultState       → IdleState | PLCErrorState
/// ErrorState        → IdleState
/// PLCErrorState     → IdleState | PLCErrorState
/// ```
class AppStateMachine {
  /// Creates a state machine starting in [InitializingState].
  AppStateMachine() : _state = const InitializingState();

  AppState _state;

  /// The current application state.
  AppState get state => _state;

  /// Attempts to transition to [next].
  ///
  /// Returns `true` and updates [state] if the transition is valid.
  /// Returns `false` and leaves [state] unchanged if the transition is not
  /// permitted by the transition table.
  bool transition(AppState next) {
    if (!_isValidTransition(_state, next)) return false;
    _state = next;
    return true;
  }

  /// Returns `true` if moving from [current] to [next] is permitted.
  bool _isValidTransition(AppState current, AppState next) {
    return switch (current) {
      InitializingState() =>
        next is IdleState || next is ErrorState || next is PLCErrorState,
      IdleState() =>
        next is KvkkState || next is ErrorState || next is PLCErrorState,
      KvkkState() =>
        next is QuestionsState || next is IdleState || next is PLCErrorState,
      QuestionsState() =>
        next is QuestionsState ||
        next is LoadingState ||
        next is IdleState ||
        next is PLCErrorState,
      LoadingState() =>
        next is ResultState || next is ErrorState || next is PLCErrorState,
      ResultState()   => next is IdleState || next is PLCErrorState,
      ErrorState()    => next is IdleState,
      PLCErrorState() => next is IdleState || next is PLCErrorState,
    };
  }
}