// lib/plc/error/retry_policy.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Retry stratejisi
enum RetryStrategy {
  fixed,           // Sabit bekleme süresi
  exponential,     // Üstel artan bekleme
  fibonacci,       // Fibonacci serisi
}

/// Retry policy configuration
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 5),
    this.strategy = RetryStrategy.exponential,
    this.shouldRetry,
  });

  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final RetryStrategy strategy;
  final bool Function(Object error)? shouldRetry;

  /// Default policy for connection operations
  static const connection = RetryPolicy(
    maxAttempts: 5,
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 10),
    strategy: RetryStrategy.exponential,
  );

  /// Default policy for read operations
  static const read = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 2),
    strategy: RetryStrategy.fixed,
  );

  /// Default policy for write operations
  static const write = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 2),
    strategy: RetryStrategy.fixed,
  );

  /// Critical operations (no retry)
  static const noRetry = RetryPolicy(maxAttempts: 1);

  /// Calculate delay for given attempt
  Duration calculateDelay(int attempt) {
    switch (strategy) {
      case RetryStrategy.fixed:
        return initialDelay;

      case RetryStrategy.exponential:
        final delay = initialDelay * (1 << (attempt - 1)); // 2^(n-1)
        return delay > maxDelay ? maxDelay : delay;

      case RetryStrategy.fibonacci:
        final fib = _fibonacci(attempt);
        final delay = initialDelay * fib;
        return delay > maxDelay ? maxDelay : delay;
    }
  }

  int _fibonacci(int n) {
    if (n <= 1) return 1;
    int a = 1, b = 1;
    for (int i = 2; i <= n; i++) {
      final temp = a + b;
      a = b;
      b = temp;
    }
    return b;
  }
}

/// Retry executor with policy support
class RetryExecutor {
  const RetryExecutor();

  /// Execute operation with retry policy
  Future<T> execute<T>({
    required Future<T> Function() operation,
    required RetryPolicy policy,
    String? operationName,
    void Function(int attempt, Object error, Duration delay)? onRetry,
  }) async {
    int attempt = 0;
    Object? lastError;

    while (attempt < policy.maxAttempts) {
      attempt++;

      try {
        debugPrint(
          '[RetryExecutor] ${operationName ?? "Operation"} - Attempt $attempt/${policy.maxAttempts}',
        );
        return await operation();
      } catch (error) {
        lastError = error;

        // Son deneme ise hata fırlat
        if (attempt >= policy.maxAttempts) {
          debugPrint(
            '[RetryExecutor] ${operationName ?? "Operation"} - Max attempts reached',
          );
          rethrow;
        }

        // Retry edilebilir mi kontrol et
        if (policy.shouldRetry != null && !policy.shouldRetry!(error)) {
          debugPrint(
            '[RetryExecutor] ${operationName ?? "Operation"} - Error not retryable',
          );
          rethrow;
        }

        // Bekleme süresi hesapla
        final delay = policy.calculateDelay(attempt);
        debugPrint(
          '[RetryExecutor] ${operationName ?? "Operation"} - Retry after ${delay.inMilliseconds}ms',
        );

        // Callback çağır
        onRetry?.call(attempt, error, delay);

        // Bekle
        await Future.delayed(delay);
      }
    }

    // Bu noktaya hiç gelmemeli ama güvenlik için
    throw lastError ?? Exception('Unknown error');
  }
}