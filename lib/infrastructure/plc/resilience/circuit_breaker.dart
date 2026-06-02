// lib/plc/resilience/circuit_breaker.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Circuit breaker state
enum CircuitState {
  closed,     // Normal operation
  open,       // Failure threshold reached, blocking requests
  halfOpen,   // Testing if service recovered
}

/// Circuit breaker configuration
class CircuitBreakerConfig {
  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.successThreshold = 2,
    this.timeout = const Duration(seconds: 30),
    this.halfOpenTimeout = const Duration(seconds: 10),
  });

  final int failureThreshold;      // Consecutive failures to open
  final int successThreshold;      // Consecutive successes to close
  final Duration timeout;          // How long to stay open
  final Duration halfOpenTimeout;  // Timeout in half-open state

  static const defaultConfig = CircuitBreakerConfig();

  static const aggressive = CircuitBreakerConfig(
    failureThreshold: 3,
    successThreshold: 1,
    timeout: Duration(seconds: 15),
  );

  static const lenient = CircuitBreakerConfig(
    failureThreshold: 10,
    successThreshold: 3,
    timeout: Duration(minutes: 1),
  );
}

/// Circuit breaker implementation
class CircuitBreaker {
  CircuitBreaker({
    required this.name,
    CircuitBreakerConfig? config,
  })  : config = config ?? CircuitBreakerConfig.defaultConfig,
        _state = CircuitState.closed;

  final String name;
  final CircuitBreakerConfig config;

  CircuitState _state;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  Timer? _resetTimer;

  CircuitState get state => _state;
  int get failureCount => _failureCount;
  int get successCount => _successCount;
  bool get isOpen => _state == CircuitState.open;
  bool get isClosed => _state == CircuitState.closed;
  bool get isHalfOpen => _state == CircuitState.halfOpen;

  /// Execute operation through circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    // Open state: Reject immediately
    if (_state == CircuitState.open) {
      _checkIfShouldAttemptReset();
      if (_state == CircuitState.open) {
        throw CircuitBreakerOpenException(name);
      }
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (error) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    _successCount++;

    if (_state == CircuitState.halfOpen) {
      if (_successCount >= config.successThreshold) {
        _transitionTo(CircuitState.closed);
        _successCount = 0;
      }
    }
  }

  void _onFailure() {
    _successCount = 0;
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_state == CircuitState.halfOpen) {
      _transitionTo(CircuitState.open);
      _scheduleReset();
      return;
    }

    if (_failureCount >= config.failureThreshold) {
      _transitionTo(CircuitState.open);
      _scheduleReset();
    }
  }

  void _checkIfShouldAttemptReset() {
    if (_lastFailureTime == null) return;

    final elapsed = DateTime.now().difference(_lastFailureTime!);
    if (elapsed >= config.timeout) {
      _transitionTo(CircuitState.halfOpen);
    }
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(config.timeout, () {
      if (_state == CircuitState.open) {
        _transitionTo(CircuitState.halfOpen);
      }
    });
  }

  void _transitionTo(CircuitState newState) {
    if (_state == newState) return;

    debugPrint('[CircuitBreaker] $name: $_state → $newState');
    _state = newState;

    if (newState == CircuitState.closed) {
      _failureCount = 0;
      _successCount = 0;
      _resetTimer?.cancel();
    }
  }

  /// Manually reset circuit breaker
  void reset() {
    debugPrint('[CircuitBreaker] $name: Manual reset');
    _transitionTo(CircuitState.closed);
    _failureCount = 0;
    _successCount = 0;
    _lastFailureTime = null;
    _resetTimer?.cancel();
  }

  void dispose() {
    _resetTimer?.cancel();
  }
}

/// Exception thrown when circuit breaker is open
class CircuitBreakerOpenException implements Exception {
  CircuitBreakerOpenException(this.circuitName);

  final String circuitName;

  @override
  String toString() =>
      'CircuitBreakerOpenException: Circuit "$circuitName" is open';
}