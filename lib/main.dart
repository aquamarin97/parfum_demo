// main.dart file
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'kiosk/android_kiosk_controller.dart';
import 'kiosk/kiosk_mode_controller.dart';
import 'viewmodel/app_view_model_provider.dart';
import 'plc/config/test_register_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ FAZE 1.1 TEST
  await testRegisterConfig();

  await _enableKioskMode();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(
    MultiProvider(
      providers: [AppViewModelProvider.create()],
      child: const ParfumApp(),
    ),
  );
}

Future<void> _enableKioskMode() async {
  final KioskModeController controller = AndroidKioskController();
  await controller.enable();
}