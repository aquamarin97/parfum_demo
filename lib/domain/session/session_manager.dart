import 'package:uuid/uuid.dart';

/// Manages the lifecycle of a single kiosk session.
///
/// A new session ID is generated when the app starts and on every
/// [resetSession] call (i.e. when the kiosk returns to idle). The ID
/// is passed to the scoring engine so that recommendation results can
/// be correlated with a specific session in logs.
class SessionManager {
  /// Creates a [SessionManager] with an initial session ID.
  SessionManager() : _sessionId = const Uuid().v4();

  final Uuid _uuid = const Uuid();
  String _sessionId;

  /// The current session identifier (UUID v4).
  String get sessionId => _sessionId;

  /// Invalidates the current session and generates a new ID.
  ///
  /// Call this when the kiosk resets to [IdleState] between customers.
  void resetSession() {
    _sessionId = _uuid.v4();
  }
}