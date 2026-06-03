/// Contract for enabling kiosk mode on a target platform.
///
/// Implement this interface for each platform that requires kiosk
/// lockdown behaviour (e.g. [AndroidKioskController]).
abstract interface class KioskModeController {
  /// Enables kiosk mode — locks the UI, hides system chrome, and
  /// applies any platform-specific constraints.
  Future<void> enable();
}