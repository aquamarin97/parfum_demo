import 'package:flutter/services.dart';

import 'kiosk_mode_controller.dart';

/// Android implementation of [KioskModeController].
///
/// Locks the display into immersive sticky mode and forces portrait
/// orientation, preventing the customer from accessing system UI or
/// rotating the screen.
class AndroidKioskController implements KioskModeController {
  @override
  Future<void> enable() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
}