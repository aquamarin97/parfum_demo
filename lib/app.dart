// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parfume_app/plc/debug/hidden_button.dart';  // ← EKLE
import 'package:parfume_app/plc/admin/admin_panel_screen.dart';  // ← EKLE

import 'i18n/rtl_support.dart';
import 'ui/components/language_switcher.dart';
import 'ui/navigation/app_router.dart';
import 'ui/theme/app_theme.dart';
import 'viewmodel/app_view_model.dart';

class ParfumApp extends StatelessWidget {
  const ParfumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewModel>(
      builder: (context, viewModel, _) {
        final router = const AppRouter();
        final textDirection = RtlSupport.textDirection(viewModel.language);
        
        return Listener(
          onPointerDown: (_) => viewModel.onUserInteraction(),
          child: PopScope(
            canPop: false,
            child: Directionality(
              textDirection: textDirection,
              child: Scaffold(
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: viewModel.initialized
                          ? router.build(viewModel)
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    
                    Positioned(
                      right: 30,
                      bottom: 30,
                      child: LanguageSwitcher(
                        selected: viewModel.language,
                        onSelect: viewModel.changeLanguage,
                      ),
                    ),
                    
                    // ✅ GİZLİ ADMIN BUTON (Sol alt köşe)
                    HiddenAdminButton(
                      onAccessGranted: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminPanelScreen(
                              plcService: viewModel.plcService,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}