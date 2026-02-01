// android_kiosk_controller.dart file
import 'package:flutter/services.dart';

import 'kiosk_mode_controller.dart';

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