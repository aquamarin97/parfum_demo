import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parfume_app/core/constants/app_constants.dart';
import 'package:parfume_app/infrastructure/plc/plc_service_manager.dart';
import 'package:parfume_app/ui/screens/idle/widgets/idle_center_content.dart';
import 'package:parfume_app/ui/screens/idle/widgets/idle_greeting_text.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../../viewmodel/app_view_model.dart';

/// Kiosk home screen shown while the app is waiting for user interaction.
///
/// Owns the shared [AnimationController] that drives the greeting and center
/// content entry animations.
/// Re-runs the entry animation whenever the active language changes.
class IdleScreen extends StatefulWidget {
  const IdleScreen({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<IdleScreen> createState() => _IdleScreenState();
}

class _IdleScreenState extends State<IdleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  /// Tracks the active language code so [didUpdateWidget] can detect changes.
  String _currentLanguageCode = '';

  @override
  void initState() {
    super.initState();
    _currentLanguageCode = widget.viewModel.currentLanguage.code;
    _setupAnimation();
  }

  /// Creates the animation controller and starts the entry animation.
  void _setupAnimation() {
    _controller = AnimationController(
      duration: AppConstants.logoAnimationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(IdleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLanguageCode = widget.viewModel.currentLanguage.code;
    if (_currentLanguageCode != newLanguageCode) {
      _currentLanguageCode = newLanguageCode;
      // Re-run the entry animation so the RTL/LTR layout change feels
      // intentional rather than an abrupt jump.
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.viewModel.currentLanguage.isRtl;
    final strings = widget.viewModel.strings;

    return Stack(
      children: [
        IdleGreetingText(
          animation: _animation,
          languageCode: _currentLanguageCode,
          isRtl: isRtl,
          title1: strings.t('idle_title_1'),
          title2: strings.t('idle_title_2'),
          brandName: strings.t('brand_name'),
        ),
        IdleCenterContent(
          animation: _animation,
          languageCode: _currentLanguageCode,
          subtitle: strings.t('idle_subtitle'),
          startLabel: strings.t('start'),
          onStart: widget.viewModel.startKvkk,
        ),
        // Sağ üst köşe — dijital saat
        Positioned(
          top: 28,
          right: 36,
          child: _ClockWidget(),
        ),
        // Sol alt köşe — PLC durum noktası
        Positioned(
          left: 24,
          bottom: 24,
          child: _PLCStatusDot(plcService: widget.viewModel.plcService),
        ),
      ],
    );
  }
}

/// Sol alt köşede küçük PLC bağlantı göstergesi.
///
/// - Turuncu nabız: bağlanıyor
/// - Yeşil: bağlandı
/// - Kırmızı: hata / bağlantı yok
class _PLCStatusDot extends StatefulWidget {
  const _PLCStatusDot({required this.plcService});

  final PLCServiceManager plcService;

  @override
  State<_PLCStatusDot> createState() => _PLCStatusDotState();
}

class _PLCStatusDotState extends State<_PLCStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.plcService,
      builder: (context, _) {
        final state = widget.plcService.state;

        final (color, animate) = switch (state) {
          PLCConnectionState.connecting   => (Colors.orange, true),
          PLCConnectionState.connected    => (const Color(0xFF38A169), false),
          PLCConnectionState.error        => (Colors.red, false),
          PLCConnectionState.disconnected => (Colors.grey, false),
        };

        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final opacity = animate ? (0.4 + 0.6 * _pulse.value) : 1.0;
            return Opacity(
              opacity: opacity,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Saat widget'i
// ---------------------------------------------------------------------------

class _ClockWidget extends StatefulWidget {
  const _ClockWidget();

  @override
  State<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<_ClockWidget> {
  late String _time;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _time = _formatted();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _time = _formatted());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatted() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _time,
      style: AppTextStyles.body.copyWith(
        fontFamily: 'NotoSans',
        fontSize: 28,
        color: AppColors.textPrimary.withValues(alpha: 0.45),
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
      ),
    );
  }
}

