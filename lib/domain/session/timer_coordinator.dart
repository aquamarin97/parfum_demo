import 'dart:async';

/// Coordinates the two-phase timer sequence used after survey completion.
///
/// Phase 1 — loading delay: waits [loadingDelay], then calls
/// [onLoadingComplete] and immediately starts phase 2.
///
/// Phase 2 — result countdown: waits [resultDuration], then calls
/// [onResultTimeout] to return the kiosk to the idle screen.
///
/// Both timers can be cancelled at any time via [cancel], which is also
/// called by [dispose]. Cancelling during phase 1 prevents phase 2 from
/// starting.
class TimerCoordinator {
  /// Creates a [TimerCoordinator] with fixed durations and callbacks.
  ///
  /// [loadingDelay] how long to wait before calling [onLoadingComplete].
  /// [resultDuration] how long to display the result before calling
  /// [onResultTimeout].
  /// [onLoadingComplete] called when the loading delay elapses; use this to
  /// compute and display the recommendation result.
  /// [onResultTimeout] called when the result display period elapses; use
  /// this to reset the kiosk to idle.
  TimerCoordinator({
    required Duration loadingDelay,
    required Duration resultDuration,
    required void Function() onLoadingComplete,
    required void Function() onResultTimeout,
  })  : _loadingDelay = loadingDelay,
        _resultDuration = resultDuration,
        _onLoadingComplete = onLoadingComplete,
        _onResultTimeout = onResultTimeout;

  final Duration _loadingDelay;
  final Duration _resultDuration;
  final void Function() _onLoadingComplete;
  final void Function() _onResultTimeout;

  Timer? _loadingTimer;
  Timer? _resultTimer;

  /// Starts phase 1: waits [_loadingDelay], fires [_onLoadingComplete], then
  /// automatically starts [startResultCountdown].
  ///
  /// Any previously running loading timer is cancelled before starting a new
  /// one.
  void startLoadingSequence() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(_loadingDelay, () {
      _onLoadingComplete();
      startResultCountdown();
    });
  }

  /// Starts phase 2: waits [_resultDuration], then fires [_onResultTimeout].
  ///
  /// Called automatically by [startLoadingSequence] and can also be called
  /// directly when the result screen needs to be shown without a loading delay.
  /// Any previously running result timer is cancelled before starting a new one.
  void startResultCountdown() {
    _resultTimer?.cancel();
    _resultTimer = Timer(_resultDuration, _onResultTimeout);
  }

  /// Cancels both the loading and result timers if they are active.
  ///
  /// Safe to call even if no timers are running.
  void cancel() {
    _loadingTimer?.cancel();
    _resultTimer?.cancel();
  }

  /// Cancels all active timers and releases resources.
  void dispose() {
    cancel();
  }
}