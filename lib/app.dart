// app.dart file
import 'package:flutter/material.dart';
import 'package:parfume_app/ui/screens/error_screen.dart';
import 'package:parfume_app/ui/screens/loading_indicator.dart';
import 'package:parfume_app/ui/screens/loading_screen.dart';
import 'package:parfume_app/ui/screens/result_screen.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:provider/provider.dart';

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
                    // Positioned.fill(
                    //   child: viewModel.initialized
                    //       ? ResultScreen(
                    //           viewModel: viewModel,
                    //         ) // router.build(viewModel) yerine bunu yazdık
                    //       : const Center(child: CircularProgressIndicator()),
                    // ),
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
