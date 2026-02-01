// timeout_watcher.dart file
import 'dart:async';
import 'package:flutter/foundation.dart'; // VoidCallback burada tanımlıdır

class TimeoutWatcher {
  TimeoutWatcher({required this.timeout, required this.onTimeout});

  final Duration timeout;
  final VoidCallback onTimeout;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer(timeout, onTimeout);
  }

  void reset() {
    start();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}