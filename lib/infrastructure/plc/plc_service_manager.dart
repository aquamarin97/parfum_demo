import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:parfume_app/domain/plc/i_plc_client.dart';
import 'package:parfume_app/domain/plc/plc_exceptions.dart';

import '../../core/logging/app_logger.dart';

/// Manages the PLC connection lifecycle and surfaces faults to the rest of
/// the application.
///
/// Wraps an [IPlcClient] implementation (injected via constructor) and adds:
/// - connection state tracking via [PLCConnectionState]
/// - automatic reconnect with exponential back-off up to [maxReconnectAttempts]
/// - error propagation through the optional [onError] callback and
///   [ChangeNotifier] so listeners can react to state changes
///
/// The concrete [IPlcClient] is never created inside this class (DIP).
class PLCServiceManager extends ChangeNotifier {
  /// Creates a [PLCServiceManager].
  ///
  /// [client] the PLC client implementation to use.
  /// [logger] application logger; defaults to a debug-level logger.
  /// [autoConnect] when `true`, [initialize] is called immediately.
  /// [onError] optional callback invoked on every [PLCException].
  PLCServiceManager({
    required IPlcClient client,
    AppLogger? logger,
    bool autoConnect = true,
    this.onError,
  })  : _client = client,
        _logger = logger ?? AppLogger() {
    if (autoConnect) initialize();
  }

  final IPlcClient _client;
  final AppLogger _logger;

  /// Optional callback invoked whenever a [PLCException] is handled.
  final void Function(PLCException)? onError;

  PLCConnectionState _state = PLCConnectionState.disconnected;
  PLCException? _lastError;
  DateTime? _lastConnectedTime;
  int _reconnectAttempts = 0;

  /// Maximum number of consecutive reconnect attempts before giving up.
  static const int maxReconnectAttempts = 5;

  /// Current connection state.
  PLCConnectionState get state => _state;

  /// The most recent [PLCException], or `null` if no error has occurred.
  PLCException? get lastError => _lastError;

  /// Whether the PLC is fully connected and ready for communication.
  bool get isConnected => _state == PLCConnectionState.connected;

  /// Whether a connection attempt is currently in progress.
  bool get isConnecting => _state == PLCConnectionState.connecting;

  /// Whether the service is in an error state.
  bool get hasError => _state == PLCConnectionState.error;

  /// The timestamp of the last successful connection, or `null`.
  DateTime? get lastConnectedTime => _lastConnectedTime;

  /// Initiates the PLC connection sequence.
  ///
  /// No-op if a connection attempt is already in progress.
  /// Updates [state] to [PLCConnectionState.connecting] then
  /// [PLCConnectionState.connected] on success, or calls [_handleError]
  /// on failure.
  Future<void> initialize() async {
    if (_state == PLCConnectionState.connecting) {
      _logger.warning('initialize() called while already connecting — skipped.');
      return;
    }

    _updateState(PLCConnectionState.connecting);
    _lastError = null;

    try {
      _logger.info('Starting PLC connection...');
      await _client.connect();
      _lastConnectedTime = DateTime.now();
      _reconnectAttempts = 0;
      _updateState(PLCConnectionState.connected);
      _logger.info('PLC connection established.');
    } on PLCException catch (e) {
      _logger.error('Connection error ${e.errorCode}: ${e.message}');
      _handleError(e);
    } catch (e) {
      _logger.error('Unexpected error during connect: $e');
      _handleError(PLCException(
        errorCode: PLCErrorCodes.unknownError,
        message: 'An unexpected error occurred',
        technicalDetail: e.toString(),
      ));
    }
  }

  /// Closes the PLC connection gracefully.
  ///
  /// Updates [state] to [PLCConnectionState.disconnected] on success.
  /// Errors during disconnect are logged but not re-thrown.
  Future<void> disconnect() async {
    try {
      await _client.disconnect();
      _updateState(PLCConnectionState.disconnected);
      _logger.info('PLC connection closed.');
    } catch (e) {
      _logger.warning('Error while closing connection: $e');
    }
  }

