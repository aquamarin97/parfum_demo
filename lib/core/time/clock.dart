/// Contract for obtaining the current time.
///
/// Abstracting time allows tests to inject a fake clock and control
/// time-dependent behaviour deterministically.
abstract interface class Clock {
  /// Returns the current date and time.
  DateTime now();
}

/// Production implementation of [Clock] that delegates to [DateTime.now].
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}