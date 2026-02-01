// app_state_machine.dart file
import 'app_state.dart';

class AppStateMachine {
  AppStateMachine() : _state = const IdleState();

  AppState _state;

  AppState get state => _state;

  void transition(AppState next) {
    _state = next;
  }
}
