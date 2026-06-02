import 'dart:async';

class TimerCoordinator {
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

  void startLoadingSequence() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(_loadingDelay, () {
      _onLoadingComplete();
      startResultCountdown();
    });
  }

  void startResultCountdown() {
    _resultTimer?.cancel();
    _resultTimer = Timer(_resultDuration, _onResultTimeout);
  }

  void cancel() {
    _loadingTimer?.cancel();
    _resultTimer?.cancel();
  }

  void dispose() {
    cancel();
  }
}
