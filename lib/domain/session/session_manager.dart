// session_manager.dart file
import 'package:uuid/uuid.dart';

class SessionManager {
  String _sessionId = const Uuid().v4();

  String get sessionId => _sessionId;

  void resetSession() {
    _sessionId = const Uuid().v4();
  }
}