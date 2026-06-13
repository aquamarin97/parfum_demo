import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parfume_app/data/plc/plc_error_asset_source.dart';
import 'package:parfume_app/domain/plc/i_plc_error_string_source.dart';
import 'package:parfume_app/domain/plc/plc_exceptions.dart';
import 'package:parfume_app/ui/theme/app_colors.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

import '../../../viewmodel/app_view_model.dart';

/// PLC hata ekranı — iki mod:
///
/// **Yeniden bağlanma modu** (ilk [_maxRetries] denemede):
///   - Otomatik geri sayım → [onRetry] çağrısı
///   - Her başarısız denemede bekleme süresi uzar: 10 → 20 → 40 sn
///
/// **Hizmet dışı modu** (tüm denemeler tükendikten sonra):
///   - "Cihaz şu anda hizmet dışıdır" mesajı
///   - Otomatik yeniden deneme yok; yalnızca "Başa dön" butonu
class PLCErrorScreen extends StatefulWidget {
  const PLCErrorScreen({
    super.key,
    required this.viewModel,
    required this.errorCode,
    required this.languageCode,
    this.technicalDetail,
    this.onRetry,
    this.errorStringSource = const PlcErrorAssetSource(),
  });

  final AppViewModel viewModel;
  final int errorCode;
  final String languageCode;
  final String? technicalDetail;

  /// Async yeniden bağlanma işlemi. Başarılı olursa ekran unmount edilir;
  /// başarısız olursa sayaç bir sonraki gecikme ile yeniden başlar.
  final Future<void> Function()? onRetry;

  final IPlcErrorStringSource errorStringSource;

  @override
  State<PLCErrorScreen> createState() => _PLCErrorScreenState();
}

class _PLCErrorScreenState extends State<PLCErrorScreen> {
  late final Future<Map<int, String>?> _messagesFuture;

  static const _maxRetries = 3;
  static const _retryDelays = [10, 20, 40];

  int _retryCount = 0;
  int _secondsLeft = 10;
  bool _isRetrying = false;
  Timer? _countdownTimer;

  bool get _isOutOfService => _retryCount >= _maxRetries;

  @override
  void initState() {
    super.initState();
    _messagesFuture = widget.errorStringSource.load(widget.languageCode);
    if (widget.onRetry != null) _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final delay = _retryCount < _retryDelays.length
        ? _retryDelays[_retryCount]
        : _retryDelays.last;
    setState(() {
      _secondsLeft = delay;
      _isRetrying = false;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _countdownTimer?.cancel();
        _doRetry();
      }
    });
  }

  Future<void> _doRetry() async {
    if (!mounted) return;
    setState(() => _isRetrying = true);
    _retryCount++;
    await widget.onRetry?.call();
    // Başarılı olsaydı ekran unmount edilirdi. Hâlâ buradaysak başarısız.
    if (!mounted) return;
    if (_isOutOfService) {
      setState(() => _isRetrying = false);
    } else {
      _startCountdown();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<int, String>?>(
      future: _messagesFuture,
      builder: (context, snapshot) {
        final message = snapshot.data?[widget.errorCode] ??
            snapshot.data?[PLCErrorCodes.unknownError] ??
            PLCErrorCodes.getTechnicalDescription(widget.errorCode);
        return _isOutOfService
            ? _buildOutOfService(context)
            : _buildReconnecting(context, message);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Yeniden bağlanma modu
  // ---------------------------------------------------------------------------

  Widget _buildReconnecting(BuildContext context, String errorMessage) {
    final strings = widget.viewModel.strings;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İkon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 96,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Hata başlığı
              Text(
                strings.t('error_title'),
                style: AppTextStyles.title.copyWith(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Hata mesajı
              Text(
                errorMessage,
                style: AppTextStyles.body.copyWith(
                  fontFamily: 'NotoSans',
                  fontSize: 40,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Hata kodu etiketi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  'Error Code: ${widget.errorCode}',
                  style: AppTextStyles.body.copyWith(
                    fontFamily: 'Courier',
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Sayaç / bağlanıyor göstergesi
              _buildRetryStatus(),

              const SizedBox(height: 40),

              // Başa dön
              SizedBox(
                width: 400,
                child: OutlinedButton(
                  onPressed: widget.viewModel.resetToIdle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 20,
                    ),
                    side: const BorderSide(color: AppColors.border, width: 2),
                  ),
                  child: Text(
                    strings.t('back_to_start'),
                    style: AppTextStyles.body.copyWith(
                      fontFamily: 'NotoSans',
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetryStatus() {
    if (_isRetrying) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Bağlantı yeniden kuruluyor...',
            style: AppTextStyles.body.copyWith(
              fontFamily: 'NotoSans',
              fontSize: 36,
              color: AppColors.primary,
            ),
          ),
        ],
      );
    }

    return Text(
      '$_secondsLeft saniye içinde tekrar denenecek  (${_retryCount + 1}/$_maxRetries)',
      style: AppTextStyles.body.copyWith(
        fontFamily: 'NotoSans',
        fontSize: 36,
        color: AppColors.textSecondary.withValues(alpha: 0.7),
      ),
      textAlign: TextAlign.center,
    );
  }

  // ---------------------------------------------------------------------------
  // Hizmet dışı modu
  // ---------------------------------------------------------------------------

  Widget _buildOutOfService(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B1A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Uyarı ikonu
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

              const SizedBox(height: 48),

              // Hata kodu — tekniker için
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Text(
                  'Error ${widget.errorCode}',
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),

              const SizedBox(height: 56),

              // Başa dön — kullanıcı başka bir şey yapamayacağı için bu da gösterilir
              SizedBox(
                width: 420,
                child: OutlinedButton(
                  onPressed: widget.viewModel.resetToIdle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 20,
                    ),
                    side: const BorderSide(color: Colors.white30, width: 2),
                  ),
                  child: Text(
                    widget.viewModel.strings.t('back_to_start'),
                    style: AppTextStyles.body.copyWith(
                      fontFamily: 'NotoSans',
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