  /// Attempts to re-establish the connection after a failure.
  ///
  /// Increments the internal attempt counter on each call. After
  /// [maxReconnectAttempts] consecutive failures, transitions to an error
  /// state without retrying further.
  ///
  /// Delay between attempts grows exponentially: `2^attempt` seconds
  /// (2 s, 4 s, 8 s, 16 s, 32 s).
  Future<void> reconnect() async {
    _reconnectAttempts++;

    if (_reconnectAttempts > maxReconnectAttempts) {
      _logger.error(
        'Maximum reconnect attempts ($maxReconnectAttempts) exceeded.',
      );
      _handleError(PLCException(
        errorCode: PLCErrorCodes.connectionFailed,
        message: 'Maximum reconnect attempts exceeded',
        technicalDetail: 'Attempt count: $_reconnectAttempts',
      ));
      return;
    }

    final delay = Duration(seconds: 1 << _reconnectAttempts); // 2, 4, 8, 16, 32 s
    _logger.info(
      'Reconnect attempt $_reconnectAttempts / $maxReconnectAttempts '
      '(delay: ${delay.inSeconds} s)...',
    );
    await disconnect();
    await Future.delayed(delay);
    await initialize();
  }

  /// Writes the top-three perfume recommendation IDs to the PLC registers.
  ///
  /// Throws [PLCException] if the write fails; the error is also forwarded
  /// to [_handleError] before re-throwing.
  Future<void> sendRecommendations(List<int> perfumeIds) async {
    _ensureConnected();
    try {
      _logger.debug('Sending recommendations: $perfumeIds');
      await _client.sendRecommendation(perfumeIds);
      _logger.debug('Recommendations sent successfully.');
    } on PLCException catch (e) {
      _logger.error('Send recommendations failed (${e.errorCode}): ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  /// Returns a stream that emits `true` once all testers are physically ready.
  ///
  /// Throws [PLCException] on stream error; the error is also forwarded to
  /// [_handleError] before re-throwing.
  Stream<bool> watchTestersReady() async* {
    _ensureConnected();
    try {
      yield* _client.watchTestersReady();
    } on PLCException catch (e) {
      _logger.error('watchTestersReady error (${e.errorCode}): ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  /// Sends the user's tester selection to the PLC.
  ///
  /// [testerNumber] must be in the range 1–3.
  /// Throws [PLCException] if the write fails.
  Future<void> sendSelectedTester(int testerNumber) async {
    _ensureConnected();
    try {
      _logger.debug('Sending selected tester: $testerNumber');
      await _client.sendSelectedTester(testerNumber);
      _logger.debug('Tester selection sent.');
    } on PLCException catch (e) {
      _logger.error('sendSelectedTester failed (${e.errorCode}): ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  /// Returns a stream that emits the payment status register value whenever
  /// it changes from zero.
  ///
  /// Throws [PLCException] on stream error.
  Stream<int> watchPaymentStatus() async* {
    _ensureConnected();
    try {
      yield* _client.watchPaymentStatus();
    } on PLCException catch (e) {
      _logger.error('watchPaymentStatus error (${e.errorCode}): ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  /// Returns a stream that emits `true` once the perfume dispenser is ready.
  ///
  /// Throws [PLCException] on stream error.
  Stream<bool> watchPerfumeReady() async* {
    _ensureConnected();
    try {
      yield* _client.watchPerfumeReady();
    } on PLCException catch (e) {
      _logger.error('watchPerfumeReady error (${e.errorCode}): ${e.message}');
      _handleError(e);
      rethrow;
    }
  }

  /// Performs a heartbeat read to verify the connection is still alive.
  ///
  /// Returns `false` immediately if [isConnected] is `false`.
  Future<bool> checkHealth() async {
    if (!isConnected) return false;
    try {
      return await _client.healthCheck();
    } catch (e) {
      _logger.warning('Health check failed: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _ensureConnected() {
    if (!isConnected) {
      throw PLCException(
        errorCode: PLCErrorCodes.connectionLost,
        message: 'PLC not connected',
      );
    }
  }

  void _handleError(PLCException error) {
    _lastError = error;
    _updateState(PLCConnectionState.error);
    onError?.call(error);
  }

  void _updateState(PLCConnectionState newState) {
    if (_state == newState) return;
    _logger.debug('PLCConnectionState: ${_state.name} → ${newState.name}');
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.disconnect().ignore();
    super.dispose();
  }
}

/// Represents the lifecycle state of the PLC connection.
enum PLCConnectionState {
  /// No connection has been attempted or the connection was explicitly closed.
  disconnected,

  /// A connection attempt is currently in progress.
  connecting,

  /// The connection is established and the PLC is ready for communication.
  connected,

  /// A fault has occurred; inspect [PLCServiceManager.lastError] for details.
  error,
}