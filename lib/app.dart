import 'package:flutter/material.dart';
import 'package:parfume_app/common/widgets/app_logo_background.dart';
import 'package:parfume_app/common/widgets/app_scent_wave.dart';
import 'package:parfume_app/core/constants/app_constants.dart';
import 'package:parfume_app/data/models/recommendation.dart';
import 'package:parfume_app/domain/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:parfume_app/ui/screens/admin/widgets/hidden_button.dart';
import 'package:parfume_app/ui/screens/admin/admin_panel_screen.dart';
import 'package:flutter/foundation.dart'; // DEBUG_REMOVE

import 'i18n/rtl_support.dart';
import 'ui/components/navigation/language_switcher.dart';
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

/// Root kiosk shell that owns the shared decorative animation layers.
///
/// Holds the logo [AnimationController] so it survives page transitions.
/// The logo re-animates on every [AppState] *type* change — not on every
/// [notifyListeners] call — so intra-state updates (e.g. question index
/// increments) do not retrigger the animation.
///
/// [AppScentWave] and [AppLogoBackground] are conditionally shown depending
/// on the active state; [KvkkState], [ErrorState], and [PLCErrorState] suppress
/// both layers for a cleaner layout.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with SingleTickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoAnimation;

  /// Tracks the *type* of the last seen state to avoid re-animating on
  /// intra-state updates such as question index changes.
  Type? _currentStateType;
  int _languageVersion = 0;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: AppConstants.logoAnimationDuration,
      vsync: this,
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );
    // DEBUG_REMOVE_START
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        context.read<AppViewModel>().goToResult();
      }
    });
    // DEBUG_REMOVE_END
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  /// Replays the logo animation only when the [AppState] *type* or language changes.
  void _reanimateLogoIfStateChanged(AppState newState, int languageVersion) {
    final newType = newState.runtimeType;
    if (_currentStateType == newType && _languageVersion == languageVersion) {
      return;
    }
    _currentStateType = newType;
    _languageVersion = languageVersion;
    _logoController
      ..reset()
      ..forward();
  }

  /// Whether the logo background should be shown for [state].
  bool _showLogo(AppState state) => switch (state) {
    KvkkState() => false,
    ErrorState() => false,
    PLCErrorState() => false,
    _ => true,
  };

  /// Whether the scent-wave animation should be shown for [state].
  bool _showWave(AppState state) => switch (state) {
    KvkkState() => false,
    ErrorState() => false,
    PLCErrorState() => false,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewModel>(
      builder: (context, viewModel, _) {
        final state = viewModel.state;
        _reanimateLogoIfStateChanged(state, viewModel.languageVersion);

        return Listener(
          onPointerDown: (_) => viewModel.onUserInteraction(),
          child: PopScope(
            canPop: false,
            child: Directionality(
              textDirection: RtlSupport.textDirection(viewModel.language),
              child: Scaffold(
                body: Stack(
                  children: [
                    if (_showLogo(state))
                      AppLogoBackground(animation: _logoAnimation),
                    if (_showWave(state)) const AppScentWave(),
                    Positioned.fill(
                      child: viewModel.initialized
                          // app.dart
                          ? AppRouter(
                              debugOverrideState: ResultState(
                                Recommendation.mock(),
                              ),
                            ).build(
                              viewModel,
                            ) // const AppRouter().build(viewModel)
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    Positioned(
                      right: 30,
                      bottom: 30,
                      child: LanguageSwitcher(
                        selected: viewModel.language,
                        available: viewModel.availableLanguages,
                        onSelect: viewModel.changeLanguage,
                      ),
                    ),
                    HiddenAdminButton(
                      onAccessGranted: () {
                        viewModel.onAdminPanelOpened();
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => AdminPanelScreen(
                                  plcService: viewModel.plcService,
                                  isReadOnly: viewModel.state is! IdleState,
                                ),
                              ),
                            )
                            .then((_) => viewModel.onAdminPanelClosed());
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
