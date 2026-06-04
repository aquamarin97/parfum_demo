import 'dart:async';
import 'package:flutter/foundation.dart';

/// Fires [onTimeout] after [timeout] elapses without a [reset] call.
///
/// Used to detect kiosk inactivity: every pointer-down event calls
/// [reset], so [onTimeout] is only invoked when the user has not
/// interacted for a full [timeout] duration.
///
/// Call [start] once after construction, [reset] on each user
/// interaction, and [stop] when the watcher is no longer needed.
class TimeoutWatcher {
  /// Creates a [TimeoutWatcher].
  ///
  /// [timeout] duration of inactivity before [onTimeout] is called.
  /// [onTimeout] callback invoked when the timeout elapses.
  TimeoutWatcher({required this.timeout, required this.onTimeout});

  /// Inactivity duration after which [onTimeout] is fired.
  final Duration timeout;

  /// Called when [timeout] elapses without a [reset].
  final VoidCallback onTimeout;

  Timer? _timer;

  /// Starts the inactivity timer.
  ///
  /// Safe to call multiple times — cancels any running timer before
  /// starting a new one.
  void start() {
    _timer?.cancel();
    _timer = Timer(timeout, onTimeout);
  }

  /// Restarts the inactivity timer from zero.
  ///
  /// Call this on every user interaction to prevent [onTimeout] from
  /// firing while the user is active.
  void reset() => start();

  /// Cancels the timer and prevents any pending [onTimeout] call.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}