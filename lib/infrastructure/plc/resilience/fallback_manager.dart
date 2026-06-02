// lib/plc/resilience/fallback_manager.dart
import 'package:flutter/foundation.dart';

/// Fallback mode
enum FallbackMode {
  normal,      // PLC connected and working
  degraded,    // PLC connected but unreliable
  mock,        // PLC not available, using mock data
  offline,     // Complete offline mode
}

/// Fallback strategy for different operations
class FallbackStrategy {
  const FallbackStrategy({
    required this.mode,
    required this.canContinue,
    this.mockData,
    this.userMessage,
  });

  final FallbackMode mode;
  final bool canContinue;
  final dynamic mockData;
  final String? userMessage;
}

/// Fallback manager
class FallbackManager extends ChangeNotifier {
  FallbackManager() : _currentMode = FallbackMode.normal;

  FallbackMode _currentMode;
  int _degradedOperations = 0;
  int _failedOperations = 0;
  DateTime? _lastSuccessfulOperation;

  FallbackMode get currentMode => _currentMode;
  bool get isNormal => _currentMode == FallbackMode.normal;
  bool get isDegraded => _currentMode == FallbackMode.degraded;
  bool get isMock => _currentMode == FallbackMode.mock;
  bool get isOffline => _currentMode == FallbackMode.offline;

  /// Check if operation can continue in current mode
  bool canContinueOperation(String operationType) {
    switch (_currentMode) {
      case FallbackMode.normal:
        return true;

      case FallbackMode.degraded:
        // Critical operations only
        return _isCriticalOperation(operationType);

      case FallbackMode.mock:
        // User-facing operations only
        return _isUserFacingOperation(operationType);

      case FallbackMode.offline:
        return false;
    }
  }

  /// Get fallback strategy for operation
  FallbackStrategy getStrategy(String operationType) {
    switch (_currentMode) {
      case FallbackMode.normal:
        return FallbackStrategy(
          mode: FallbackMode.normal,
          canContinue: true,
        );

      case FallbackMode.degraded:
        return FallbackStrategy(
          mode: FallbackMode.degraded,
          canContinue: _isCriticalOperation(operationType),
          userMessage: 'PLC bağlantısı yavaş. Lütfen bekleyin.',
        );

      case FallbackMode.mock:
        return FallbackStrategy(
          mode: FallbackMode.mock,
          canContinue: _isUserFacingOperation(operationType),
          mockData: _getMockData(operationType),
          userMessage: 'Demo modunda çalışılıyor.',
        );

      case FallbackMode.offline:
        return FallbackStrategy(
          mode: FallbackMode.offline,
          canContinue: false,
          userMessage: 'PLC bağlantısı yok. Lütfen teknik destek çağırın.',
        );
    }
  }

  /// Record successful operation
  void recordSuccess() {
    _lastSuccessfulOperation = DateTime.now();
    _degradedOperations = 0;
    _failedOperations = 0;

    if (_currentMode != FallbackMode.normal) {
      _transitionTo(FallbackMode.normal);
    }
  }

  /// Record degraded operation (slow but successful)
  void recordDegraded() {
    _degradedOperations++;
    _lastSuccessfulOperation = DateTime.now();

    // 5 consecutive degraded operations → degraded mode
    if (_degradedOperations >= 5 && _currentMode == FallbackMode.normal) {
      _transitionTo(FallbackMode.degraded);
    }
  }

  /// Record failed operation
  void recordFailure() {
    _failedOperations++;

    // Transition logic
    if (_currentMode == FallbackMode.normal) {
      if (_failedOperations >= 3) {
        _transitionTo(FallbackMode.degraded);
      }
    } else if (_currentMode == FallbackMode.degraded) {
      if (_failedOperations >= 5) {
        _transitionTo(FallbackMode.mock);
      }
    } else if (_currentMode == FallbackMode.mock) {
      if (_failedOperations >= 10) {
        _transitionTo(FallbackMode.offline);
      }
    }
  }

  /// Manually set fallback mode
  void setMode(FallbackMode mode) {
    _transitionTo(mode);
  }

  /// Reset to normal mode
  void reset() {
    _transitionTo(FallbackMode.normal);
    _degradedOperations = 0;
    _failedOperations = 0;
  }

  void _transitionTo(FallbackMode newMode) {
    if (_currentMode == newMode) return;

    debugPrint('[FallbackManager] $_currentMode → $newMode');
    _currentMode = newMode;
    notifyListeners();
  }

  bool _isCriticalOperation(String operationType) {
    // Critical operations that must work even in degraded mode
    return operationType == 'heartbeat' ||
        operationType == 'emergency_stop' ||
        operationType == 'system_status';
  }

  bool _isUserFacingOperation(String operationType) {
    // Operations that can use mock data for demo
    return operationType == 'send_recommendations' ||
        operationType == 'check_tester_ready' ||
        operationType == 'check_payment_status' ||
        operationType == 'check_perfume_ready';
  }

  dynamic _getMockData(String operationType) {
    switch (operationType) {
      case 'check_tester_ready':
        return true;
      case 'check_payment_status':
        return 1; // Payment complete
      case 'check_perfume_ready':
        return true;
      default:
        return null;
    }
  }
}

/// Mock data provider for fallback mode
class MockPLCDataProvider {
  static const mockRecommendations = [101, 202, 303];
  
  static bool get testerReady => true;
  
  static int get paymentStatus => 1; // Completed
  
  static bool get perfumeReady => true;
  
  static int get heartbeat => DateTime.now().millisecondsSinceEpoch % 65536;

  /// Simulate PLC operation with mock data
  static Future<T> simulateOperation<T>(
    T data, {
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    await Future.delayed(delay);
    return data;
  }
}