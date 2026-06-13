import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../../viewmodel/app_view_model.dart';

/// PLC bağlantı hatası ekranı.
///
/// Doğrudan "Cihaz şu anda hizmet dışıdır" mesajını gösterir.
/// Arka planda her [_retryInterval] saniyede bir [onRetry] çağrılır;
/// bağlantı sağlanınca ekran otomatik unmount edilir.
class PLCErrorScreen extends StatefulWidget {
  const PLCErrorScreen({
    super.key,
    required this.viewModel,
    required this.errorCode,
    this.onRetry,
  });

  final AppViewModel viewModel;
  final int errorCode;

  /// Async yeniden bağlanma işlemi. Başarılı olursa ekran unmount edilir;
  /// başarısız olursa bir sonraki deneme zamanlanır.
  final Future<void> Function()? onRetry;

  @override
  State<PLCErrorScreen> createState() => _PLCErrorScreenState();
}

class _PLCErrorScreenState extends State<PLCErrorScreen> {
  static const _retryInterval = Duration(seconds: 30);

  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    if (widget.onRetry != null) _scheduleRetry();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryInterval, _doRetry);
  }

  Future<void> _doRetry() async {
    if (!mounted) return;
    await widget.onRetry?.call();
    if (!mounted) return; // Bağlantı sağlandı, ekran unmount edildi
    _scheduleRetry();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B1A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  size: 110,
                  color: Colors.redAccent,
                ),
              ),

              const SizedBox(height: 48),

              Text(
                'Cihaz Şu An Hizmet Dışıdır',
                style: AppTextStyles.title.copyWith(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 56,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              Text(
                'Hizmetinize en kısa sürede yeniden gireceğiz.\nRahatsızlık için özür dileriz.',
                style: AppTextStyles.body.copyWith(
                  fontFamily: 'NotoSans',
                  fontSize: 40,
                  color: Colors.white70,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
